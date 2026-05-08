import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database.dart';
import '../../services/image_service.dart';
import '../constants/sport_utils.dart';
import 'activity_confirmation.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF111214);
const _card     = Color(0xFF1A1D21);
const _border   = Color(0xFF2A2D35);
const _blue     = Color(0xFF2A9FFF);
const _green    = Color(0xFF1CE9B0);
const _accent   = Color(0xFF4A8FA8);
const _dim      = Color(0xFF666666);
const _stepper  = Color(0xFF252830);
const _stepLine = Color(0xFF333333);

// ─── Sport data (aus sport_utils) ────────────────────────────────────────────

// ─── Mention-aware TextEditingController ─────────────────────────────────────
class _MentionController extends TextEditingController {
  List<String> _confirmed = [];

  void setConfirmed(List<String> usernames) {
    _confirmed = usernames;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final spans = <InlineSpan>[];
    final text  = value.text;
    final regex = RegExp(r'@(\w+)');
    int last = 0;

    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: style));
      }
      final isTagged = _confirmed.contains(m.group(1));
      spans.add(TextSpan(
        text: m.group(0),
        style: (style ?? const TextStyle()).copyWith(
          color: isTagged ? const Color(0xFF2A9FFF) : const Color(0xFF2A9FFF).withValues(alpha: 0.55),
          fontWeight: FontWeight.w700,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: style));
    }
    return TextSpan(children: spans);
  }
}

// ─── Main widget ──────────────────────────────────────────────────────────────
class AktivitaetHinzufuegen extends StatefulWidget {
  final VoidCallback? onSaved;
  const AktivitaetHinzufuegen({super.key, this.onSaved});

  @override
  State<AktivitaetHinzufuegen> createState() => _AktivitaetHinzufuegenState();
}

class _AktivitaetHinzufuegenState extends State<AktivitaetHinzufuegen> {
  String? _sport;
  bool _showMore = false;

  int _dauer   = 45;
  int _distanz = 8;
  String _activityType = 'training'; // für Ballsport/Kampfsport

  String _intensity = 'easy';
  int _mood = 4;

  final _captionCtrl = _MentionController();
  XFile? _photo;
  bool _saving = false;

  // ── Sport state ───────────────────────────────────────────────────────────
  List<String> _userSports = [];

  // Letzte 3 User-Sports (oder erste 3 alphabetisch wenn keine registriert)
  List<Map<String, String>> get _displayedSports {
    if (_userSports.isNotEmpty) {
      return _userSports.reversed.take(3)
          .map((s) => {'name': s, 'emoji': sportEmoji(s)}).toList();
    }
    return kAllSports.take(3).map((s) => {'name': s, 'emoji': sportEmoji(s)}).toList();
  }

  // Alle übrigen Sportarten für den "Mehr"-Bereich
  List<Map<String, String>> get _moreSports {
    final shown = _displayedSports.map((p) => p['name']!).toSet();
    return kAllSports
        .where((s) => !shown.contains(s))
        .map((s) => {'name': s, 'emoji': sportEmoji(s)})
        .toList();
  }

  SportCategory get _category =>
      _sport != null ? sportCategory(_sport!) : SportCategory.general;

  // ── Mention state ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _friends     = [];
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _mentions    = [];
  String? _mentionQuery;

  @override
  void initState() {
    super.initState();
    _loadUserSports();
    _loadFriends();
    _captionCtrl.addListener(_onCaptionChange);
  }

