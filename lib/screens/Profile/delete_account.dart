import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/Services/auth.dart';
import 'package:streax/Services/database.dart';

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
              _showPasswordConfirmation(context, uid, setDeleting);
            },
            child: Text('Weiter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Passwort-Bestätigung für Re-Authentifizierung (Firebase-Pflicht)
  static void _showPasswordConfirmation(
    BuildContext context,
    String uid,
    Function(bool) setDeleting,
  ) {
    final passwordController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: const Text(
            'Passwort bestätigen',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bitte gib dein Passwort ein um die Löschung zu bestätigen.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Passwort',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text;
                if (password.isEmpty) return;
                Navigator.pop(ctx);
                await _deleteAccount(context, uid, password, setDeleting);
              },
              child: const Text(
                'Endgültig löschen',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _deleteAccount(
    BuildContext context,
    String uid,
    String password,
    Function(bool) setDeleting,
  ) async {
    setDeleting(true);

    try {
      final auth = AuthService();
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null || firebaseUser.email == null) {
        setDeleting(false);
        if (context.mounted) _showErrorDialog(context, 'Kein Benutzer angemeldet.');
        return;
      }

      // Re-Authentifizierung (Firebase-Pflicht vor Account-Löschung)
      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: password,
      );
      await firebaseUser.reauthenticateWithCredential(credential);

      // 1. Firestore-Daten löschen (Session ist nach Re-Auth frisch & aktiv)
      await DatabaseService(uid: uid).deleteAllUserData();

      // 2. Firebase Auth Account löschen
      await auth.deleteAccount();

    } on FirebaseAuthException catch (e) {
      setDeleting(false);
      if (!context.mounted) return;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showErrorDialog(context, 'Falsches Passwort. Bitte versuche es erneut.');
      } else {
        _showErrorDialog(context, 'Fehler: ${e.message}');
      }
    } catch (e) {
      setDeleting(false);
      if (context.mounted) _showErrorDialog(context, 'Unerwarteter Fehler: $e');
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
