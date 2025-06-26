import 'package:flutter/material.dart';
import 'widgets/fortschrittsbalken.dart';
import 'widgets/kopfzeile.dart';
import 'widgets/journal.dart';
import 'widgets/navigationsleiste.dart';
import 'kalender.dart';
import 'aktivitaet.dart';

class startseite extends StatelessWidget {
  final int streakWert = 25;
  final List<String> tage = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
  final int aktuellerTagIndex = 3; // Donnerstag

  Color fortschrittFarbe(double fortschritt) {
    if (fortschritt >= 1.0) return Colors.green;
    if (fortschritt > 0.6) return Colors.blue;
    if (fortschritt >= 0.3) return Colors.yellow;
    return Colors.red;
  }

  Widget buildGoalBar(String label, double fortschritt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 10),
              ),
            ),
            Container(
              height: 14,
              width: 300 * fortschritt,
              decoration: BoxDecoration(
                color: fortschrittFarbe(fortschritt),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kopfzeile(username: "username", streakWert: streakWert),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => kalender()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "Deine Woche",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: Colors.white, size: 32),
                  ],
                ),
              ),
              SizedBox(height: 8),
              journal(),
              SizedBox(height: 20),

              // Feed
              Text("Feed", style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 8),
              Text(
                "keine neuen Aktivitäten",
                style: TextStyle(color: Colors.grey[500]),
              ),
              SizedBox(height: 20),

              //Überschrift für Fortschritt-Bereich
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "Deine Ziele",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),

              //Klasse aus fortschrittsbalken.dart
              Fortschrittsbalken(
                label: 'streax programmieren',
                fortschritt: 0.7,
              ),
              Fortschrittsbalken(label: '80kg bis Oktober', fortschritt: 0.2),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 0),
    );
  }
}