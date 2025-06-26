import 'package:flutter/material.dart';
import 'widgets/fortschrittsbalken.dart';
import 'widgets/kopfzeile.dart';
import 'widgets/journal.dart';
import 'widgets/navigationsleiste.dart';
import 'kalender.dart';

class startseite extends StatefulWidget {
  const startseite({super.key});

  @override
  State<startseite> createState() => _startseiteState();
}

class _startseiteState extends State<startseite> {
  final int streakWert = 25;
  final List<String> tage = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
  final int aktuellerTagIndex = 3; // Donnerstag
  int _currentPage = 0;

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

  Widget _buildPage() {
    switch (_currentPage) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildFriendsPage();
      case 3:
        return kalender();
      case 4:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kopfzeile(username: "username", streakWert: streakWert),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _currentPage = 3; // Wechsel zum Kalender-Tab
              });
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
    );
  }

  Widget _buildFriendsPage() {
    return Center(
      child: Text(
        'Freunde',
        style: TextStyle(color: Colors.white, fontSize: 30),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Center(
      child: Text(
        'Einstellungen',
        style: TextStyle(color: Colors.white, fontSize: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: _buildPage(),
      ),
      bottomNavigationBar: NavigationsLeiste(
        currentPage: _currentPage,
        onPageChanged: (index) {
          if (index == 2) {
            // Wenn der Plus-Button gedrückt wurde
            showJournalContextMenu(context, () {
              setState(() {}); // UI aktualisieren
            });
          } else {
            setState(() {
              _currentPage = index;
            });
          }
        },
      ),
    );
  }
}
