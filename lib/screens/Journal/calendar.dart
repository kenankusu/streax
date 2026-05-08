import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Shared/navigationbar.dart';
import '../../services/database.dart';
import '../../utils/sport_utils.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF111214);
const _card     = Color(0xFF161920);
const _cardLine = Color(0xFF1F2228);
const _border   = Color(0xFF252830);
const _cyan     = Color(0xFF00B4CC);
const _green    = Color(0xFF8ED832);
const _teal     = Color(0xFF1CE9B0);
const _fire     = Color(0xFFFF6030);
const _orange   = Color(0xFFF0A020);
const _secLbl   = Color(0xFF3A7A9A);
const _statLbl  = Color(0xFF3A5A6A);

const _months      = ['Januar','Februar','März','April','Mai','Juni','Juli','August','September','Oktober','November','Dezember'];
const _monthsShort = ['Jan','Feb','Mär','Apr','Mai','Jun','Jul','Aug','Sep','Okt','Nov','Dez'];
const _weekdays    = ['Mo','Di','Mi','Do','Fr','Sa','So'];

const _albumBgs = [
  Color(0xFF0B2233), Color(0xFF1A1008), Color(0xFF0B1E14),
  Color(0xFF1A1230), Color(0xFF231800), Color(0xFF0B2620),
];

// ─── Calendar page ────────────────────────────────────────────────────────────
class calendar extends StatefulWidget {
  const calendar({super.key});
  @override
  State<calendar> createState() => _calendarState();
}

class _calendarState extends State<calendar> {
  String _view = 'month';
  int _year  = DateTime.now().year;
  int _month = DateTime.now().month;

