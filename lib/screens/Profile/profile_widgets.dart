import 'package:flutter/material.dart';
import 'profile_editing.dart';

// Profil Header (Avatar, Name, Edit/Share buttons)

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String uid;

  const ProfileHeader({super.key, required this.userData, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/profil/profilbild.png'),
        ),
        const SizedBox(height: 16),
        Text(
          '${userData['firstName'] ?? 'Unbekannter'} ${userData['lastName'] ?? 'Name'}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          '@${userData['username'] ?? 'unbekannt'}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                EditProfileDialog.show(context, uid, userData);
              },
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                // Teilen-Funktion (wird noch implementiert)
              },
            ),
          ],
        ),
      ],
    );
  }
}

// Profil Info (Streak, Gewicht, Größe etc.)

class ProfileInfo extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileInfo({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Streax Freunde: ${userData['friends_count'] ?? 0}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Dein längster streak: ${userData['longest_streak'] ?? 0}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Dein Gewicht: ${userData['weight'] != null ? '${userData['weight']} kg' : 'Nicht angegeben'}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Deine Größe: ${userData['height'] != null ? '${userData['height']} cm' : 'Nicht angegeben'}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          "Geschlecht: ${userData['gender'] ?? 'Nicht angegeben'}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
