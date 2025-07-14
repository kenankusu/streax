import 'package:flutter/material.dart';
import 'package:streax/services/auth.dart';
import 'package:streax/services/database.dart';

// Sichere Account Löschung mit doppelter Bestätigung
class DeleteAccountDialog {
  
  // Zeigt erste Bestätigungsebene für Account-Löschung
  static void show(
    BuildContext context,
    String uid,
    Function(bool) setDeleting,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'Account löschen',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bist du sicher, dass du deinen Account unwiderruflich löschen möchtest?\n\nAlle deine Daten, Aktivitäten und dein Fortschritt gehen dabei verloren.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalConfirmation(context, uid, setDeleting);
            },
            child: Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Letzte Chance für den User, die Löschung abzubrechen
  static void _showFinalConfirmation(
    BuildContext context,
    String uid,
    Function(bool) setDeleting,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'Letzte Bestätigung',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Dies ist deine letzte Chance!\n\nWenn du auf "Endgültig löschen" klickst, wird dein Account sofort und unwiderruflich gelöscht.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Doch nicht löschen',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, uid, setDeleting);
            },
            child: Text(
              'Endgültig löschen',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Löscht zuerst Firestore-Daten, dann Firebase Auth Account
  static Future<void> _deleteAccount(
    BuildContext context,
    String uid,
    Function(bool) setDeleting,
  ) async {
    // Loading-State aktivieren
    setDeleting(true);

    try {
      final auth = AuthService();

      // 1. Alle Firestore-Daten löschen
      bool firestoreDeleted = await DatabaseService(
        uid: uid,
      ).deleteAllUserData();

      // 2. Firebase Auth Account löschen
      bool authDeleted = await auth.deleteAccount();

      if (!firestoreDeleted || !authDeleted) {
        setDeleting(false);
        if (context.mounted) {
          _showErrorDialog(
            context,
            'Beim Löschen des Accounts ist ein Fehler aufgetreten.',
          );
        }
      }
    } catch (e) {
      setDeleting(false);
      if (context.mounted) {
        _showErrorDialog(context, 'Unerwarteter Fehler: $e');
      }
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Fehler', style: TextStyle(color: Colors.red)),
        content: Text(message, style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