  /// key: "YYYY-M-D" → first activity that day
  Map<String, Map<String, dynamic>> _acts = {};
  int  _userStreak = 0;
  bool _loading    = true;

  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }

    // Load activities for this year + last year (for album history)
    final firstDay = DateTime(_year - 1, 1, 1).toIso8601String();
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('activities')
        .where('datum', isGreaterThanOrEqualTo: firstDay)
        .get();

    final userData = await DatabaseService(uid: user.uid).getFriendData(user.uid);

    final acts = <String, Map<String, dynamic>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = DateTime.tryParse(data['datum'] ?? '');
      if (date == null) continue;
      final key = '${date.year}-${date.month}-${date.day}';
      acts.putIfAbsent(key, () => data);
    }

    if (mounted) {
      setState(() {
        _acts        = acts;
        _userStreak  = userData?['streak'] as int? ?? 0;
        _loading     = false;
      });
    }
  }

  // ── Data helpers ─────────────────────────────────────────────────────────
  int _countMonth(int y, int m) => _acts.keys.where((k) {
    final p = k.split('-');
    return p.length == 3 && int.parse(p[0]) == y && int.parse(p[1]) == m;
  }).length;

  Map<String, Map<String, dynamic>> _actsForMonth(int y, int m) {
    final r = <String, Map<String, dynamic>>{};
    _acts.forEach((k, v) {
      final p = k.split('-');
      if (p.length == 3 && int.parse(p[0]) == y && int.parse(p[1]) == m) r[k] = v;
    });
    return r;
  }

  int _bestCount(int y) {
    int b = 0;
    for (int m = 1; m <= 12; m++) { final c = _countMonth(y, m); if (c > b) b = c; }
    return b;
  }

  int _bestMonthIndex(int y) {
    int b = 0, bm = 1;
    for (int m = 1; m <= 12; m++) { final c = _countMonth(y, m); if (c > b) { b = c; bm = m; } }
    return bm;
  }

  bool _isStreakDay(String key) {
    final p = key.split('-');
    if (p.length != 3) return false;
    final date     = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    final todayD   = DateTime(_today.year, _today.month, _today.day);
    final diff     = todayD.difference(date).inDays;
    if (diff < 0 || diff >= _userStreak) return false;
    for (int i = 0; i <= diff; i++) {
      final d = todayD.subtract(Duration(days: i));
      if (!_acts.containsKey('${d.year}-${d.month}-${d.day}')) return false;
    }
    return true;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _cyan, strokeWidth: 2))
              : Column(children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text('DEIN JOURNAL',
                        style: GoogleFonts.barlowCondensed(
                            fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white)),
                  ),

                  // Tab toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildToggle(),
                  ),

                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      child: _view == 'album' ? _buildAlbumView()
                           : _view == 'month' ? _buildMonthView()
                           :                   _buildYearView(),
                    ),
                  ),
                ]),
        ),
        const Positioned(
          bottom: 0, left: 0, right: 0,
          child: NavigationsLeiste(currentPage: 3),
        ),
      ]),
    );
  }

  // ── Tab toggle ────────────────────────────────────────────────────────────
  Widget _buildToggle() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1D21),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Row(children: [
      _tabBtn('Album', 'album'),
      _tabBtn('Monat', 'month'),
      _tabBtn('Jahr',  'year'),
    ]),
  );

  Widget _tabBtn(String label, String view) {
    final active = _view == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _view = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [Color(0xFF1A2D8A), _cyan])
                : null,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: GoogleFonts.barlow(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  color: active ? Colors.white : const Color(0xFF444444))),
        ),
      ),
    );
  }

  // ── Month view ────────────────────────────────────────────────────────────
  Widget _buildMonthView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Month nav
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navBtn(() {
            if (_month > 1) { setState(() => _month--); } else { setState(() { _month = 12; _year--; }); }
          }),
          Text(
            '${_months[_month - 1]} $_year'.toUpperCase(),
            style: GoogleFonts.barlow(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
          ),
          _navBtn(
            () {
              if (_month < 12) { setState(() => _month++); } else { setState(() { _month = 1; _year++; }); }
            },
            next: true,
          ),
        ],
      ),

      const SizedBox(height: 14),
      _buildCalendar(_year, _month),
      const SizedBox(height: 14),
      _secLabel('Stats'),
      _buildMonthStats(_year, _month),
    ],
  );

  Widget _navBtn(VoidCallback onTap, {bool next = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Icon(next ? Icons.chevron_right : Icons.chevron_left,
          color: const Color(0xFF888888), size: 20),
    ),
  );

  Widget _buildCalendar(int y, int m) {
    final firstDay    = DateTime(y, m, 1);
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final offset      = firstDay.weekday - 1; // Mon=0
    final monthActs   = _actsForMonth(y, m);

    return Column(children: [
      // Weekday headers
      Row(
        children: _weekdays.map((d) => Expanded(
          child: Text(d,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.6, color: const Color(0xFF3A4050))),
        )).toList(),
      ),
      const SizedBox(height: 4),

      // Day grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3,
        ),
        itemCount: offset + daysInMonth,
        itemBuilder: (_, i) {
          if (i < offset) return const SizedBox.shrink();
          final day   = i - offset + 1;
          final key   = '$y-$m-$day';
          final act   = monthActs[key];
          final today = y == _today.year && m == _today.month && day == _today.day;
          final streak = act != null && _isStreakDay(key);

          return GestureDetector(
            onTap: act != null ? () => _showDialog(act) : null,
            child: Container(
              decoration: BoxDecoration(
                gradient: today
                    ? const LinearGradient(
                        colors: [Color(0xFF2A9FFF), Color(0xFF1CE9B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: today
                    ? null
                    : act != null
                        ? (streak ? const Color(0xFF0B1E14) : _card)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: !today && act != null
                    ? Border.all(color: streak
                        ? _teal.withValues(alpha: 0.4)
                        : _cardLine)
                    : null,
              ),
              child: act != null
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(sportEmoji(act['option'] ?? ''),
                          style: const TextStyle(fontSize: 13, height: 1)),
                      Text('$day',
                          style: GoogleFonts.barlow(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: today ? Colors.white : _statLbl, height: 1.2)),
                    ])
                  : Center(
                      child: Text('$day',
                          style: GoogleFonts.barlow(
                              fontSize: 12,
                              fontWeight: today ? FontWeight.w900 : FontWeight.w600,
                              color: today ? Colors.white : const Color(0xFF555555))),
                    ),
            ),
          );
        },
      ),
    ]);
  }

  void _showDialog(Map<String, dynamic> act) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Text(sportEmoji(act['option'] ?? ''), style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(act['option'] ?? '',
              style: GoogleFonts.barlowCondensed(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if ((act['text'] ?? '').toString().isNotEmpty)
            Text(act['text'].toString(), style: GoogleFonts.barlow(color: Colors.white70, fontSize: 14)),
          if (act['dauer'] != null) ...[
            const SizedBox(height: 8),
            Text('⏱ ${act['dauer']} min', style: GoogleFonts.barlow(color: _statLbl, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          if (act['distanz'] != null)
            Text('📍 ${act['distanz']} km', style: GoogleFonts.barlow(color: _statLbl, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.barlow(color: _cyan, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Month stats ───────────────────────────────────────────────────────────
  Widget _buildMonthStats(int y, int m) {
    final cur  = _countMonth(y, m);
    final prev = _countMonth(m > 1 ? y : y - 1, m > 1 ? m - 1 : 12);
    final diff = cur - prev;
    final best = _bestCount(y);
    final bestM = _bestMonthIndex(y);

    final diffColor = diff > 0 ? _teal : diff < 0 ? const Color(0xFFFF4455) : _orange;
    final diffTxt   = diff > 0 ? '▲ +$diff vs. Vormonat' : diff < 0 ? '▼ ${diff.abs()} weniger als Vormonat' : '= gleich wie Vormonat';
    final prevTxt   = diff > 0 ? '▲ +$diff mehr' : diff < 0 ? '▼ ${diff.abs()} weniger' : '= gleich wie Vormonat';
    final msgs = [
      '$cur Aktivitäten — noch ${(best - cur).clamp(0, 99)} bis zu deinem Rekord.',
      'Du warst ${cur}x aktiv diesen Monat — weiter so! 💪',
      'Jeden Tag zählt. $cur Aktivitäten im Journal — dein zukünftiges Ich dankt dir.',
      'Noch ${(best - cur).clamp(0, 99)} bis zu deinem Monatsrekord von $best!',
    ];

    return Column(children: [
      // Highlight
      _highlightCard(
        icon: '📅',
        label: 'AKTIVITÄTEN DIESEN MONAT',
        value: '$cur',
        sub: diffTxt,
        subColor: diffColor,
        badgeVal: '$_userStreak🔥',
        badgeLabel: 'STREAK',
        badgeColor: _fire,
      ),
      const SizedBox(height: 8),

      // Two cards
      Row(children: [
        Expanded(child: _miniStat('VORHERIGER MONAT', '$prev', prevTxt, diffColor)),
        const SizedBox(width: 8),
        Expanded(child: _miniStat('BESTER MONAT', '$best', '🏆 ${_monthsShort[bestM - 1]} $y', _orange)),
      ]),
      const SizedBox(height: 8),

      // Motivation
      Container(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardLine)),
        child: Row(children: [
          const Text('💪', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(msgs[cur % msgs.length],
              style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF888888)))),
        ]),
      ),
    ]);
  }

  // ── Year view ─────────────────────────────────────────────────────────────
  Widget _buildYearView() {
    final total   = List.generate(12, (i) => _countMonth(_year, i + 1)).fold(0, (a, b) => a + b);
    final best    = _bestCount(_year);
    final dayCount = List.filled(7, 0);
    _acts.forEach((key, _) {
      final p = key.split('-');
      if (p.length == 3 && int.parse(p[0]) == _year) {
        final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        dayCount[d.weekday - 1]++;
      }
    });
    final maxD = dayCount.reduce((a, b) => a > b ? a : b);
    final bestDay = maxD > 0 ? _weekdays[dayCount.indexOf(maxD)] : '—';
    final avg = total > 0 ? (total / 12).toStringAsFixed(1) : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year nav
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navBtn(() => setState(() => _year--)),
            Text(
              '$_year',
              style: GoogleFonts.barlowCondensed(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  letterSpacing: 0.8, color: Colors.white),
            ),
            _navBtn(() => setState(() => _year++), next: true),
          ],
        ),
        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 104,
          ),
          itemCount: 12,
          itemBuilder: (_, i) => _miniMonth(i + 1),
        ),
        const SizedBox(height: 14),
        _secLabel('Jahresübersicht'),
        _highlightCard(
          icon: '📊',
          label: 'AKTIVITÄTEN GESAMT',
          value: '$total',
          sub: 'In diesem Jahr',
          subColor: _statLbl,
          badgeVal: '$best🏆',
          badgeLabel: 'BESTER MONAT',
          badgeColor: _orange,
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _miniStat('AKTIVSTER TAG', bestDay, 'Meistens aktiv', _teal)),
          const SizedBox(width: 8),
          Expanded(child: _miniStat('Ø PRO MONAT', avg, 'Aktivitäten', const Color(0xFF2A9FFF))),
        ]),
      ],
    );
  }

  Widget _miniMonth(int m) {
    final now      = DateTime.now();
    final current  = m == now.month && _year == now.year;
    final isPast   = _year < now.year || (_year == now.year && m < now.month);
    final acts     = _actsForMonth(_year, m);
    final count    = acts.length;
    final daysInM  = DateTime(_year, m + 1, 0).day;

    // XP: 50 base + intensity bonus per activity
    int xp = 0;
    for (final a in acts.values) {
      final intensity = a['intensity'] as String?;
      xp += intensity == 'hard' ? 75 : intensity == 'mid' ? 60 : 50;
    }

    // Longest streak within this month
    int longestStreak = 0, cur = 0;
    for (int d = 1; d <= daysInM; d++) {
      if (acts.containsKey('$_year-$m-$d')) {
        cur++;
        if (cur > longestStreak) longestStreak = cur;
      } else {
        cur = 0;
      }
    }

    final labelColor = isPast && !current ? const Color(0xFF2A2D35) : _statLbl;

    return GestureDetector(
      onTap: () => setState(() { _month = m; _view = 'month'; }),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: current ? const Color(0xFF0B1A20) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: current ? _cyan.withValues(alpha: 0.4) : _cardLine,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_monthsShort[m - 1].toUpperCase(),
                style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700,
                    letterSpacing: 0.7, color: labelColor)),
            const SizedBox(height: 4),

            // 31 dots — one per calendar day
            Wrap(
              spacing: 2, runSpacing: 2,
              children: List.generate(31, (i) {
                final day    = i + 1;
                final hasAct = acts.containsKey('$_year-$m-$day');
                final beyond = day > daysInM;
                return Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasAct
                        ? const LinearGradient(colors: [_cyan, _green])
                        : null,
                    color: hasAct ? null
                        : beyond  ? Colors.transparent
                        :           const Color(0xFF1E2228),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),

            // Activity count + XP (immer farbig)
            Text.rich(TextSpan(children: [
              TextSpan(text: '$count ',
                  style: GoogleFonts.barlowCondensed(fontSize: 13,
                      fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
              TextSpan(text: 'Akt.',
                  style: GoogleFonts.barlow(fontSize: 8, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5, color: labelColor)),
            ])),
            if (xp > 0)
              Text('+$xp XP',
                  style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700,
                      color: _cyan, height: 1.3)),

            const Spacer(),

            // Längster Streak — unten verankert
            if (longestStreak > 0)
              Text('Längster Streak: $longestStreak',
                  style: GoogleFonts.barlow(fontSize: 8, fontWeight: FontWeight.w600,
                      color: Colors.white70, height: 1.2)),
          ],
        ),
      ),
    );
  }

  // ── Album view ────────────────────────────────────────────────────────────
  Widget _buildAlbumView() {
    final groups = <String, List<Map<String, dynamic>>>{};
    _acts.forEach((key, act) {
      final p = key.split('-');
      if (p.length < 2) return;
      final gk = '${p[0]}-${p[1].padLeft(2, '0')}';
      groups.putIfAbsent(gk, () => []).add({...act, '_key': key});
    });
    final sorted = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(children: [
            const Text('📷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Noch keine Aktivitäten',
                style: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3A4050))),
            const SizedBox(height: 6),
            Text('Erstelle deine erste Aktivität!',
                style: GoogleFonts.barlow(fontSize: 11, color: _border)),
          ]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((gk) {
        final p  = gk.split('-');
        final y  = int.parse(p[0]);
        final m  = int.parse(p[1]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_months[m - 1]} $y'.toUpperCase(),
                style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700,
                    letterSpacing: 0.8, color: _secLbl)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 3, crossAxisSpacing: 3,
              children: (groups[gk] ?? []).map(_albumCell).toList(),
            ),
            const SizedBox(height: 14),
          ],
        );
      }).toList(),
    );
  }

  Widget _albumCell(Map<String, dynamic> act) {
    final sport    = (act['option'] ?? '').toString();
    final photoUrl = act['photoUrl'] as String?;
    final bgIdx    = sport.hashCode.abs() % _albumBgs.length;

    final emoji = sportEmoji(sport);

    return GestureDetector(
      onTap: () => _showDialog(act),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(fit: StackFit.expand, children: [
          // Background: photo or colored placeholder
          if (photoUrl != null && photoUrl.isNotEmpty)
            Image.network(photoUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _albumPlaceholder(sport, bgIdx))
          else
            _albumPlaceholder(sport, bgIdx),

          // Emoji bottom-right
          Positioned(
            bottom: 5, right: 5,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 13, height: 1)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _albumPlaceholder(String sport, int bgIdx) => Container(
    color: _albumBgs[bgIdx],
  );

  // ── Shared stat widgets ───────────────────────────────────────────────────
  Widget _highlightCard({
    required String icon, required String label, required String value,
    required String sub, required Color subColor,
    required String badgeVal, required String badgeLabel, required Color badgeColor,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x121CE9B0), Color(0x0D2A9FFF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _teal.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: _secLbl)),
            Text(value,
                style: GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
            Text(sub,
                style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w600, color: subColor)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B2233),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1A4A6A)),
            ),
            child: Column(children: [
              Text(badgeVal,
                  style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: badgeColor, height: 1)),
              Text(badgeLabel,
                  style: GoogleFonts.barlow(fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: _statLbl)),
            ]),
          ),
        ]),
      );

  Widget _miniStat(String label, String val, String sub, Color subColor) => Container(
    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardLine)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: _statLbl)),
      const SizedBox(height: 4),
      Text(val,
          style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
      const SizedBox(height: 2),
      Text(sub,
          style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
    ]),
  );

  Widget _secLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _secLbl)),
  );
}
