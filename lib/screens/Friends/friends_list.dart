import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../services/database.dart';
import '../../shared/constants/sport_utils.dart';
import 'friend_actions.dart';
import 'profile_view.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF111214);
const _card     = Color(0xFF161920);
const _cardLine = Color(0xFF1E2228);
const _border   = Color(0xFF252830);
const _blue     = Color(0xFF2A9FFF);
const _green    = Color(0xFF1CE9B0);
const _fire     = Color(0xFFFF6030);
const _secLbl   = Color(0xFF3A7A9A);

// ─── Avatar / rank palette ────────────────────────────────────────────────────
const _rankStyles = [
  // index 0 → rank 1
  {'border': Color(0xFFFF6030), 'bg': Color(0xFF1A0A00), 'text': Color(0xFFFF6030), 'pillBg': Color(0xFF1A1400), 'pillText': Color(0xFFF0C040), 'pillBorder': Color(0xFF4A3800)},
  // index 1 → rank 2
  {'border': Color(0xFF5A7898), 'bg': Color(0xFF141820), 'text': Color(0xFF5A7898), 'pillBg': Color(0xFF141820), 'pillText': Color(0xFF6080A0), 'pillBorder': Color(0xFF303850)},
  // index 2 → rank 3
  {'border': Color(0xFF1CE9B0), 'bg': Color(0xFF0D1A10), 'text': Color(0xFF1CE9B0), 'pillBg': Color(0xFF1A1008), 'pillText': Color(0xFFC07840), 'pillBorder': Color(0xFF402808)},
];

Map<String, dynamic> _rankStyle(int rank) {
  if (rank >= 1 && rank <= 3) return Map<String, dynamic>.from(_rankStyles[rank - 1]);
  return {'border': _border, 'bg': const Color(0xFF181B1F), 'text': const Color(0xFF444444), 'pillBg': const Color(0xFF1A1D21), 'pillText': const Color(0xFF555555), 'pillBorder': _border};
}

String _rankLabel(int rank) {
  if (rank == 1) return '#1 🏆';
  if (rank == 2) return '#2';
  if (rank == 3) return '#3';
  return '#$rank';
}

// ─── Sport → emoji ────────────────────────────────────────────────────────────

String _initials(Map u) {
  final f = (u['firstName'] ?? '').toString();
  final l = (u['lastName']  ?? '').toString();
  return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
}

// ─── FriendsSlideInView ───────────────────────────────────────────────────────
class FriendsSlideInView extends StatefulWidget {
  const FriendsSlideInView({super.key});
  @override
  State<FriendsSlideInView> createState() => _FriendsSlideInViewState();
}

class _FriendsSlideInViewState extends State<FriendsSlideInView> {
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  List<Map<String, dynamic>> _allFriends      = [];
  List<Map<String, dynamic>> _allRequests     = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  Map<String, dynamic>?      _myData;
  bool _loading = true;

