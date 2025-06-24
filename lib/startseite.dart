import 'package:flutter/material.dart';
import 'widgets/fortschrittsbalken.dart';
import 'widgets/kopfzeile.dart';
import 'widgets/journal.dart';
import 'kalender.dart';

class startseite extends StatelessWidget {
<<<<<<< HEAD
  final int streakWert = 13;

  const startseite({super.key});
=======
  final int streakWert = 25;
  final List<String> tage = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
  final int aktuellerTagIndex = 3; // Donnerstag
>>>>>>> cb13f71eb42ab6631e88021dccd82cd0066cb0c5

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
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kopfzeile(username: "username", streakWert: streakWert),
              SizedBox(height: 16),
              Text(
                "Journal",
                style: TextStyle(color: Colors.white, fontSize: 18),
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
              journal(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home, color: Colors.white),
            Icon(Icons.group, color: Colors.white),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 68, 255),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 6)],
              ),
              child: GestureDetector(
                onTap: () async {
                  await showJournalContextMenu(context, () {
                    // setState in startseite aufrufen
                    (context as Element).markNeedsBuild();
                  });
                },
                child: Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
            IconButton(
              icon: Icon(Icons.calendar_month, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => kalender()),
                );
              },
            ),
            Icon(Icons.settings, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
