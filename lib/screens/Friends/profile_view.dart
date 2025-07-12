import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/screens/friends/friend_actions.dart';

class ProfileView extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header mit Zurück-Button und Freund entfernen
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  // Zurück-Button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  SizedBox(width: 15),
                  
                  Expanded(
                    child: Text(
                      'Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Freund entfernen Button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          FriendActions.removeFriend(context, user, currentUser.uid);
                        }
                      },
                      icon: Icon(Icons.person_remove, color: Colors.red, size: 22),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Profil-Inhalt
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    
                    // Profilbild und Name
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: user['profileImageUrl'] != null &&
                                  user['profileImageUrl'].toString().isNotEmpty
                              ? NetworkImage(user['profileImageUrl'])
                              : null,
                          child: user['profileImageUrl'] == null ||
                                  user['profileImageUrl'].toString().isEmpty
                              ? Icon(Icons.person, color: Colors.grey[600], size: 60)
                              : null,
                        ),
                        
                        SizedBox(height: 16),
                        
                        Text(
                          '${user['firstName'] ?? 'Unbekannt'} ${user['lastName'] ?? ''}'.trim(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 8),
                        
                        Text(
                          '@${user['username'] ?? 'unbekannt'}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Statistiken
                    FutureBuilder<Map<String, dynamic>>(
                      future: _loadUserStats(user['uid']),
                      builder: (context, snapshot) {
                        final stats = snapshot.data ?? {};
                        
                        return Column(
                          children: [
                            // Aktuelle Streak
                            _buildStatCard(
                              icon: Icons.local_fire_department,
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: 'Aktuelle Streak',
                              value: '${user['streak'] ?? 0} Tage',
                              subtitle: user['streak'] == 0 ? 'Noch keine Streak' : 'Weiter so!',
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Höchste Streak
                            _buildStatCard(
                              icon: Icons.emoji_events,
                              iconColor: Colors.amber,
                              title: 'Höchste Streak',
                              value: '${stats['highestStreak'] ?? 0} Tage',
                              subtitle: stats['highestStreak'] == 0 ? 'Noch kein Rekord' : 'Persönlicher Rekord',
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Freunde
                            _buildStatCard(
                              icon: Icons.group,
                              iconColor: Colors.blue,
                              title: 'Freunde',
                              value: '${stats['friendsCount'] ?? 0}',
                              subtitle: stats['friendsCount'] == 1 ? 'Freund' : 'Freunde',
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Aktivitäten diese Woche
                            _buildStatCard(
                              icon: Icons.fitness_center,
                              iconColor: Colors.green,
                              title: 'Diese Woche',
                              value: '${stats['activitiesThisWeek'] ?? 0}',
                              subtitle: stats['activitiesThisWeek'] == 1 ? 'Aktivität' : 'Aktivitäten',
                            ),
                            
                            SizedBox(height: 12),
                            
                            // Gesamte Aktivitäten
                            _buildStatCard(
                              icon: Icons.analytics,
                              iconColor: Colors.purple,
                              title: 'Gesamt',
                              value: '${stats['totalActivities'] ?? 0}',
                              subtitle: 'Aktivitäten insgesamt',
                            ),
                          ],
                        );
                      },
                    ),
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadUserStats(String userId) async {
    // Lädt Benutzerstatistiken aus Firebase (Freunde, Streak, Aktivitäten)
    try {
      // User-Dokument für Freunde-Count und höchste Streak
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final userData = userDoc.data() ?? {};
      
      // Aktivitäten der letzten 7 Tage
      final oneWeekAgo = DateTime.now().subtract(Duration(days: 7));
      final weekActivities = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
          .get();
      
      // Alle Aktivitäten für Gesamtanzahl
      final allActivities = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .get();
      
      return {
        'friendsCount': userData['friends_count'] ?? 0,
        'highestStreak': userData['highest_streak'] ?? userData['streak'] ?? 0,
        'activitiesThisWeek': weekActivities.docs.length,
        'totalActivities': allActivities.docs.length,
      };
    } catch (e) {
      print('Fehler beim Laden der User-Stats: $e');
      return {};
    }
  }
}