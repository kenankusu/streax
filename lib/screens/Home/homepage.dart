import 'package:flutter/material.dart';
import 'package:streax/screens/Home/Goals/goals.dart'; 
import 'head.dart';
import 'journal.dart';
import '../Shared/navigationbar.dart';
import '../Journal/calendar.dart';

class startseite extends StatelessWidget {
  final int streakWert = 25;
  final int aktuellerTagIndex = 3;

  const startseite({super.key}); // Donnerstag


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // Theme Hintergrundfarbe
      body: Stack( // Stack verwenden für überlappende Widgets
        children: [
          // Hauptinhalt - scrollbar
          SafeArea(
            bottom: false, // bottom: false für echte floating bar
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Begrüßung und Streak-Wert
                    Kopfzeile(streakWert: streakWert),
                    SizedBox(height: 40), // Abstand zwischen Kopfzeile und Kalender

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
                      SizedBox(height: 30), // Abstand zwischen Überschrift und Kalender
                      //tatsächliches Kalender Widget
                      Journal(),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]), // Textfarbe für "keine neuen Aktivitäten"
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    //Überschrift für Ziele-Bereich - JETZT KLICKBAR
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: GestureDetector(
                        onTap: () {
                          // Ziele-Popup öffnen
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ZielePopup(),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              "Deine Ziele",
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right, color: Colors.white, size: 32), // Pfeil-Icon hinzugefügt
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Schwebende Navigation
        ],
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 0),
    );
  }
}
