import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:streax/screens/Home/Goals/goals.dart'; 
import 'package:streax/models/user.dart';
import 'head.dart';
import 'journal.dart';
import '../../shared/widgets/navigation_bar.dart';
import '../Journal/calendar.dart';
import '../../services/database.dart';
import 'Goals/progress_indicators.dart';
import '../Friends/feed.dart';
import '../../shared/constants/sport_utils.dart';

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
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const Feed()),
                            ),
                            child: Row(
                              children: [
                                Text('Feed', style: Theme.of(context).textTheme.headlineMedium),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          HomeFeedPreview(userId: user.uid),
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
                              child: GoalIndicator(data, context),
                            );
                          }).toList(),
                        );
                      },
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
                        HomeFeedPreview(userId: user.uid),
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
        const Positioned(
          bottom: 0, left: 0, right: 0,
          child: NavigationsLeiste(currentPage: 0),
        ),
        ],
      ),
    );
  }
}

class HomeFeedPreview extends StatefulWidget {
  final String userId;
  const HomeFeedPreview({super.key, required this.userId});

  @override
  State<HomeFeedPreview> createState() => _HomeFeedPreviewState();
}

class _HomeFeedPreviewState extends State<HomeFeedPreview> {
  Stream<List<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _stream = DatabaseService(uid: widget.userId).friendActivities;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final activities = (snapshot.data ?? []).take(3).toList();

        if (activities.isEmpty) {
          return Text(
            'Keine neuen Aktivitäten',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          );
        }

        return Column(
          children: activities
              .map((a) => CompactActivityCard(activity: a))
              .toList(),
        );
      },
    );
  }
}

class CompactActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const CompactActivityCard({super.key, required this.activity});

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference((timestamp as Timestamp).toDate());
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'jetzt';
  }

  Widget _activityIcon(String category) => sportIconWidget(category, size: 28);

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (activity['photoUrl'] ?? '').toString().isNotEmpty;
    final likeCount = activity['likeCount'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[700],
            backgroundImage: (activity['userProfileImage'] ?? '').toString().isNotEmpty
                ? NetworkImage(activity['userProfileImage'])
                : null,
            child: (activity['userProfileImage'] ?? '').toString().isEmpty
                ? const Icon(Icons.person, size: 20, color: Colors.white54)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['userName'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(activity['title'] ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    Text(' · ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(_timeAgo(activity['timestamp']), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                if (likeCount > 0)
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 11, color: Colors.red.withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Text('$likeCount', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                activity['photoUrl'],
                width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          else
            _activityIcon(activity['category'] ?? ''),
        ],
      ),
    );
  }
}