  StreamSubscription<QuerySnapshot>? _friendsSub;
  StreamSubscription<QuerySnapshot>? _requestsSub;
  int _knownFriendCount  = -1;
  int _knownRequestCount = -1;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() { _query = _searchCtrl.text.trim(); _applyFilter(); });
    });
    _loadAll();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    _friendsSub = DatabaseService(uid: me.uid).userFriends.listen((snap) {
      if (!_loading && snap.docs.length != _knownFriendCount) {
        _loadAll();
      }
    });
    _requestsSub = DatabaseService(uid: me.uid).incomingFriendRequests.listen((snap) {
      if (!_loading && snap.docs.length != _knownRequestCount) {
        _loadAll();
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _searchFocus.dispose();
    _friendsSub?.cancel(); _requestsSub?.cancel();
    super.dispose();
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filteredFriends = List.from(_allFriends);
    } else {
      final q = _query.toLowerCase();
      _filteredFriends = _allFriends.where((f) =>
          '${f['firstName']} ${f['lastName']}'.toLowerCase().contains(q) ||
          f['username'].toString().toLowerCase().contains(q)).toList();
    }
  }

  Future<void> _loadAll() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    setState(() => _loading = true);
    try {
      // Freunde + eigene Daten laden
      final results = await Future.wait([
        DatabaseService(uid: me.uid).userFriends.first,
        DatabaseService(uid: me.uid).getFriendData(me.uid),
      ]);

      final friendsSnap = results[0] as QuerySnapshot;
      _myData = results[1] as Map<String, dynamic>?;

      final friends = <Map<String, dynamic>>[];
      for (final doc in friendsSnap.docs) {
        final id = (doc.data() as Map)['userId'];
        final data = await DatabaseService(uid: me.uid).getFriendData(id);
        if (data != null) friends.add(data);
      }
      friends.sort((a, b) => ((b['streak'] ?? 0) as int).compareTo((a['streak'] ?? 0) as int));

      setState(() {
        _allFriends       = friends;
        _knownFriendCount = friends.length;
        _loading          = false;
        _applyFilter();
      });
    } catch (e) {
      setState(() => _loading = false);
    }

    // Anfragen separat laden — Fehler hier brechen die Freundesliste nicht
    try {
      final requestsSnap = await DatabaseService(uid: me.uid).incomingFriendRequests.first;
      final friendIds = _allFriends.map((f) => f['uid'] as String?).toSet();
      final requests = <Map<String, dynamic>>[];
      for (final doc in requestsSnap.docs) {
        final id = (doc.data() as Map)['senderId'] as String?;
        if (id == null) continue;
        // Veraltetes Dokument: bereits Freund → aus Firestore löschen
        if (friendIds.contains(id)) {
          doc.reference.delete();
          continue;
        }
        final data = await DatabaseService(uid: me.uid).getFriendData(id);
        if (data != null) {
          requests.add(data);
        } else {
          // User existiert nicht mehr → veraltetes Dokument löschen
          doc.reference.delete();
        }
      }
      if (mounted) {
        setState(() {
          _allRequests       = requests;
          _knownRequestCount = requests.length;
        });
      }
    } catch (_) {}
  }

  // My rank among friends
  int get _myRank {
    final myStreak = (_myData?['streak'] ?? 0) as int;
    int rank = 1;
    for (final f in _allFriends) {
      if (((f['streak'] ?? 0) as int) > myStreak) rank++;
    }
    return rank;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const Scaffold(backgroundColor: _bg);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2))
            : Column(
                  children: [
                    // ── Header ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2024), shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF2A2D33)),
                              ),
                              child: const Icon(Icons.chevron_left, color: Color(0xFF888888), size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('FREUNDE',
                              style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white)),
                          const SizedBox(width: 6),
                          Text('${_allFriends.length}',
                              style: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w700, color: _blue)),
                        ],
                      ),
                    ),

                    // ── Search ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D21),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            controller: _searchCtrl, focusNode: _searchFocus,
                            style: GoogleFonts.barlow(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF444444), size: 18),
                              hintText: 'Freunde durchsuchen…',
                              hintStyle: GoogleFonts.barlow(color: const Color(0xFF444444), fontSize: 13),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Color(0xFF555555), size: 16),
                                      onPressed: () { _searchCtrl.clear(); _searchFocus.unfocus(); },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Anfragen-Zeile ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: GestureDetector(
                        onTap: () => _showRequestsSheet(context, me.uid),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _allRequests.isNotEmpty
                                ? const Color(0xFF0B2233)
                                : _card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _allRequests.isNotEmpty
                                  ? _blue.withValues(alpha: 0.4)
                                  : _border,
                            ),
                          ),
                          child: Row(children: [
                            Icon(
                              Icons.person_add_outlined,
                              size: 18,
                              color: _allRequests.isNotEmpty ? _blue : const Color(0xFF444444),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Freundesanfragen',
                                  style: GoogleFonts.barlow(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: _allRequests.isNotEmpty ? Colors.white : const Color(0xFF444444),
                                  )),
                            ),
                            if (_allRequests.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${_allRequests.length}',
                                    style: GoogleFonts.barlow(
                                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                              )
                            else
                              const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 16),
                          ]),
                        ),
                      ),
                    ),

                    // ── Scrollable content ───────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── "Du" section ─────────────────────────────
                            if (_myData != null) ...[
                              _secLabel('Du'),
                              _MyCard(data: _myData!, rank: _myRank),
                              const SizedBox(height: 4),
                            ],

                            // ── Friends ───────────────────────────────────
                            _secLabel('Deine Freunde'),
                            if (_filteredFriends.isEmpty)
                              _emptyState(_query.isNotEmpty ? 'Keine Freunde gefunden' : 'Noch keine Freunde')
                            else
                              ..._filteredFriends.asMap().entries.map((e) => _FriendCard(
                                user: e.value, rank: e.key + 1, key: ValueKey(e.value['uid']),
                              )),

                            const SizedBox(height: 8),

                            // ── Add friends button ────────────────────────
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _border, style: BorderStyle.solid),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_add_outlined, color: Color(0xFF3A4050), size: 18),
                                    const SizedBox(width: 8),
                                    Text('FREUNDE HINZUFÜGEN',
                                        style: GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: const Color(0xFF3A4050))),
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
    );
  }

  void _showRequestsSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(children: [
                  Text('FREUNDESANFRAGEN',
                      style: GoogleFonts.barlowCondensed(
                          fontSize: 18, fontWeight: FontWeight.w900,
                          letterSpacing: 0.8, color: Colors.white)),
                  const SizedBox(width: 8),
                  if (_allRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(10)),
                      child: Text('${_allRequests.length}',
                          style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                ]),
              ),
              const Divider(height: 1, color: Color(0xFF1F2228)),
              Expanded(
                child: _allRequests.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.mark_email_read_outlined, size: 44, color: Color(0xFF252830)),
                          const SizedBox(height: 12),
                          Text('Keine offenen Anfragen',
                              style: GoogleFonts.barlow(color: const Color(0xFF3A4050), fontSize: 14, fontWeight: FontWeight.w600)),
                        ]),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: _allRequests.length,
                        itemBuilder: (_, i) => _RequestCard(
                          user: _allRequests[i],
                          currentUserId: uid,
                          key: ValueKey(_allRequests[i]['uid']),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _secLbl)),
  );

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Column(children: [
        const Icon(Icons.group_outlined, size: 44, color: Color(0xFF252830)),
        const SizedBox(height: 12),
        Text(msg, style: GoogleFonts.barlow(color: const Color(0xFF3A4050), fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─── My card (current user) ───────────────────────────────────────────────────
class _MyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int rank;
  const _MyCard({required this.data, required this.rank});

  @override
  Widget build(BuildContext context) {
    final streak    = data['streak']     as int? ?? 0;
    final maxStreak = data['streak_max'] as int? ?? 0;
    final sports    = (data['sports'] as List?)?.cast<String>() ?? [];
    final imgUrl    = (data['profileImageUrl'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A9FFF).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A9FFF).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(imgUrl, _initials(data), _blue, const Color(0xFF0B2233), const Color(0xFF2A9FFF)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
                        style: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFE0E0E0))),
                    Text('@${data['username'] ?? ''}',
                        style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF3A4555))),
                  ],
                ),
              ),
              _rankPill('#$rank', const Color(0xFF0B2233), _blue, const Color(0xFF1A4A6A)),
            ],
          ),
          _statsRow(streak, maxStreak, sports, isMe: true),
        ],
      ),
    );
  }
}

