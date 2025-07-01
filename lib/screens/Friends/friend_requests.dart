import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';
import 'friend_actions.dart';

class FriendRequestsTab extends StatelessWidget {
  final String uid;

  const FriendRequestsTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService(uid: uid).incomingFriendRequests,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Keine Anfragen',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Hier erscheinen eingehende Freundschaftsanfragen',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestData = requests[index].data() as Map<String, dynamic>;
            final senderId = requestData['senderId'];

            return FutureBuilder<Map<String, dynamic>?>(
              future: DatabaseService(uid: uid).getFriendData(senderId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text(
                        'Lade Anfrage...',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  );
                }

                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return SizedBox.shrink();
                }

                final userData = userSnapshot.data!;
                return RequestCard(user: userData, currentUserId: uid);
              },
            );
          },
        );
      },
    );
  }
}

// Anfragekarte
class RequestCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String currentUserId;

  const RequestCard({
    super.key,
    required this.user,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              backgroundImage: user['profileImageUrl'] != null &&
                      user['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(user['profileImageUrl'])
                  : null,
              child: user['profileImageUrl'] == null ||
                      user['profileImageUrl'].toString().isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600])
                  : null,
            ),

            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user['firstName'] ?? 'Unbekannt'} ${user['lastName'] ?? ''}'.trim(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user['username'] ?? 'unbekannt'}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  if ((user['streak'] ?? 0) > 0)
                    Text(
                      '🔥 ${user['streak']} Tag${user['streak'] == 1 ? '' : 'e'} Streak',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Aktions-Buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => FriendActions.acceptFriendRequest(
                    context,
                    user,
                    currentUserId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(80, 32),
                  ),
                  child: Text('✓', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => FriendActions.declineFriendRequest(
                    context,
                    user,
                    currentUserId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(80, 32),
                  ),
                  child: Text('✗', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}