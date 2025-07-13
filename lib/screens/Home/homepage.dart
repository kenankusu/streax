import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:streax/screens/home/goals/goals.dart';
import 'package:streax/screens/shared/user.dart';
import 'package:streax/screens/home/head.dart';
import 'package:streax/screens/home/journal.dart';
import 'package:streax/screens/shared/navigationbar.dart';
import 'package:streax/screens/journal/calendar.dart';
import 'package:streax/services/database.dart';
import 'package:streax/screens/home/goals/progress_indicators.dart';
import 'package:streax/screens/Friends/feed.dart';

class Homepage extends StatelessWidget {
  final int streakWert = 25;
  final int aktuellerTagIndex = 3;

  const Homepage({super.key});

  // Helpermethoden für ziele
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
    switch (data['type']) {
      case 'Event':
        final eventDate = DateTime.tryParse(data['eventDate'] ?? '');
        if (eventDate != null) {
          final now = DateTime.now();
          final totalDays = eventDate
              .difference(DateTime.now().subtract(Duration(days: 30)))
              .inDays;
          final remainingDays = eventDate.difference(now).inDays;
          return remainingDays <= 0
              ? 1.0
              : (totalDays - remainingDays) / totalDays;
        }
        return 0.0;
      case 'Gewicht':
        return 0.6;
      case 'Training':
        return 0.4;
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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Hauptinhalt
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                48,
                20,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Begrüßung und Streak-Wert
                  Header(streakValue: streakWert),
                  SizedBox(height: 20),

                  // Kalender
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => calendar(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                "Deine Woche",
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        Journal(),
                      ],
                    ),
                  ),

                  // Feed-Bereich
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Feed(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                "Dein Feed",
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Feed-Aktivitäten des aktuellen Tages
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: DatabaseService(uid: user.uid).friendActivities,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final activities = (snapshot.data ?? []).where((activity) {
                              final ts = activity['timestamp'];
                              if (ts is Timestamp) {
                                final date = ts.toDate();
                                final now = DateTime.now();
                                return date.year == now.year &&
                                    date.month == now.month &&
                                    date.day == now.day;
                              }
                              return false;
                            }).toList();

                            if (activities.isEmpty) {
                              return Text(
                                "Heute noch keine Aktivitäten deiner Freunde vorhanden.",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[500]),
                              );
                            }

                            return Column(
                              children: activities.map((activity) {
                                final ts = activity['timestamp'] as Timestamp;
                                final timeStr =
                                    "${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}";
                                return Card(
                                  color:
                                      Theme.of(context).colorScheme.surfaceContainer,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage:
                                          activity['userProfileImage'] != null &&
                                                  activity['userProfileImage']
                                                      .toString()
                                                      .isNotEmpty
                                              ? NetworkImage(activity['userProfileImage'])
                                              : null,
                                      child: activity['userProfileImage'] == null ||
                                              activity['userProfileImage']
                                                  .toString()
                                                  .isEmpty
                                          ? Icon(Icons.person, color: Colors.grey[600])
                                          : null,
                                    ),
                                    title: Text(
                                      activity['userName'] ?? 'Unbekannt',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      "${activity['title'] ?? 'Aktivität'} • $timeStr",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
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
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // StreamBuilder für Ziele mit fehlerbehandlung
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

                      // Keine Daten oder leere Collection
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Keine Ziele vorhanden',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500]),
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
                            child: ProgressBar(
                              labelText: _getGoalDisplayName(data),
                              progressValue: _calculateProgress(data),
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

          // Navigation Bar am unteren Rand
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationsLeiste(currentPage: 0),
          ),
        ],
      ),
    );
  }
}