// ─── Friend card ──────────────────────────────────────────────────────────────
class _FriendCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  const _FriendCard({super.key, required this.user, required this.rank});

  @override
  Widget build(BuildContext context) {
    final style     = _rankStyle(rank);
    final streak    = user['streak']     as int? ?? 0;
    final maxStreak = user['streak_max'] as int? ?? 0;
    final sports    = (user['sports'] as List?)?.cast<String>() ?? [];
    final imgUrl    = (user['profileImageUrl'] ?? '').toString();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileView(user: user))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardLine),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _avatar(imgUrl, _initials(user), style['text'] as Color, style['bg'] as Color, style['border'] as Color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
                          style: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFE0E0E0))),
                      Text('@${user['username'] ?? ''}',
                          style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF3A4555))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => FriendActions.removeFriend(context, user, FirebaseAuth.instance.currentUser?.uid ?? ''),
                  behavior: HitTestBehavior.opaque,
                  child: _rankPill(_rankLabel(rank), style['pillBg'] as Color, style['pillText'] as Color, style['pillBorder'] as Color),
                ),
              ],
            ),
            _statsRow(streak, maxStreak, sports),
          ],
        ),
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String currentUserId;
  const _RequestCard({super.key, required this.user, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final imgUrl = (user['profileImageUrl'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardLine),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileView(user: user))),
            child: _avatar(imgUrl, _initials(user), const Color(0xFF5A7898), const Color(0xFF141820), const Color(0xFF5A7898)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
                    style: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFE0E0E0))),
                Row(children: [
                  Text('@${user['username'] ?? ''}',
                      style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF3A4555))),
                  if ((user['streak'] ?? 0) > 0) ...[
                    const SizedBox(width: 6),
                    Text('🔥 ${user['streak']}',
                        style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w700, color: _fire)),
                  ],
                ]),
              ],
            ),
          ),
          Row(
            children: [
              _actionBtn(Icons.check, _green, const Color(0xFF0D2A1A),
                  () => FriendActions.acceptFriendRequest(context, user, currentUserId)),
              const SizedBox(width: 8),
              _actionBtn(Icons.close, const Color(0xFFFF4455), const Color(0xFF2A0D0D),
                  () => FriendActions.declineFriendRequest(context, user, currentUserId)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color fg, Color bg, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: fg.withValues(alpha: 0.4))),
      child: Icon(icon, color: fg, size: 18),
    ),
  );
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
Widget _avatar(String imgUrl, String initials, Color textColor, Color bgColor, Color borderColor) {
  return Container(
    width: 46, height: 46,
    decoration: BoxDecoration(
      shape: BoxShape.circle, color: bgColor,
      border: Border.all(color: borderColor, width: 2),
    ),
    child: ClipOval(
      child: imgUrl.isNotEmpty
          ? Image.network(imgUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsWidget(initials, textColor))
          : _initialsWidget(initials, textColor),
    ),
  );
}

