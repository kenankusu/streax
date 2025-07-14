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
import 'package:streax/screens/home/homepage_feed.dart';
import 'package:streax/screens/friends/feed.dart';

class Homepage extends StatelessWidget {
  final int streakWert = 25;
  final int aktuellerTagIndex = 3;

  const Homepage({super.key});

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
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        HomepageFeed(userUid: user.uid),
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

                  // StreamBuilder für Ziele mit Fehlerbehandlung
                  StreamBuilder<QuerySnapshot>(
                    stream: DatabaseService(uid: user.uid).userGoals,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

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

                      final goals = snapshot.data!.docs;

                      return Column(
                        children: goals.map((goal) {
                          final data = goal.data() as Map<String, dynamic>;
                          if (data['type'] == 'Event' && data['eventDate'] != null) {
                            final eventDate = DateTime.tryParse(data['eventDate']);
                            if (eventDate != null && eventDate.isBefore(DateTime.now())) {
                              DatabaseService(uid: user.uid).deleteGoal(goal.id);
                              return Container();
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GoalIndicator(data, context),
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
