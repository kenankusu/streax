import 'package:flutter/material.dart';
import '../Shared/addActivity.dart';

// Einträge werden nach Datum gespeichert (z.B. "2025-06-28")
Map<String, Map<String, dynamic>> eintraege = {};

class journal extends StatefulWidget {
  const journal({super.key});
  @override
  State<journal> createState() => _JournalState();
}

class _JournalState extends State<journal> {
  final List<String> wochentage = ["MO", "DI", "MI", "DO", "FR", "SA", "SO"];

  @override
  Widget build(BuildContext context) {
    int today = DateTime.now().weekday - 1; // 0=Mo, 6=So
    DateTime monday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (idx) {
        DateTime day = monday.add(Duration(days: idx));
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
              // Tagesbezeichnung über der Box
              Text(
                tag,
                style: TextStyle(
                  color: idx == today ? Theme.of(context).colorScheme.primary : Colors.white,
                  fontSize: 16,
                  fontWeight: idx == today ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              SizedBox(height: 4),
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
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              eintrag['text'] ?? '',
                              style: TextStyle(color: Colors.white70),
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
                        : SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

