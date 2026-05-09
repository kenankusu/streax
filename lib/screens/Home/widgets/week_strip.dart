import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streax/shared/constants/theme_constants.dart';
import 'package:streax/shared/constants/sport_utils.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('activities')
          .where('datum', isGreaterThanOrEqualTo: weekStart.toIso8601String())
          .where('datum', isLessThanOrEqualTo: weekEnd.toIso8601String())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final Map<String, Map<String, dynamic>> eintraege = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = DateTime.tryParse(data['datum'] ?? '') ?? DateTime(2000);
          final key =
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          eintraege[key] = data;
        }

        final labels = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
        final today = DateTime.now().weekday - 1;

        return Row(
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            final key =
                '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final entry = eintraege[key];
            final hasEntry = entry != null && (entry['option'] ?? '').toString().isNotEmpty;
            final isToday = i == today;
            final isFuture = i > today;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Column(
                  children: [
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isToday ? kBlue : const Color(0xFF3A4050),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: hasEntry ? () => _showDayDialog(context, entry) : null,
                      child: AspectRatio(
                        aspectRatio: 5 / 7,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFF0B2233)
                                : hasEntry
                                    ? const Color(0xFF0B1E14)
                                    : kCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isToday
                                  ? kBlue
                                  : hasEntry
                                      ? kGreen.withValues(alpha: 0.35)
                                      : isFuture
                                          ? const Color(0xFF1F2228).withValues(alpha: 0.5)
                                          : const Color(0xFF1F2228),
                              width: isToday || hasEntry ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: hasEntry
                                ? Text(
                                    sportEmoji(entry['option'] ?? ''),
                                    style: const TextStyle(fontSize: 20),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _showDayDialog(BuildContext context, Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          entry['option'] ?? '',
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          entry['text'] ?? '',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}

int loggedWeekydaysCount(Map<String, Map<String, dynamic>> eintraege) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final weekStart = DateTime(monday.year, monday.month, monday.day);
  int count = 0;
  for (int i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final entry = eintraege[key];
    if (entry != null &&
        (entry['icon'] ?? '').toString().isNotEmpty &&
        entry['icon'] != 'assets/icons/journal/rest.png') {
      count++;
    }
  }
  return count;
}

int getLoggedTrainingDaysThisWeek(Map<String, Map<String, dynamic>> eintraege) =>
    loggedWeekydaysCount(eintraege);
