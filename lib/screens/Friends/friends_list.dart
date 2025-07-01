import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';
import 'friend_actions.dart';

class FriendsListTab extends StatelessWidget {
  final String uid;

  const FriendsListTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService(uid: uid).userFriends,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Noch keine Freunde',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Finde Freunde über die Suche',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        final friends = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendData = friends[index].data() as Map<String, dynamic>;
            final friendId = friendData['userId'];

            return FutureBuilder<Map<String, dynamic>?>(
              future: DatabaseService(uid: uid).getFriendData(friendId),
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
                        'Lade...',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  );
                }

                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return SizedBox.shrink();
                }

                final userData = userSnapshot.data!;
                return FriendCard(user: userData);
              },
            );
          },
        );
      },
    );
  }
}

// Freundeskarte
class FriendCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const FriendCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
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
        title: Text(
          '${user['firstName'] ?? 'Unbekannt'} ${user['lastName'] ?? ''}'.trim(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text('Profil ansehen'),
              onTap: () => ProfileDialog.show(context, user, 'friends'),
            ),
            PopupMenuItem(
              child: Text(
                'Freund entfernen',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => FriendActions.removeFriend(context, user),
            ),
          ],
        ),
      ),
    );
  }
}