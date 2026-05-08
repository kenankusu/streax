import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/sport_utils.dart';
import 'friend_actions.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF111214);
const _card     = Color(0xFF161920);
const _cardLine = Color(0xFF1F2228);
const _border   = Color(0xFF252830);
const _blue     = Color(0xFF2A9FFF);
const _green    = Color(0xFF1CE9B0);
const _fire     = Color(0xFFFF6030);
const _orange   = Color(0xFFF0A020);
const _secLbl   = Color(0xFF3A7A9A);

// Sport chip palette (cycling)
const _chipPalette = [
  {'border': Color(0xFFF0A020), 'bg': Color(0xFF231800), 'letter': Color(0xFFF0A020), 'name': Color(0xFF8A5A10)},
  {'border': Color(0xFF7C5FDC), 'bg': Color(0xFF1A1230), 'letter': Color(0xFF7C5FDC), 'name': Color(0xFF4A3890)},
  {'border': Color(0xFF1CE9B0), 'bg': Color(0xFF0B2620), 'letter': Color(0xFF1CE9B0), 'name': Color(0xFF0E7050)},
  {'border': Color(0xFF2A9FFF), 'bg': Color(0xFF0B2233), 'letter': Color(0xFF2A9FFF), 'name': Color(0xFF1A6090)},
];

// ─── Level helpers (same as profile.dart) ────────────────────────────────────
int _level(int streakMax) => ((streakMax * 10) / 100).floor() + 1;
double _xpProgress(int streakMax) => ((streakMax * 10) % 100 / 100.0).clamp(0.0, 1.0);
int _xp(int streakMax) => streakMax * 10;
int _nextXp(int streakMax) => _level(streakMax) * 100;

String _initials(Map u) {
  final f = (u['firstName'] ?? '').toString();
  final l = (u['lastName'] ?? '').toString();
  return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
}

// ─── ProfileView ──────────────────────────────────────────────────────────────
class ProfileView extends StatelessWidget {
  final Map<String, dynamic> user;
  const ProfileView({super.key, required this.user});

