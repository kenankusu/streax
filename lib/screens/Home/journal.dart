import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Journal extends StatelessWidget {
  const Journal({super.key});

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
          return const Center(child: CircularProgressIndicator());
        }

        // Mappe Einträge nach Datum
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (idx) {
            DateTime day = weekStart.add(Duration(days: idx));
            String tag = wochentage[idx];
            String dateKey = "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
            final eintrag = eintraege[dateKey];
            bool hasEntry = eintrag != null && eintrag['icon'] != null && eintrag['icon'] != '';

            Color borderColor = hasEntry
                ? Theme.of(context).colorScheme.primary
                : const Color.fromARGB(255, 75, 73, 73);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Column(
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      color: idx == today ? Theme.of(context).colorScheme.primary : Colors.white,
                      fontSize: 16,
                      fontWeight: idx == today ? FontWeight.bold : FontWeight.normal,
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
                    child: Container(
                      width: 50,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: borderColor,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: hasEntry
                            ? Image.asset(
                                eintrag['icon'],
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

