import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Widget für die Wochenansicht der Journal-Einträge
class Journal extends StatelessWidget {
  const Journal({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Berechnung der aktuellen Woche (Montag bis Sonntag)
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
          return const Center(child: CircularProgressIndicator());
        }

        // Gruppiert Aktivitäten nach Datum für schnelleren Zugriff
        final Map<String, Map<String, dynamic>> eintraege = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = DateTime.tryParse(data['datum'] ?? '') ?? DateTime(2000);
          final dateKey = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          eintraege[dateKey] = data;
        }

        final wochentage = ["MO", "DI", "MI", "DO", "FR", "SA", "SO"];
        int today = DateTime.now().weekday - 1;

        return Row(
          children: List.generate(7, (idx) {
            DateTime day = weekStart.add(Duration(days: idx));
            String tag = wochentage[idx];
            String dateKey = "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
            final eintrag = eintraege[dateKey];
            bool hasEntry = eintrag != null && eintrag['icon'] != null && eintrag['icon'] != '';
            bool isToday = idx == today;
            bool isFuture = idx > today;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        color: isToday
                            ? Color(0xFF1C499E)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: hasEntry
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color.fromARGB(255, 75, 73, 73),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          eintrag['option'] ?? '',
                                          style: const TextStyle(color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    eintrag['text'] ?? '',
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
                          : null,
                      child: AspectRatio(
                        aspectRatio: 5 / 7,
                        child: isToday
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1C499E), Color(0xFFB1D43A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: hasEntry
                                        ? Image.asset(eintrag['icon'], width: 36, height: 36, fit: BoxFit.contain)
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: isFuture
                                        ? Colors.white54
                                        : Theme.of(context).colorScheme.surfaceContainer,
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: hasEntry
                                      ? Image.asset(eintrag['icon'], width: 36, height: 36, fit: BoxFit.contain)
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
}

class GradientBorder extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderWidth;
  final BorderRadius borderRadius;

  const GradientBorder({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
    this.borderWidth = 4,
    required this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C499E), Color(0xFFB1D43A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius.topLeft.x - borderWidth),
        ),
        child: child,
      ),
    );
  }
}

