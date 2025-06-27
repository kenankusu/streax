import 'package:flutter/material.dart';
import '../Shared/addActivity.dart';
import '../Journal/calendar.dart';
import '../Profile/profile.dart';

class NavigationsLeiste extends StatelessWidget {
  final int currentPage;

  const NavigationsLeiste({
    super.key,
    this.currentPage = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Hauptnavigationsleiste
        Container(
          height: 65,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BottomNavigationBar(
              backgroundColor: colorScheme.surfaceContainer,
              selectedItemColor: colorScheme.onSurface,
              unselectedItemColor: Colors.white,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentPage,
              iconSize: 26,
              elevation: 0, // Entfernt zusätzliche Schatten
              onTap: (index) {
                switch (index) {
                  case 0:
                    if (currentPage != 0) {
                      // Navigation zurück zur Startseite
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                    break;
                  case 1:
                    // Freunde-Funktion noch nicht implementiert
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Freunde-Seite kommt bald!')),
                    );
                    break;
                  case 2:
                    // Plus-Button öffnet Aktivität-hinzufügen-Fenster
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AktivitaetHinzufuegen(),
                    );
                    break;
                  case 3:
                    if (currentPage != 3) {
                      // Navigation zum Kalender
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => kalender()),
                      );
                    }
                    break;
                  case 4:
                    if (currentPage != 4) {
                      // Navigation zum Profil
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Profil()),
                      );
                    }
                    break;
                }
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                  label: 'Freunde',
                ),
                BottomNavigationBarItem(
                  // Leerer Platz für den schwebenden Plus-Button - reduzierte Höhe
                  icon: SizedBox(height: 26),
                  label: 'Hinzufügen',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Kalender',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Einstellungen',
                ),
              ],
            ),
          ),
        ),
        // Plus-Button schwebt über der Navigationsleiste
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                // Aktivität-hinzufügen-Fenster öffnen
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AktivitaetHinzufuegen(),
                );
              },
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  // Gradient für den Plus-Button
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1C499E),
                      Color(0xFFB1D43A),
                    ],
                    stops: [0.35, 1.0],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}