import 'package:flutter/material.dart';
import 'widgets/fortschrittsbalken.dart';

class startseite extends StatelessWidget {
  final int streakWert = 13;
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
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Streak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hallo,\nJakob!",
                      style: TextStyle(color: Colors.white, fontSize: 26)),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: streakWert / 30,
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                        backgroundColor: Colors.grey[800],
                      ),
                      Text('$streakWert', style: TextStyle(color: Colors.white)),
                    ],
                  )
                ],
              ),
              SizedBox(height: 16),
              Text(
                "„Zum Erfolg gibt es keinen Lift.\nMan muss die Treppe benutzen“",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 24),
              // Wochentage
              Text("Journal", style: TextStyle(color: Colors.white, fontSize: 18)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tage.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String day = entry.value;
                  bool isToday = idx == aktuellerTagIndex;

                  return GestureDetector(
                    onTap: () {
                      // TODO: Öffne Journal für den Tag
                    },
                    child: Container(
                      width: 40,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.yellow : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(day,
                                style: TextStyle(
                                  color: isToday ? Colors.black : Colors.white,
                                )),
                            SizedBox(height: 4),
                            Icon(Icons.fitness_center,
                                size: 16,
                                color: isToday ? Colors.black : Colors.white),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Feed
              Text("Feed", style: TextStyle(color: Colors.white, fontSize: 18)),
              SizedBox(height: 8),
              Text("keine neuen Aktivitäten",
                  style: TextStyle(color: Colors.grey[500])),
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
              Fortschrittsbalken(label: 'streax programmieren', fortschritt: 0.7),
              Fortschrittsbalken(label: '80kg bis Oktober', fortschritt: 0.2)
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
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 6)]),
              child: Icon(Icons.add, color: Colors.white, size: 30),
            ),
            Icon(Icons.menu_book, color: Colors.white),
            Icon(Icons.settings, color: Colors.white),
          ],
        ),
      ),
    );
  }
}