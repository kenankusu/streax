import 'package:flutter/material.dart';
import 'package:streax/Services/auth.dart';
import 'package:streax/Services/database.dart';

// Account löschen

class DeleteAccountDialog {
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

  static Future<void> _deleteAccount(
    BuildContext context,
    String uid,
    Function(bool) setDeleting,
  ) async {
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
        _showErrorDialog(
          context,
          'Beim Löschen des Accounts ist ein Fehler aufgetreten.',
        );
      }
    } catch (e) {
      setDeleting(false);
      _showErrorDialog(context, 'Unerwarteter Fehler: $e');
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
