import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/services/database.dart';
import '../../shared/utils/snackbar.dart';
import '../../shared/constants/sport_utils.dart';

// Sportart auswählen

class SportSelectionDialog {
  static List<String> get availableSports => kAllSports;

  static void show(
    BuildContext context,
    String uid,
    Map<String, dynamic> currentData,
  ) {
    List<String> selectedSports = currentData['sports'] != null
        ? List<String>.from(currentData['sports'])
        : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Sportarten auswählen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ...availableSports.map(
                    (sport) => CheckboxListTile(
                      title: Text(
                        sport,
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: selectedSports.contains(sport),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedSports.add(sport);
                          } else {
                            selectedSports.remove(sport);
                          }
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await DatabaseService(
                    uid: uid,
                  ).updateUserSports(selectedSports);
                  Navigator.pop(context);
                  SnackBarUtils.showSuccess(
                    context,
                    'Sportarten erfolgreich gespeichert!',
                  );
                } catch (e) {
                  SnackBarUtils.showError(context, 'Fehler beim Speichern: $e');
                }
              },
              child: Text(
                'Speichern',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sport icons widget

class SportIcons extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String uid;

  const SportIcons({super.key, required this.userData, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // "Deine Sportarten" Label
        Text(
          "Deine Sportarten:",
          style: Theme.of(
            context,
          ).textTheme.bodySmall
        ),
        const SizedBox(height: 8),
        // Horizontale scrollbare Liste
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              // Ausgewählte Sportarten
              if (userData['sports'] != null &&
                  (userData['sports'] as List).isNotEmpty)
                ...((userData['sports'] as List<dynamic>)
                    .cast<String>()
                    .map((sport) => SportIcon(sportName: sport))
                    .toList()),
              // Plus-Button
              GestureDetector(
                onTap: () => SportSelectionDialog.show(context, uid, userData),
                child: const AddSportIcon(),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// Individuelle Sport Icons

class SportIcon extends StatelessWidget {
  final String sportName;

  const SportIcon({super.key, required this.sportName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onLongPress: () => _showRemoveSportDialog(context, sportName),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161920),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF252830)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sportEmoji(sportName), style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(
                sportName.length > 8 ? '${sportName.substring(0, 7)}.' : sportName,
                style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  letterSpacing: 0.4, color: Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveSportDialog(BuildContext context, String sportName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sportart entfernen'),
        content: Text(
          'Möchten Sie "$sportName" aus Ihren Sportarten entfernen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeSport(context, sportName);
            },
            child: Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSport(BuildContext context, String sportName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        List<String> currentSports =
            (userDoc.data()?['sports'] as List<dynamic>?)?.cast<String>() ?? [];

        currentSports.remove(sportName);

        await DatabaseService(uid: user.uid).updateUserSports(currentSports);

        SnackBarUtils.showSuccess(context, '$sportName wurde entfernt');
      }
    }
  }
}

// Sport Icon hinzufügen (muss noch mit Emojis oder Icons erweitert werden)

class AddSportIcon extends StatelessWidget {
  const AddSportIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSurface,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sportarten',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
