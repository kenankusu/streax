import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/services/database.dart';
import 'package:streax/shared/constants/theme_constants.dart';
import 'package:streax/shared/constants/sport_utils.dart';

enum _GoalType { gewohnheit, event, koerperziel }

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  _GoalType _type = _GoalType.gewohnheit;

  // Gewohnheit
  String? _habitSport;
  int _freq = 3;
  String _period = 'Woche';

  // Event
  final _eventNameCtrl = TextEditingController();
  String? _eventSport;
  DateTime? _eventDate;

  // Körperziel
  String _metric = 'Gewicht';
  DateTime? _targetDate;
  double _startVal = 80;
  double _targetVal = 75;
  final _notesCtrl = TextEditingController();

  // Loaded from user profile
  List<String> _userSports = [];
  bool _loadingProfile = true;

  static const _metrics = ['Gewicht', 'Körperfett', 'Muskelmasse'];

  static const _metricEmoji = {
    'Gewicht': '⚖️',
    'Körperfett': '📊',
    'Muskelmasse': '💪',
  };

  static const _metricUnit = {
    'Gewicht': 'kg',
    'Körperfett': '%',
    'Muskelmasse': 'kg',
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    final doc = await DatabaseService(uid: user.uid).userCollection.doc(user.uid).get();
    if (!mounted) return;
    final data = doc.data() as Map<String, dynamic>?;
    setState(() {
      _userSports = (data?['sports'] as List<dynamic>?)?.cast<String>() ?? [];
      final w = (data?['weight'] as num?)?.toDouble();
      if (w != null && w > 0) {
        _startVal = w;
        _targetVal = (w - 5).clamp(30, 200);
      }
      _loadingProfile = false;
    });
  }

  @override
  void dispose() {
    _eventNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    switch (_type) {
      case _GoalType.gewohnheit:
        return _habitSport != null;
      case _GoalType.event:
        return _eventNameCtrl.text.trim().isNotEmpty && _eventDate != null;
      case _GoalType.koerperziel:
        return _targetDate != null && _startVal != _targetVal;
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = <String, dynamic>{'createdAt': FieldValue.serverTimestamp()};

    switch (_type) {
      case _GoalType.gewohnheit:
        data.addAll({
          'type': 'Gewohnheit',
          'sport': _habitSport,
          'targetFrequency': _freq,
          'period': _period,
        });
      case _GoalType.event:
        data.addAll({
          'type': 'Event',
          'name': _eventNameCtrl.text.trim(),
          'sport': _eventSport,
          'eventDate': _eventDate!.toIso8601String(),
        });
      case _GoalType.koerperziel:
        data.addAll({
          'type': 'Körperziel',
          'messgröße': _metric,
          'startValue': _startVal,
          'targetValue': _targetVal,
          'bisWann': _targetDate!.toIso8601String(),
          'notes': _notesCtrl.text.trim(),
        });
    }

    try {
      await DatabaseService(uid: user.uid).addGoal(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _secLabel('Zieltyp', topPad: 0),
                    _typeGrid(),
                    _typeContent(),
                    _saveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2024),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2A2D33)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Color(0xFF888888)),
            ),
          ),
          const Expanded(
            child: Text(
              'NEUES ZIEL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  // ─── SECTION LABEL ──────────────────────────────────────────────────────────

  Widget _secLabel(String text, {double topPad = 20}) {
    return Padding(
      padding: EdgeInsets.only(top: topPad, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Color(0xFF3A7A9A),
        ),
      ),
    );
  }

  // ─── TYPE GRID ──────────────────────────────────────────────────────────────

  Widget _typeGrid() {
    return Row(
      children: [
        _typeCard(_GoalType.gewohnheit, '🏋️', 'Gewohnheit',
            activeColor: kBlue, activeBg: const Color(0xFF0B2233)),
        const SizedBox(width: 8),
        _typeCard(_GoalType.event, '🏆', 'Event',
            activeColor: kMid, activeBg: const Color(0xFF1A1008)),
        const SizedBox(width: 8),
        _typeCard(_GoalType.koerperziel, '⚖️', 'Körperziel',
            activeColor: kGreen, activeBg: const Color(0xFF0B1E14)),
      ],
    );
  }

  Widget _typeCard(
    _GoalType type,
    String emoji,
    String label, {
    required Color activeColor,
    required Color activeBg,
  }) {
    final isActive = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? activeBg : kCard,
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFF1F2228),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isActive ? activeColor : const Color(0xFF555555),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TYPE CONTENT ───────────────────────────────────────────────────────────

  Widget _typeContent() {
    switch (_type) {
      case _GoalType.gewohnheit:
        return _habitContent();
      case _GoalType.event:
        return _eventContent();
      case _GoalType.koerperziel:
        return _bodyContent();
    }
  }

  // ─── GEWOHNHEIT ─────────────────────────────────────────────────────────────

  Widget _habitContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secLabel('Deine Sportarten'),
        _sportChips(_habitSport, (s) => setState(() => _habitSport = s)),
        _secLabel('Häufigkeit'),
        _stepper(),
        _secLabel('Zeitraum'),
        _periodChips(),
        _secLabel('Vorschau'),
        _habitPreview(),
      ],
    );
  }

  Widget _sportChips(String? selected, void Function(String) onSelect) {
    if (_loadingProfile) {
      return const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_userSports.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          border: Border.all(color: const Color(0xFF252830)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Keine Sportarten im Profil gesetzt — füge sie in deinem Profil hinzu.',
          style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _userSports.map((sport) {
        final isOn = selected == sport;
        return GestureDetector(
          onTap: () => onSelect(sport),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: BoxDecoration(
              color: isOn ? const Color(0xFF0B2233) : const Color(0xFF1A1D21),
              border: Border.all(
                color: isOn ? kBlue : const Color(0xFF252830),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sportEmoji(sport), style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  sport,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOn ? kBlue : const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stepper() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        border: Border.all(color: const Color(0xFF252830)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _stepBtn('−', () => setState(() => _freq = (_freq - 1).clamp(1, 7))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    '$_freq',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'mal pro',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _stepBtn('+', () => setState(() => _freq = (_freq + 1).clamp(1, 7))),
        ],
      ),
    );
  }

  Widget _stepBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, color: Color(0xFF555555)),
          ),
        ),
      ),
    );
  }

  Widget _periodChips() {
    const periods = ['Woche', 'Monat', 'Jahr'];
    return Row(
      children: periods.asMap().entries.map((e) {
        final isOn = _period == e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < periods.length - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _period = e.value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isOn ? const Color(0xFF0B2233) : const Color(0xFF1A1D21),
                  border: Border.all(
                    color: isOn ? kBlue : const Color(0xFF252830),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  e.value.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isOn ? kBlue : const Color(0xFF555555),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _habitPreview() {
    final sport = _habitSport ?? 'Sport';
    final emoji = _habitSport != null ? sportEmoji(_habitSport!) : '🏋️';
    return _previewCard(
      color: const Color(0xFF0B1A2E),
      border: const Color(0xFF1A3A5A),
      emoji: emoji,
      name: '$_freq× $sport pro $_period',
      badgeText: 'Gewohnheit',
      badgeColor: kBlue,
      badgeBg: const Color(0xFF0B2233),
      badgeBorder: const Color(0xFF1A4A6A),
      progress: 0.33,
      gradientColors: const [kBlue, kGreen],
      sub: '0 / $_freq diese $_period',
    );
  }

  // ─── EVENT ──────────────────────────────────────────────────────────────────

  Widget _eventContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secLabel('Event-Name'),
        _fieldInput(_eventNameCtrl, 'z.B. Hannover Marathon',
            onChanged: (_) => setState(() {})),
        _secLabel('Sportart'),
        _sportChips(_eventSport, (s) => setState(() => _eventSport = s)),
        _secLabel('Datum'),
        _datePicker(_eventDate, (d) => setState(() => _eventDate = d)),
        if (_eventDate != null) ...[
          _secLabel('Countdown'),
          _countdownRow(_eventDate!),
        ],
        _secLabel('Vorschau'),
        _eventPreview(),
      ],
    );
  }

  Widget _fieldInput(
    TextEditingController ctrl,
    String hint, {
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Color(0xFF3A4050), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: const Color(0xFF1A1D21),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF252830)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF252830)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue),
        ),
        contentPadding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      ),
    );
  }

  Widget _datePicker(DateTime? date, void Function(DateTime) onPicked) {
    final hasDate = date != null;
    final text = hasDate
        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
        : 'Datum auswählen';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          border: Border.all(color: const Color(0xFF252830)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasDate ? Colors.white : const Color(0xFF3A4050),
              ),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Color(0xFF555555)),
          ],
        ),
      ),
    );
  }

  Widget _countdownRow(DateTime date) {
    final now = DateTime.now();
    final days = date.difference(now).inDays.clamp(0, 9999);
    final weeks = (days / 7).floor();
    final months = (days / 30).floor();
    return Row(
      children: [
        _cdBox('$days', 'Tage'),
        const SizedBox(width: 8),
        _cdBox('$weeks', 'Wochen'),
        const SizedBox(width: 8),
        _cdBox('$months', 'Monate'),
      ],
    );
  }

  Widget _cdBox(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          border: Border.all(color: const Color(0xFF252830)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: kMid,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: Color(0xFF3A4050),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventPreview() {
    final name = _eventNameCtrl.text.trim().isEmpty
        ? 'Dein Event'
        : _eventNameCtrl.text.trim();
    final sport = _eventSport ?? '';
    final emoji = sport.isNotEmpty ? sportEmoji(sport) : '🏆';
    int? daysLeft;
    String dateStr = '';
    if (_eventDate != null) {
      daysLeft = _eventDate!.difference(DateTime.now()).inDays.clamp(0, 9999);
      const months = [
        'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
        'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
      ];
      dateStr =
          '${_eventDate!.day}. ${months[_eventDate!.month - 1]} ${_eventDate!.year}';
    }

    return _previewCard(
      color: const Color(0xFF1A1208),
      border: const Color(0xFF4A2E08),
      emoji: emoji,
      name: name,
      badgeText: daysLeft != null ? '$daysLeft Tage' : '–',
      badgeColor: kMid,
      badgeBg: const Color(0xFF231800),
      badgeBorder: const Color(0xFF5A3000),
      progress: daysLeft != null ? 0.3 : 0,
      gradientColors: const [kMid, kFire],
      sub: [if (sport.isNotEmpty) '$emoji $sport', if (dateStr.isNotEmpty) dateStr]
          .join(' · '),
    );
  }

  // ─── KÖRPERZIEL ─────────────────────────────────────────────────────────────

  Widget _bodyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secLabel('Messgröße'),
        _metricSelector(),
        _secLabel('Start → Ziel'),
        _bodyRange(),
        _secLabel('Bis wann'),
        _datePicker(_targetDate, (d) => setState(() => _targetDate = d)),
        _secLabel('Notizen (optional)'),
        _fieldInput(_notesCtrl, 'z.B. Weniger Zucker, mehr Cardio'),
        _secLabel('Vorschau'),
        _bodyPreview(),
      ],
    );
  }

  Widget _metricSelector() {
    return Row(
      children: _metrics.asMap().entries.map((e) {
        final isOn = _metric == e.value;
        final emoji = _metricEmoji[e.value] ?? '⚖️';
        final unit = _metricUnit[e.value] ?? 'kg';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < _metrics.length - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _metric = e.value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: isOn ? const Color(0xFF0B1E14) : kCard,
                  border: Border.all(
                    color: isOn ? kGreen : const Color(0xFF1F2228),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isOn ? kGreen : const Color(0xFF555555),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '($unit)',
                      style: const TextStyle(
                          fontSize: 8, color: Color(0xFF3A4050)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bodyRange() {
    return Row(
      children: [
        Expanded(
          child: _valueBox(
            _startVal,
            'Aktuell',
            isTarget: false,
            onChange: (v) => setState(() => _startVal = v),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('→', style: TextStyle(fontSize: 18, color: Color(0xFF3A4050))),
        ),
        Expanded(
          child: _valueBox(
            _targetVal,
            'Ziel',
            isTarget: true,
            onChange: (v) => setState(() => _targetVal = v),
          ),
        ),
      ],
    );
  }

  Widget _valueBox(
    double val,
    String label, {
    required bool isTarget,
    required void Function(double) onChange,
  }) {
    return GestureDetector(
      onTap: () => _showValuePicker(val, onChange),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          border: Border.all(color: const Color(0xFF252830)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              val.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isTarget ? kGreen : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: Color(0xFF3A5A6A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showValuePicker(double current, void Function(double) onChange) {
    final init = (current - 30).round().clamp(0, 170);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Colors.grey[900],
        child: Column(
          children: [
            Expanded(
              child: CupertinoPicker(
                backgroundColor: Colors.transparent,
                itemExtent: 40,
                scrollController: FixedExtentScrollController(initialItem: init),
                onSelectedItemChanged: (i) => onChange((i + 30).toDouble()),
                children: List.generate(
                  171,
                  (i) => Center(
                    child: Text(
                      '${i + 30}',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fertig', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyPreview() {
    final unit = _metricUnit[_metric] ?? 'kg';
    final emoji = _metricEmoji[_metric] ?? '⚖️';
    final diff = _targetVal - _startVal;
    final diffStr =
        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} $unit';
    String dateStr = '';
    if (_targetDate != null) {
      const months = [
        'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
        'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
      ];
      dateStr =
          'bis ${_targetDate!.day}. ${months[_targetDate!.month - 1]} ${_targetDate!.year}';
    }
    return _previewCard(
      color: const Color(0xFF0B1A14),
      border: const Color(0xFF0E4030),
      emoji: emoji,
      name:
          '$_metric: ${_startVal.toStringAsFixed(1)} → ${_targetVal.toStringAsFixed(1)} $unit',
      badgeText: 'Körperziel',
      badgeColor: kGreen,
      badgeBg: const Color(0xFF0B2620),
      badgeBorder: const Color(0xFF0E5040),
      progress: 0.45,
      gradientColors: const [kGreen, kBlue],
      sub: '$diffStr${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
    );
  }

  // ─── SHARED PREVIEW CARD ────────────────────────────────────────────────────

  Widget _previewCard({
    required Color color,
    required Color border,
    required String emoji,
    required String name,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required Color badgeBorder,
    required double progress,
    required List<Color> gradientColors,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  border: Border.all(color: badgeBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _progressBar(progress, gradientColors),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(double progress, List<Color> colors) {
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  // ─── SAVE BUTTON ────────────────────────────────────────────────────────────

  Widget _saveButton() {
    return GestureDetector(
      onTap: _canSave ? _save : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: _canSave
              ? const LinearGradient(
                  colors: [Color(0xFF1A2D8A), Color(0xFF00B4CC)],
                )
              : null,
          color: _canSave ? null : const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'ZIEL SPEICHERN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            color: _canSave ? Colors.white : const Color(0xFF3A4050),
          ),
        ),
      ),
    );
  }
}
