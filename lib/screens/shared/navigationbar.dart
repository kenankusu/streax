import 'package:flutter/material.dart';
import 'addActivity.dart';
import '../Journal/calendar.dart';
import '../Profile/profile.dart';
import '../Friends/feed.dart';

/// Hauptnavigationsleiste mit schwebendem Plus-Button
/// Ermöglicht Navigation zwischen den fünf Hauptbereichen der App
class NavigationsLeiste extends StatelessWidget {
  final int currentPage;

  const NavigationsLeiste({super.key, this.currentPage = 0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Hauptnavigationsleiste mit abgerundeten Ecken
        Container(
          height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BottomNavigationBar(
              backgroundColor: colorScheme.surfaceContainer,
              selectedItemColor: Colors.white70,
              unselectedItemColor: Colors.white70,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentPage,
              iconSize: 26,
              elevation: 0,
              onTap: (index) => _handleNavigation(context, index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  activeIcon: Icon(Icons.group),
                  label: 'Freunde',
                ),
                BottomNavigationBarItem(
                  // Leerer Platz für den schwebenden Plus-Button
                  icon: SizedBox(height: 26),
                  label: 'Hinzufügen',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month),
                  label: 'Kalender',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
        // Schwebender Plus-Button mit Gradient-Design
        _buildFloatingActionButton(context),
      ],
    );
  }

  /// Behandelt die Navigation zwischen den verschiedenen Bereichen
  void _handleNavigation(BuildContext context, int index) {
    // Verhindert unnötige Navigation zur gleichen Seite
    if (index == currentPage) return;

    switch (index) {
      case 0:
        // Navigation zur Startseite - alle anderen Seiten schließen
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        // Navigation zum Freunde-Feed
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const Feed()),
        );
        break;
      case 2:
        // Plus-Button öffnet Aktivität-Modal
        _showAddActivityModal(context);
        break;
      case 3:
        // Navigation zum Kalender
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const calendar()),
        );
        break;
      case 4:
        // Navigation zum Profil
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const Profile()),
        );
        break;
    }
  }

  /// Erstellt den schwebenden Plus-Button mit Gradient-Design
  Widget _buildFloatingActionButton(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => _showAddActivityModal(context),
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              // Gradient von Blau zu Grün
              gradient: const LinearGradient(
                colors: [Color(0xFF1C499E), Color(0xFFB1D43A)],
                stops: [0.35, 1.0],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  /// Zeigt das Modal zum Hinzufügen einer neuen Aktivität
  void _showAddActivityModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AktivitaetHinzufuegen(
        onSaved: () {
          // Callback für erfolgreiche Aktivität-Speicherung
          // Navigation wird vom Modal selbst gehandhabt
        },
      ),
    );
  }
}