  Future<Map<String, dynamic>> _load() async {
    final uid = user['uid'] as String? ?? '';
    final me  = FirebaseAuth.instance.currentUser;

    final results = await Future.wait([
      // Full user data
      FirebaseFirestore.instance.collection('users').doc(uid).get(),
      // My own data for comparison
      me != null
          ? FirebaseFirestore.instance.collection('users').doc(me.uid).get()
          : Future.value(null),
      // Total activities
      FirebaseFirestore.instance
          .collection('users').doc(uid).collection('activities').get(),
      // My friends for rank
      me != null
          ? FirebaseFirestore.instance
              .collection('users').doc(me.uid).collection('friends').get()
          : Future.value(null),
    ]);

    final userData  = (results[0] as DocumentSnapshot).data() as Map<String, dynamic>? ?? {};
    final myData    = (results[1] as DocumentSnapshot?)?.data() as Map<String, dynamic>? ?? {};
    final actSnap   = results[2] as QuerySnapshot;
    final frSnap    = results[3] as QuerySnapshot?;

    final theirStreak = userData['streak'] as int? ?? 0;

    // Rank: how many of MY friends have a higher streak than this person?
    int rank = 1;
    if (frSnap != null && me != null) {
      for (final doc in frSnap.docs) {
        final fId   = (doc.data() as Map)['userId'] as String?;
        if (fId == null || fId == uid) continue;
        final fDoc  = await FirebaseFirestore.instance
            .collection('users').doc(fId).get();
        final fStr  = (fDoc.data()?['streak'] as int?) ?? 0;
        if (fStr > theirStreak) rank++;
      }
    }

    return {
      'userData':       userData,
      'myStreak':       myData['streak'] as int? ?? 0,
      'totalActivities': actSnap.docs.length,
      'rank':           rank,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _load(),
          builder: (context, snap) {
            final loading  = !snap.hasData;
            final d        = snap.data ?? {};
            final userData = d['userData'] as Map<String, dynamic>? ?? {};
            final merged   = {...user, ...userData};

            final streak    = merged['streak']     as int? ?? 0;
            final streakMax = (userData['streak_max'] ?? userData['highest_streak'] ?? streak) as int? ?? streak;
            final myStreak  = d['myStreak'] as int? ?? 0;
            final total     = d['totalActivities'] as int? ?? 0;
            final rank      = d['rank']  as int? ?? 1;
            final sports    = (userData['sports'] as List?)?.cast<String>() ?? [];
            final imgUrl    = (merged['profileImageUrl'] ?? '').toString();
            final name      = '${merged['firstName'] ?? ''} ${merged['lastName'] ?? ''}'.trim();
            final handle    = merged['username'] ?? '';
            final lv        = _level(streakMax);
            final xpVal     = _xp(streakMax);
            final xpNext    = _nextXp(streakMax);
            final xpProg    = _xpProgress(streakMax);
            final diff      = streak - myStreak;

            return Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2024), shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2A2D33)),
                          ),
                          child: const Icon(Icons.chevron_left, color: Color(0xFF888888), size: 20),
                        ),
                      ),
                      Expanded(
                        child: Text('PROFIL',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.barlowCondensed(
                                fontSize: 20, fontWeight: FontWeight.w900,
                                letterSpacing: 0.8, color: Colors.white)),
                      ),
                      // Three-dots menu
                      GestureDetector(
                        onTap: () => _showMenu(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: _card, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(Icons.more_horiz, color: Color(0xFF666666), size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                    child: loading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: CircularProgressIndicator(color: _blue, strokeWidth: 2),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Hero card ────────────────────────────────
                              _heroCard(context, name, handle, imgUrl, lv, xpVal, xpNext, xpProg, streak, rank),
                              const SizedBox(height: 14),

                              // ── Streak banner ─────────────────────────────
                              _streakBanner(streak, myStreak, diff),
                              const SizedBox(height: 14),

                              // ── Compare bar ───────────────────────────────
                              _compareBar(name.split(' ').first, streak, myStreak),
                              const SizedBox(height: 4),

                              // ── Sports ────────────────────────────────────
                              if (sports.isNotEmpty) ...[
                                _secLabel('Sportarten'),
                                _sportRow(sports),
                              ],

                              // ── Stats ─────────────────────────────────────
                              _secLabel('Stats'),
                              _trophyCard('🏆', 'Längster Streak', '$streakMax', 'Tage in Folge'),
                              const SizedBox(height: 8),
                              _trophyCard('🥇', 'Platzierung', '#$rank', 'Rang unter Freunden'),
                              const SizedBox(height: 8),
                              _plainStatCard('$total', 'Gesamt', 'Aktivitäten'),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Three-dots menu ────────────────────────────────────────────────────────
  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_remove_outlined, color: Colors.red.shade400, size: 22),
              title: Text('Freund entfernen',
                  style: GoogleFonts.barlow(color: Colors.red.shade400, fontWeight: FontWeight.w700, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                FriendActions.removeFriend(context, user);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Hero card ──────────────────────────────────────────────────────────────
  Widget _heroCard(BuildContext context, String name, String handle, String imgUrl,
      int lv, int xpVal, int xpNext, double xpProg, int streak, int rank) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle top glow
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1),
                  radius: 0.8,
                  colors: [Color(0x1200B4CC), Colors.transparent],
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Accent bar
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2D8A), Color(0xFF00B4CC), Color(0xFF8ED832)],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E2228),
                        border: Border.all(color: _border, width: 2),
                      ),
                      child: ClipOval(
                        child: imgUrl.isNotEmpty
                            ? Image.network(imgUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultAvatar(user))
                            : _defaultAvatar(user),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Level row
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1400),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _orange),
                        ),
                        child: Text('LEVEL',
                            style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _orange)),
                      ),
                      const SizedBox(width: 8),
                      Text('$lv',
                          style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w900, color: _fire)),
                    ]),

                    const SizedBox(height: 8),

                    // Name
                    Text(name,
                        style: GoogleFonts.barlowCondensed(
                            fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.white)),

                    Text('@$handle',
                        style: GoogleFonts.barlow(fontSize: 12, color: const Color(0xFF444444), fontWeight: FontWeight.w600, letterSpacing: 0.4)),

                    // XP bar
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 200,
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('XP', style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: const Color(0xFF3A5A6A))),
                          Text('$xpVal / $xpNext', style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF00B4CC))),
                        ]),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(children: [
                            Container(height: 3, color: const Color(0xFF1E2228)),
                            FractionallySizedBox(
                              widthFactor: xpProg,
                              child: Container(
                                height: 3,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF1A2D8A), Color(0xFF00B4CC), Color(0xFF8ED832)],
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 18),

                    // Action buttons
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {}, // placeholder
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B4CC).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00B4CC).withValues(alpha: 0.25)),
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.track_changes_outlined, color: Color(0xFF00B4CC), size: 16),
                              const SizedBox(width: 7),
                              Text('Gemeinsames Ziel setzen',
                                  style: GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF00B4CC))),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),

          // Rank badge
          Positioned(
            top: 18, right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1400),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _orange),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🏅', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text('#$rank Platz',
                    style: GoogleFonts.barlowCondensed(
                        fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: _orange)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(Map u) => Center(
    child: Text(_initials(u),
        style: GoogleFonts.barlowCondensed(fontSize: 34, fontWeight: FontWeight.w900, color: const Color(0xFF888888))),
  );

  // ── Streak banner ──────────────────────────────────────────────────────────
  Widget _streakBanner(int streak, int myStreak, int diff) {
    final ahead = diff > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x1AFF6030), Color(0x0FF0A020)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$streak',
                  style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: _fire, height: 1)),
              Text('AKTUELLER STREAK',
                  style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: const Color(0xFF884020))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Du: ', style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3A4555))),
              TextSpan(text: '$myStreak 🔥', style: GoogleFonts.barlow(fontSize: 11, fontWeight: FontWeight.w700, color: _blue)),
            ])),
            const SizedBox(height: 2),
            if (diff != 0)
              Text(
                ahead ? '▲${diff.abs()} Tage vor dir' : '▼${diff.abs()} Tage hinter dir',
                style: GoogleFonts.barlow(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: ahead ? _green : const Color(0xFFFF4455)),
              ),
          ]),
        ],
      ),
    );
  }

  // ── Compare bar ────────────────────────────────────────────────────────────
  Widget _compareBar(String theirFirstName, int theirStreak, int myStreak) {
    final max = (theirStreak > myStreak ? theirStreak : myStreak).toDouble();
    final safe = max == 0 ? 1.0 : max;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardLine),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DIREKTER VERGLEICH',
            style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: const Color(0xFF3A5A6A))),
        const SizedBox(height: 10),
        _compareRow(theirFirstName, theirStreak, theirStreak / safe,
            const Color(0xFFF0A020), const [Color(0xFFF0A020), Color(0xFFFF6030)], them: true),
        const SizedBox(height: 6),
        _compareRow('Du', myStreak, myStreak / safe,
            _blue, const [Color(0xFF2A9FFF), Color(0xFF1CE9B0)], them: false),
      ]),
    );
  }

  Widget _compareRow(String label, int val, double frac, Color textColor,
      List<Color> gradColors, {required bool them}) {
    return Row(children: [
      SizedBox(
        width: 28,
        child: Text(label.length > 3 ? '${label.substring(0, 2)}.' : label,
            textAlign: TextAlign.right,
            style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(children: [
            Container(height: 6, color: const Color(0xFF1A1D21)),
            FractionallySizedBox(
              widthFactor: frac.clamp(0.02, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradColors),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 28,
        child: Text('$val',
            style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w900, color: textColor)),
      ),
    ]);
  }

  // ── Sports ─────────────────────────────────────────────────────────────────
  Widget _sportRow(List<String> sports) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sports.asMap().entries.map((e) {
          final colors = _chipPalette[e.key % _chipPalette.length];
          final s = e.value;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: colors['bg'],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors['border'] as Color, width: 1.5),
            ),
            child: Column(children: [
              Text(sportEmoji(s), style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(
                s.length > 8 ? '${s.substring(0, 7)}.' : s,
                style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: colors['name'] as Color),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Trophy / Medal card ────────────────────────────────────────────────────
  Widget _trophyCard(String emoji, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1400),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A2800)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: const Color(0xFF6A4A10))),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFF0C040), Color(0xFFF0A020), Color(0xFFE06010)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(value,
                style: GoogleFonts.barlowCondensed(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
          ),
          Text(unit,
              style: GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7A5010))),
        ]),
      ]),
    );
  }

  // ── Normal stat card ───────────────────────────────────────────────────────
  Widget _plainStatCard(String value, String unit, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardLine),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
        Text(unit,
            style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF444444))),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: const Color(0xFF3A5A6A))),
      ]),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _secLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(text.toUpperCase(),
        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _secLbl)),
  );
}