  Future<void> _loadUserSports() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final data = await DatabaseService(uid: me.uid).getFriendData(me.uid);
    if (data != null && mounted) {
      setState(() {
        _userSports = (data['sports'] as List<dynamic>? ?? []).cast<String>();
      });
    }
  }

  Future<void> _loadFriends() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final snap = await DatabaseService(uid: me.uid).userFriends.first;
    final list = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final id = (doc.data() as Map)['userId'] as String?;
      if (id == null) continue;
      final data = await DatabaseService(uid: me.uid).getFriendData(id);
      if (data != null) list.add(data);
    }
    if (mounted) setState(() => _friends = list);
  }

  void _onCaptionChange() {
    final text   = _captionCtrl.text;
    final cursor = _captionCtrl.selection.baseOffset;
    if (cursor < 0) { _clearSuggestions(); return; }

    final before  = text.substring(0, cursor);
    final atIndex = before.lastIndexOf('@');
    if (atIndex < 0) { _clearSuggestions(); return; }

    final query = before.substring(atIndex + 1);
    if (query.contains(' ')) { _clearSuggestions(); return; }

    final q = query.toLowerCase();
    final hits = _friends.where((f) {
      final u = (f['username'] ?? '').toString().toLowerCase();
      final n = '${f['firstName']} ${f['lastName']}'.toLowerCase();
      return u.contains(q) || n.contains(q);
    }).take(5).toList();

    setState(() { _mentionQuery = query; _suggestions = hits; });
  }

  void _clearSuggestions() {
    if (_suggestions.isNotEmpty || _mentionQuery != null) {
      setState(() { _suggestions = []; _mentionQuery = null; });
    }
  }

  void _selectMention(Map<String, dynamic> friend) {
    final text     = _captionCtrl.text;
    final cursor   = _captionCtrl.selection.baseOffset;
    final before   = text.substring(0, cursor);
    final atIndex  = before.lastIndexOf('@');
    final username = friend['username'] as String? ?? '';

    final newText = '${text.substring(0, atIndex)}@$username ${text.substring(cursor)}';
    _captionCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIndex + username.length + 2),
    );

    if (!_mentions.any((m) => m['uid'] == friend['uid'])) {
      _mentions = [..._mentions, {'uid': friend['uid'], 'username': username}];
      _captionCtrl.setConfirmed(_mentions.map((m) => m['username'] as String).toList());
    }
    _clearSuggestions();
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_sport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Sportart wählen')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    final nav     = Navigator.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);

    String? photoUrl;
    if (_photo != null) {
      photoUrl = await ImageService().uploadActivityImage(user.uid, _photo!);
    }

    final cat = _sport != null ? sportCategory(_sport!) : SportCategory.general;
    final data = {
      'option':    _sport ?? '',
      'text':      _captionCtrl.text,
      'emoji':     _mood.toString(),
      'dauer':     _dauer,
      if (cat == SportCategory.distance) 'distanz': _distanz,
      if (cat == SportCategory.ballsport || cat == SportCategory.combat)
        'activityType': _activityType,
      'intensity': _intensity,
      'datum':     DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'userId':    user.uid,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (_mentions.isNotEmpty) 'mentions': _mentions,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .add(data);

    await DatabaseService(uid: user.uid).saveActivityForToday(data);

    // Streak + Rang für den Bestätigungsscreen laden
    final userData  = await DatabaseService(uid: user.uid).getFriendData(user.uid);
    final streak    = userData?['streak'] as int? ?? 0;
    final friendRank = await _fetchFriendRank(user.uid, streak);
    final xp        = 50 + (_intensity == 'hard' ? 25 : _intensity == 'mid' ? 10 : 0);

    if (!mounted) return;
    nav.pop();

    rootNav.push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => ActivityConfirmation(
        xp: xp,
        streak: streak,
        friendRank: friendRank,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));

    if (widget.onSaved != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSaved!());
    }
  }

  Future<int?> _fetchFriendRank(String uid, int myStreak) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('friends').get();
      int rank = 1;
      for (final doc in snap.docs) {
        final friendId = (doc.data())['userId'] as String?;
        if (friendId == null) continue;
        final d = await DatabaseService(uid: uid).getFriendData(friendId);
        if ((d?['streak'] as int? ?? 0) > myStreak) rank++;
      }
      return rank;
    } catch (_) {
      return null;
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: _accent,
      ),
    ),
  );

  Widget _sportChip(String name, String emoji) {
    final active = _sport == name;
    return GestureDetector(
      onTap: () => setState(() { _sport = name; _activityType = 'training'; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0D2535) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? _blue : _border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: active ? _blue : _dim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreChip() => GestureDetector(
    onTap: () => setState(() => _showMore = !_showMore),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _showMore ? '✕' : '＋',
            style: const TextStyle(fontSize: 18, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 4),
          Text(
            _showMore ? 'Weniger' : 'Mehr',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF444444)),
          ),
        ],
      ),
    ),
  );

  Widget _statBox({
    required String label,
    required int value,
    required String unit,
    required int step,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: _accent),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$value',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                const SizedBox(width: 4),
                Text(unit,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _stepBtn('−', () => onChanged((value - step).clamp(min, max))),
                const SizedBox(width: 4),
                _stepBtn('+', () => onChanged((value + step).clamp(min, max))),
              ],
            ),
          ],
        ),
      );

  Widget _stepBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: _stepper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _stepLine),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: const TextStyle(fontSize: 15, color: Color(0xFF888888), height: 1.1)),
    ),
  );

  // ── Adaptive Einheit-Sektion ───────────────────────────────────────────────

  String get _unitSectionLabel {
    switch (_category) {
      case SportCategory.ballsport: return 'Einheit';
      case SportCategory.combat:    return 'Einheit';
      default:                      return 'Einheit';
    }
  }

  Widget _buildUnitSection() {
    switch (_category) {
      case SportCategory.distance:
        return Row(children: [
          Expanded(child: _statBox(label: 'Dauer', value: _dauer, unit: 'min', step: 5, min: 0, max: 300, onChanged: (v) => setState(() => _dauer = v))),
          const SizedBox(width: 8),
          Expanded(child: _statBox(label: 'Distanz', value: _distanz, unit: 'km', step: 1, min: 0, max: 200, onChanged: (v) => setState(() => _distanz = v))),
        ]);

      case SportCategory.ballsport:
        return Column(children: [
          Row(children: [
            _actTypeBtn('training', 'Training'),
            const SizedBox(width: 8),
            _actTypeBtn('spiel', 'Spiel'),
          ]),
          const SizedBox(height: 8),
          _statBox(label: 'Dauer', value: _dauer, unit: 'min', step: 5, min: 0, max: 300, onChanged: (v) => setState(() => _dauer = v)),
        ]);

      case SportCategory.combat:
        return Column(children: [
          Row(children: [
            _actTypeBtn('training', 'Training'),
            const SizedBox(width: 8),
            _actTypeBtn('kampf', 'Kampf'),
          ]),
          const SizedBox(height: 8),
          _statBox(label: 'Dauer', value: _dauer, unit: 'min', step: 5, min: 0, max: 300, onChanged: (v) => setState(() => _dauer = v)),
        ]);

      case SportCategory.general:
        return _statBox(label: 'Dauer', value: _dauer, unit: 'min', step: 5, min: 0, max: 300, onChanged: (v) => setState(() => _dauer = v));
    }
  }

  Widget _actTypeBtn(String value, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _activityType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _activityType == value ? const Color(0xFF0D2535) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _activityType == value ? _blue : _border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: _activityType == value ? _blue : _dim,
          ),
        ),
      ),
    ),
  );

  Widget _intensityBtn(String level, String label, Color accentColor, Color bgActive, int dots) {
    final active = _intensity == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _intensity = level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? bgActive : _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? accentColor : _border),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: active ? accentColor : const Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active && i < dots ? accentColor : const Color(0xFF333333),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moodBtn(String emoji, int score) {
    final sel = _mood == score;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mood = score),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1A2030) : _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? _blue : _border),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 3),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: sel ? _blue : const Color(0xFF444444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sports = [
      ..._displayedSports,
      if (_showMore) ..._moreSports,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.92,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2024),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2A2D33)),
                        ),
                        child: const Icon(Icons.chevron_left, color: Color(0xFF888888), size: 22),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'NEUE AKTIVITÄT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _saving ? null : _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_blue, _green]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'POSTEN ↗',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFF1F2228)),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Sportart ──────────────────────────────────────────
                      _label('Sportart'),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.82,
                        children: [
                          ...sports.map((s) => _sportChip(s['name']!, s['emoji']!)),
                          _moreChip(),
                        ],
                      ),

                      // ── Einheit (adaptiv je Sportart) ─────────────────────
                      _label(_unitSectionLabel),
                      _buildUnitSection(),

                      // ── Intensität ────────────────────────────────────────
                      _label('Intensität'),
                      Row(
                        children: [
                          _intensityBtn('easy', 'Locker',  const Color(0xFF1CE9B0), const Color(0xFF0D2A1A), 1),
                          const SizedBox(width: 6),
                          _intensityBtn('mid',  'Moderat', const Color(0xFFF0A020), const Color(0xFF2A1E05), 2),
                          const SizedBox(width: 6),
                          _intensityBtn('hard', 'Hart',    const Color(0xFFFF4455), const Color(0xFF2A0D0D), 3),
                        ],
                      ),

                      // ── Gefühl ────────────────────────────────────────────
                      _label('Gefühl'),
                      Row(
                        children: [
                          _moodBtn('😢', 1),
                          const SizedBox(width: 5),
                          _moodBtn('😕', 2),
                          const SizedBox(width: 5),
                          _moodBtn('😐', 3),
                          const SizedBox(width: 5),
                          _moodBtn('🙂', 4),
                          const SizedBox(width: 5),
                          _moodBtn('😄', 5),
                        ],
                      ),

                      // ── Caption & Foto ────────────────────────────────────
                      _label('Caption & Foto'),

                      // Vorschläge
                      if (_suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D21),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2A2D35)),
                          ),
                          child: Column(
                            children: _suggestions.map((f) {
                              final imgUrl = (f['profileImageUrl'] ?? '').toString();
                              return GestureDetector(
                                onTap: () => _selectMention(f),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: const Color(0xFF252830),
                                        backgroundImage: imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
                                        child: imgUrl.isEmpty ? const Icon(Icons.person, size: 14, color: Colors.white38) : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${f['firstName'] ?? ''} ${f['lastName'] ?? ''}'.trim(),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ),
                                      Text('@${f['username'] ?? ''}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF2A9FFF), fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border),
                              ),
                              child: TextField(
                                controller: _captionCtrl,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                                decoration: const InputDecoration(
                                  hintText: 'Wie war\'s? Nutze @ um Freunde zu erwähnen...',
                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF444444)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                              if (picked != null) setState(() => _photo = picked);
                            },
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border),
                              ),
                              child: _photo != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: kIsWeb
                                          ? Image.network(_photo!.path, fit: BoxFit.cover)
                                          : Image.file(File(_photo!.path), fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.camera_alt_outlined, color: Color(0xFF555555), size: 28),
                            ),
                          ),
                        ],
                      ),

                      // ── CTA Button ────────────────────────────────────────
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_blue, _green]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: _saving
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'AKTIVITÄT TEILEN',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
