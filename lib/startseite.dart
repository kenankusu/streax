import 'package:flutter/material.dart';
import 'widgets/fortschrittsbalken.dart';
import 'widgets/kopfzeile.dart';
import 'widgets/journal.dart';
import 'widgets/navigationsleiste.dart';
import 'kalender.dart';
import 'aktivitaet.dart';
import 'profil.dart';

class startseite extends StatelessWidget {
  final int streakWert = 25;
  final int aktuellerTagIndex = 3;

  const startseite({super.key}); // Donnerstag


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView( // Damit die Seite scrollen kann
          physics: BouncingScrollPhysics(), // Für ein besseres Scroll-Erlebnis
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16), // Oben mehr Platz
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Begrüßung und Streak-Wert
                Kopfzeile(username: "username", streakWert: streakWert),
                SizedBox(height: 40),

                // Kalender
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => kalender()));
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
                    ],
                  ),
                ),


                // Feed
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Feed",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "keine neuen Aktivitäten",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                //Überschrift für Fortschritt-Bereich
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    "Deine Ziele",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),

                //Klasse aus fortschrittsbalken.dart
                Fortschrittsbalken(label: 'streax programmieren',fortschritt: 0.7,),
                Fortschrittsbalken(label: '80kg bis Oktober', fortschritt: 0.2),
                Fortschrittsbalken(label: '10km laufen', fortschritt: 1),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 0),
    );
  }
}
