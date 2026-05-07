import 'package:flutter/material.dart';
import 'package:streax/Services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Dialog für Passwort-Reset Funktionalität
/// Ermöglicht Benutzern das Zurücksetzen ihres Passworts über Email-Versand
/// Wird vom Login-Screen aufgerufen wenn User das Passwort vergessen hat
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  // Controller für Email-Eingabefeld
  final TextEditingController _emailController = TextEditingController();
  
  // Firebase Auth Service für Email-Versand
  final AuthService _auth = AuthService();
  
  // Loading-State während Email-Versand
  bool _isLoading = false;
  
  // Feedback-Nachricht für User (Erfolg oder Fehler)
  String _message = '';
  
  // Bestimmt ob Email erfolgreich versendet wurde (für UI-Anpassung)
  bool _isSuccess = false;

  @override
  void dispose() {
    // Memory Leak vermeiden - Controller aufräumen
    _emailController.dispose();
    super.dispose();
  }

  /// Sendet Passwort-Reset-Email über Firebase Auth
  /// Validiert Email-Eingabe und behandelt alle möglichen Fehlerszenarien
  Future<void> _sendResetEmail() async {
    // Basis-Validierung: Email-Feld darf nicht leer sein
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = 'Bitte Email-Adresse eingeben';
        _isSuccess = false;
      });
      return;
    }

    // Loading-State aktivieren und vorherige Nachrichten löschen
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // Firebase Auth Service aufrufen für Email-Versand
      bool success = await _auth.sendPasswordResetEmail(_emailController.text.trim());
      
      if (success) {
        // Erfolg - User informieren mit Bestätigung der Email-Adresse
        setState(() {
          _message = 'Email zum Zurücksetzen wurde an ${_emailController.text.trim()} gesendet.\n\nBitte überprüfe dein Postfach und folge den Anweisungen.';
          _isSuccess = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      // Spezifische Firebase-Fehler abfangen und benutzerfreundlich darstellen
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _message = 'Kein Account mit dieser Email-Adresse gefunden';
            break;
          case 'invalid-email':
            _message = 'Ungültige Email-Adresse';
            break;
          case 'too-many-requests':
            _message = 'Zu viele Anfragen. Bitte versuche es später erneut';
            break;
          default:
            _message = 'Fehler beim Senden der Email: ${e.message}';
        }
        _isSuccess = false;
      });
    } catch (e) {
      // Unerwartete Fehler abfangen (Netzwerk, etc.)
      setState(() {
        _message = 'Ein unerwarteter Fehler ist aufgetreten';
        _isSuccess = false;
      });
    } finally {
      // Loading-State immer deaktivieren (auch bei Fehlern)
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Konsistentes Design mit App-Theme
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      
      // Dialog-Titel
      title: Text(
        'Passwort zurücksetzen',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      
      // Haupt-Inhalt des Dialogs
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email-Eingabe nur anzeigen wenn noch nicht erfolgreich versendet
            if (!_isSuccess) ...[
              Text(
                'Ein Link zum Zurücksetzen deines Passworts wird an folgende Email-Adresse verschickt:',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              SizedBox(height: 20),
              
              // Email-Eingabefeld mit App-Design
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email-Adresse',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey[400],
                  ),
                ),
                // Eingabe während Loading deaktivieren
                enabled: !_isLoading,
              ),
              SizedBox(height: 20),
            ],
            
            // Feedback-Nachricht anzeigen (Erfolg oder Fehler)
            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      color: _isSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      
      // Dialog-Aktionen (Buttons)
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            _isSuccess ? 'Schließen' : 'Abbrechen',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        
        // Email senden Button (nur wenn noch nicht erfolgreich)
        if (!_isSuccess)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              // Button während Loading deaktivieren
              onPressed: _isLoading ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading
                  // Loading-Spinner während Verarbeitung
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Email senden',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}