import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database.dart';

class FriendActions {
  // Freundschaftsanfrage senden
  static Future<void> sendFriendRequest(
    BuildContext context,
    Map<String, dynamic> user,
    VoidCallback onComplete,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final success = await DatabaseService(
      uid: currentUser.uid,
    ).sendFriendRequest(user['uid']);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Freundschaftsanfrage an ${user['firstName']} gesendet!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      onComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Freundschaftsanfrage konnte nicht gesendet werden'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Freundschaftsanfrage akzeptieren
  static Future<void> acceptFriendRequest(
    BuildContext context,
    Map<String, dynamic> user,
    String currentUserId,
  ) async {
    final success = await DatabaseService(
      uid: currentUserId,
    ).acceptFriendRequest(user['uid']);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['firstName']} ist jetzt dein Freund! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Freundschaftsanfrage ablehnen
  static Future<void> declineFriendRequest(
    BuildContext context,
    Map<String, dynamic> user,
    String currentUserId,
  ) async {
    final success = await DatabaseService(
      uid: currentUserId,
    ).declineFriendRequest(user['uid']);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Freundschaftsanfrage abgelehnt'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Freund entfernen
  static Future<void> removeFriend(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          'Freundschaft entfernen',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Möchtest du ${user['firstName']} wirklich als Freund entfernen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final success = await DatabaseService(
          uid: currentUser.uid,
        ).removeFriend(user['uid']);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user['firstName']} wurde entfernt'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  // Anfragen-Dialog anzeigen
  static void showRequestDialog(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          'Freundschaftsanfrage',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  user['profileImageUrl'] != null &&
                      user['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(user['profileImageUrl'])
                  : null,
              child:
                  user['profileImageUrl'] == null ||
                      user['profileImageUrl'].toString().isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600])
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              '${user['firstName']} ${user['lastName']}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '@${user['username']}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            Text(
              'möchte dein Freund werden',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                declineFriendRequest(context, user, currentUser.uid);
              }
            },
            child: Text('Ablehnen', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                acceptFriendRequest(context, user, currentUser.uid);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Akzeptieren'),
          ),
        ],
      ),
    );
  }
}

// Action Button basierend auf Status
class ActionButton extends StatelessWidget {
  final Map<String, dynamic> user;
  final String status;
  final VoidCallback onActionComplete;

  const ActionButton({
    super.key,
    required this.user,
    required this.status,
    required this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case 'friends':
        return ElevatedButton.icon(
          onPressed: () => ProfileDialog.show(context, user, status),
          icon: Icon(Icons.visibility, size: 16),
          label: Text('Profil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainer,
            foregroundColor: Colors.white,
          ),
        );

      case 'request_sent':
        return ElevatedButton.icon(
          onPressed: null,
          icon: Icon(Icons.schedule, size: 16),
          label: Text('Gesendet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.withOpacity(0.3),
            foregroundColor: Colors.orange,
          ),
        );

      case 'request_received':
        return ElevatedButton.icon(
          onPressed: () => FriendActions.showRequestDialog(context, user),
          icon: Icon(Icons.notification_important, size: 16),
          label: Text('Antworten'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary.withOpacity(0.3),
            foregroundColor: colorScheme.primary,
          ),
        );

      default:
        return ElevatedButton.icon(
          onPressed: () =>
              FriendActions.sendFriendRequest(context, user, onActionComplete),
          icon: Icon(Icons.person_add, size: 16),
          label: Text('Hinzufügen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        );
    }
  }
}

// Profildialog
class ProfileDialog {
  static void show(
    BuildContext context,
    Map<String, dynamic> user,
    String relationshipStatus,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profilbild
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  user['profileImageUrl'] != null &&
                      user['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(user['profileImageUrl'])
                  : null,
              child:
                  user['profileImageUrl'] == null ||
                      user['profileImageUrl'].toString().isEmpty
                  ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                  : null,
            ),

            SizedBox(height: 16),

            // Name
            Text(
              '${user['firstName']} ${user['lastName']}'.trim(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Username
            Text(
              '@${user['username']}',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),

            SizedBox(height: 12),

            // Beziehungsstatus
            if (relationshipStatus == 'friends')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ Freunde',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            SizedBox(height: 12),

            // Streak Info
            if ((user['streak'] ?? 0) > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔥 ${user['streak'] ?? 0} Tag${(user['streak'] ?? 0) == 1 ? '' : 'e'} Streak',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }
}