Widget _initialsWidget(String initials, Color color) => Center(
  child: Text(initials,
      style: GoogleFonts.barlowCondensed(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
);

Widget _rankPill(String label, Color bg, Color text, Color border) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  decoration: BoxDecoration(
    color: bg, borderRadius: BorderRadius.circular(8),
    border: Border.all(color: border),
  ),
  child: Text(label,
      style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w900, color: text)),
);

Widget _statsRow(int streak, int maxStreak, List<String> sports, {bool isMe = false}) {
  final divColor = isMe ? const Color(0xFF2A9FFF).withValues(alpha: 0.12) : _cardLine;
  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(border: Border(top: BorderSide(color: divColor))),
    child: Row(
      children: [
        // Streak
        Expanded(child: _statCol(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$streak ', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: _fire, height: 1)),
            const Text('🔥', style: TextStyle(fontSize: 14)),
          ]),
          label: 'Streak',
          divColor: divColor,
          showDiv: false,
        )),
        Container(width: 1, height: 32, color: divColor),
        // Max Streak
        Expanded(child: _statCol(
          child: Text('$maxStreak',
              style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
          label: 'Rekord',
          divColor: divColor,
          showDiv: false,
        )),
        Container(width: 1, height: 32, color: divColor),
        // Sports
        Expanded(child: _statCol(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: sports.take(3).map((s) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(sportEmoji(s), style: const TextStyle(fontSize: 15)),
            )).toList(),
          ),
          label: 'Sportarten',
          divColor: divColor,
          showDiv: false,
        )),
      ],
    ),
  );
}

Widget _statCol({required Widget child, required String label, required Color divColor, required bool showDiv}) {
  return Column(
    children: [
      child,
      const SizedBox(height: 3),
      Text(label.toUpperCase(),
          style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: const Color(0xFF3A5A6A))),
    ],
  );
}

// ─── Backward-compat classes (used elsewhere) ─────────────────────────────────
class SlideInFriendCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const SlideInFriendCard({super.key, required this.user});
  @override
  Widget build(BuildContext context) => _FriendCard(user: user, rank: 99);
}

class FriendRequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String currentUserId;
  const FriendRequestCard({super.key, required this.user, required this.currentUserId});
  @override
  Widget build(BuildContext context) => _RequestCard(user: user, currentUserId: currentUserId);
}

class FriendsListTab extends StatelessWidget {
  final String uid;
  const FriendsListTab({super.key, required this.uid});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService(uid: uid).userFriends,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Noch keine Freunde',
              style: GoogleFonts.barlow(color: const Color(0xFF444444))));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final id = (snapshot.data!.docs[index].data() as Map)['userId'];
            return FutureBuilder<Map<String, dynamic>?>(
              future: DatabaseService(uid: uid).getFriendData(id),
              builder: (_, snap) {
                if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                return FriendCard(user: snap.data!, key: ValueKey(id));
              },
            );
          },
        );
      },
    );
  }
}

class FriendCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const FriendCard({super.key, required this.user});
  @override
  Widget build(BuildContext context) => _FriendCard(user: user, rank: 99);
}
