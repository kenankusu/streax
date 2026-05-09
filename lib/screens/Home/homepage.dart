import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:streax/models/user.dart';
import 'package:streax/shared/constants/theme_constants.dart';
import 'widgets/home_header.dart';
import 'widgets/week_strip.dart';
import 'widgets/feed_preview.dart';
import 'goals/goals_popup.dart';
import 'goals/goal_indicator.dart';
import 'goals/create_goal_screen.dart';
import '../../shared/widgets/navigation_bar.dart';
import '../Journal/calendar.dart';
import '../../services/database.dart';
import '../Friends/feed.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 22),

                  // Deine Woche
                  _SectionHeader(
                    title: 'Deine Woche',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => calendar()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const WeekStrip(),
                  const SizedBox(height: 22),

                  // Feed
                  _SectionHeader(
                    title: 'Feed',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Feed()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FeedPreview(userId: user.uid),
                  const SizedBox(height: 22),

                  // Meine Ziele — title taps into management popup, "+" opens create screen
                  _GoalsHeader(
                    onManage: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ZielePopup(),
                    ),
                    onAdd: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: DatabaseService(uid: user.uid).userGoals,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Fehler beim Laden der Ziele',
                          style: TextStyle(color: Colors.red[400], fontSize: 13),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _EmptyGoals(
                          onAdd: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['type'] == 'Event' && data['eventDate'] != null) {
                            final date = DateTime.tryParse(data['eventDate']);
                            if (date != null && date.isBefore(DateTime.now())) {
                              DatabaseService(uid: user.uid).deleteGoal(doc.id);
                              return const SizedBox.shrink();
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GoalIndicator(data, context),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationsLeiste(currentPage: 0),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION HEADER ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Alle →',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kBlue,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── GOALS HEADER (with + button) ────────────────────────────────────────────

class _GoalsHeader extends StatelessWidget {
  final VoidCallback onManage;
  final VoidCallback onAdd;

  const _GoalsHeader({required this.onManage, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onManage,
          child: const Text(
            'MEINE ZIELE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onManage,
          child: const Text(
            'Alle →',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kBlue,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kBlue, kGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2228)),
        ),
        child: Column(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            const Text(
              'Noch kein Ziel gesetzt',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe + um dein erstes Ziel zu erstellen',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
