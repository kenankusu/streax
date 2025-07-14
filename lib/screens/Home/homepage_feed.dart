import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streax/services/database.dart';

class HomepageFeed extends StatelessWidget {
  final String userUid;
  const HomepageFeed({required this.userUid, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService(uid: userUid).friendActivities,
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
              color: Theme.of(context).colorScheme.surfaceContainer,
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
                      color: Colors.white, fontWeight: FontWeight.bold),
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
    );
  }
}