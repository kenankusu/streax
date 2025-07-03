import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  
import 'package:provider/provider.dart';
import 'package:streax/Screens/Home/Goals/goals.dart'; 
import 'package:streax/Models/user.dart';
import 'head.dart';
import 'journal.dart';
import '../Shared/navigationbar.dart';
import '../Journal/calendar.dart';
import '../../Services/database.dart';
import 'Goals/progress_indicators.dart';

class homepage extends StatelessWidget {
  final int streakWert = 25;
  final int aktuellerTagIndex = 3;

  const homepage({super.key});

  // Helper-Methods für Goals
  String _getGoalDisplayName(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final name = data['name'] ?? '';
    
    switch (type) {
      case 'Event':
        return name.isNotEmpty ? name : 'Event';
      case 'Gewicht':
        return 'Zielgewicht: ${data['targetWeight']?.toInt() ?? 0} kg';
      case 'Training':
        return 'Training: ${data['targetTrainings']?.toInt() ?? 0}x/Woche';
      case 'Schritte':
        return 'Schritte: ${_formatNumber(data['targetSteps']?.toInt() ?? 0)}/Tag';
      default:
        return 'Unbekanntes Ziel';
    }
  }

  double _calculateProgress(Map<String, dynamic> data) {
    // Hier kannst du später echte Fortschrittsberechnungen implementieren
    // Für jetzt Dummy-Werte
    switch (data['type']) {
      case 'Event':
        final eventDate = DateTime.tryParse(data['eventDate'] ?? '');
        if (eventDate != null) {
          final now = DateTime.now();
          final totalDays = eventDate.difference(DateTime.now().subtract(Duration(days: 30))).inDays;
          final remainingDays = eventDate.difference(now).inDays;
          return remainingDays <= 0 ? 1.0 : (totalDays - remainingDays) / totalDays;
        }
        return 0.0;
      case 'Gewicht':
        return 0.6; // Dummy - hier würdest du echte Gewichtsdaten verwenden
      case 'Training':
        return 0.4; // Dummy - hier würdest du echte Trainingseinheiten verwenden
      case 'Schritte':
        return 0.8; // Dummy - hier würdest du echte Schrittdaten verwenden
      default:
        return 0.0;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context);
    
    if (user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Begrüßung und Streak-Wert
                    Header(streakWert: streakWert),
                    SizedBox(height: 20),

                    // Kalender
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => calendar()));
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
                          SizedBox(height: 30),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

                    // Ziele Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GestureDetector(
                        onTap: () {
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
                            Icon(Icons.chevron_right, color: Colors.white, size: 32),
                          ],
                        ),
                      ),
                    ),

                    // StreamBuilder für Ziele mit besserer Fehlerbehandlung
                    StreamBuilder<QuerySnapshot>(
                      stream: DatabaseService(uid: user.uid).userGoals,
                      builder: (context, snapshot) {
                        // Lade-Zustand
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        // Fehler-Zustand
                        if (snapshot.hasError) {
                          print('Fehler beim Laden der Ziele: ${snapshot.error}');
                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Fehler beim Laden der Ziele',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red[400],
                              ),
                            ),
                          );
                        }
                        
                        // Keine Daten oder leere Collection
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Keine Ziele vorhanden',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          );
                        }
                        
                        // Erfolgreiche Daten
                        final goals = snapshot.data!.docs;
                        
                        return Column(
                          children: goals.map((goal) {
                            final data = goal.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Fortschrittsbalken(
                                label: _getGoalDisplayName(data),
                                fortschritt: _calculateProgress(data),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 0),
    );
  }
}
