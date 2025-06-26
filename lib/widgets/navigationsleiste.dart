import 'package:flutter/material.dart';
import '../startseite.dart';
import 'journal.dart';
import '../kalender.dart';
import '../aktivitaet.dart';

class NavigationsLeiste extends StatelessWidget {
  final int currentPage;

  const NavigationsLeiste({
    Key? key,
    this.currentPage = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Hauptnavigationsleiste
        Container(
          height: 60,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: Colors.white,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentPage,
              iconSize: 30,
              onTap: (index) {
                switch (index) {
                  case 0:
                    if (currentPage != 0) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => startseite()),
                        (route) => false,
                      );
                    }
                    break;
                  case 1:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Freunde-Seite kommt bald!')),
                    );
                    break;
                  case 2:
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AktivitaetHinzufuegen(),
                    );
                    break;
                  case 3:
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => kalender()),
                    );
                    break;
                  case 4:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Einstellungen-Seite kommt bald!')),
                    );
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
                  icon: SizedBox(height: 50), // Platzhalter für den erhöhten Button
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
        // Erhöhter Plus-Button
        Positioned(
          bottom: 35,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AktivitaetHinzufuegen(),
                );
              },
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
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
                  border: Border.all(
                    color: colorScheme.surfaceContainer,
                    width: 5,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}