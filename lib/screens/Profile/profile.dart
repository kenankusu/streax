import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streax/screens/shared/user.dart';
import 'package:streax/services/auth.dart';
import 'package:streax/services/database.dart';
import '../shared/navigationbar.dart';
import 'profile_widgets.dart';
import 'sport_editing.dart';
import 'delete_account.dart';
import '../shared/sport_utils.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF111214);
const _card     = Color(0xFF161920);
const _cardLine = Color(0xFF1F2228);
const _blue     = Color(0xFF2A9FFF);
const _orange   = Color(0xFFF0A020);
const _fire     = Color(0xFFFF6030);
const _secLbl   = Color(0xFF3A7A9A);
const _statLbl  = Color(0xFF3A5A6A);

// Sport chip color palette (cycling by index)
const _chipPalette = [
  {'border': Color(0xFF2A9FFF), 'bg': Color(0xFF0B2233), 'letter': Color(0xFF2A9FFF), 'name': Color(0xFF1A6090)},
  {'border': Color(0xFF1CE9B0), 'bg': Color(0xFF0B2620), 'letter': Color(0xFF1CE9B0), 'name': Color(0xFF0E7050)},
  {'border': Color(0xFF7C5FDC), 'bg': Color(0xFF1A1230), 'letter': Color(0xFF7C5FDC), 'name': Color(0xFF4A3890)},
  {'border': Color(0xFFF0A020), 'bg': Color(0xFF231800), 'letter': Color(0xFFF0A020), 'name': Color(0xFF8A5A10)},
];

// ─── Main screen ──────────────────────────────────────────────────────────────
class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final _auth = AuthService();
  bool _isDeleting = false;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).popUntil((r) => r.isFirst),
      );
      return const Scaffold(backgroundColor: _bg, body: SizedBox.shrink());
    }

    if (_isDeleting) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _blue),
              const SizedBox(height: 20),
              Text('Account wird gelöscht…',
                  style: GoogleFonts.barlow(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: DatabaseService(uid: user.uid).userData,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _blue));
              }
              if (snap.hasError && _isDeleting) return const SizedBox.shrink();

              final data = snap.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero ──────────────────────────────────────────────
                    ProfileHeroSection(userData: data, uid: user.uid),

                    // ── Content ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStreakRow(data),
                          _secLabel('Sportarten'),
                          _buildSportChips(context, data, user.uid),
                          _secLabel('Körperdaten'),
                          _buildBodyStats(data),
                          const SizedBox(height: 28),
                          const Divider(color: _cardLine, height: 1),
                          const SizedBox(height: 16),
                          _buildBottomActions(context, user.uid),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Navigation bar (always on top)
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: NavigationsLeiste(currentPage: 4),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _secLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _secLbl),
    ),
  );

  // ── Streak cards ───────────────────────────────────────────────────────────
  Widget _buildStreakRow(Map<String, dynamic> data) {
    final current = data['streak']     as int? ?? 0;
    final max     = data['streak_max'] as int? ?? 0;
    return Row(
      children: [
        Expanded(child: _streakCard(value: current, label: 'Aktueller Streak', emoji: '🔥', numColor: _fire)),
        const SizedBox(width: 10),
        Expanded(child: _streakCard(value: max,     label: 'Längster Streak',  emoji: '🏆', numColor: _orange)),
      ],
    );
  }

  Widget _streakCard({
    required int value,
    required String label,
    required String emoji,
    required Color numColor,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 30, fontWeight: FontWeight.w900, color: numColor, height: 1,
                  ),
                ),
                Text(emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _statLbl),
            ),
          ],
        ),
      );

  // ── Sport chips ────────────────────────────────────────────────────────────
  Widget _buildSportChips(BuildContext context, Map<String, dynamic> data, String uid) {
    final sports = data['sports'] != null
        ? (data['sports'] as List<dynamic>).cast<String>()
        : <String>[];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...sports.asMap().entries.map((e) {
            final colors = _chipPalette[e.key % _chipPalette.length];
            final sport  = e.value;
            return GestureDetector(
              onLongPress: () => _showRemoveDialog(context, sport, uid, data),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: colors['bg'],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors['border'] as Color, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      sportEmoji(sport),
                      style: const TextStyle(fontSize: 22, height: 1),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sport.length > 8 ? '${sport.substring(0, 7)}.' : sport,
                      style: GoogleFonts.barlow(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        letterSpacing: 0.4, color: colors['name'],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Add chip
          GestureDetector(
            onTap: () => SportSelectionDialog.show(context, uid, data),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF252830), width: 1.5),
              ),
              child: Column(
                children: [
                  Text('+',
                      style: GoogleFonts.barlowCondensed(
                          fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF333333), height: 1)),
                  const SizedBox(height: 5),
                  Text('Mehr',
                      style: GoogleFonts.barlow(
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: const Color(0xFF2A2D33))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, String sport, String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text('Sportart entfernen', style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('„$sport" entfernen?', style: GoogleFonts.barlow(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final list = List<String>.from(data['sports'] ?? []);
              list.remove(sport);
              await DatabaseService(uid: uid).updateUserSports(list);
            },
            child: const Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Body stats grid ────────────────────────────────────────────────────────
  Widget _buildBodyStats(Map<String, dynamic> data) {
    final age    = _calcAge(data['birthdate']);
    final weight = data['weight'];
    final height = data['height'];

    return Row(
      children: [
        Expanded(child: _statCard(value: age != null ? '$age' : '—', unit: 'Jahre', label: 'Alter')),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          value: weight != null ? '${(weight is double ? weight : double.tryParse('$weight') ?? 0).toInt()}' : '—',
          unit: 'kg', label: 'Gewicht',
        )),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          value: height != null ? '${(height is double ? height : double.tryParse('$height') ?? 0).toInt()}' : '—',
          unit: 'cm', label: 'Größe',
        )),
      ],
    );
  }

  Widget _statCard({required String value, required String unit, required String label}) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardLine),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
            const SizedBox(height: 1),
            Text(unit,
                style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF444444))),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: GoogleFonts.barlow(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _statLbl)),
          ],
        ),
      );

  int? _calcAge(String? dateStr) {
    if (dateStr == null) return null;
    final bd = DateTime.tryParse(dateStr);
    if (bd == null) return null;
    final now = DateTime.now();
    int age = now.year - bd.year;
    if (now.month < bd.month || (now.month == bd.month && now.day < bd.day)) age--;
    return age;
  }

  // ── Bottom actions ─────────────────────────────────────────────────────────
  Widget _buildBottomActions(BuildContext context, String uid) => Column(
    children: [
      _dangerBtn(Icons.logout,         'Abmelden',       _handleLogout),
      const SizedBox(height: 10),
      _dangerBtn(Icons.delete_forever, 'Account löschen', () {
        DeleteAccountDialog.show(context, uid, (v) => setState(() => _isDeleting = v));
      }),
    ],
  );

  Widget _dangerBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade900.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.barlow(color: Colors.red.shade400, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );

  Future<void> _handleLogout() async {
    await _auth.signOut();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }
}
