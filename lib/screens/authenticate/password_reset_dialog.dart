import 'package:flutter/material.dart';
import 'package:streax/Services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = 'Bitte Email-Adresse eingeben';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      bool success = await _auth.sendPasswordResetEmail(_emailController.text.trim());
      if (success) {
        setState(() {
          _message = 'Email zum Zurücksetzen wurde an ${_emailController.text.trim()} gesendet.\n\nBitte überprüfe dein Postfach und folge den Anweisungen.';
          _isSuccess = true;
        });
      }
    } on FirebaseAuthException catch (e) {
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
      setState(() {
        _message = 'Ein unerwarteter Fehler ist aufgetreten';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Passwort zurücksetzen',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isSuccess) ...[
              Text(
                'Ein Link zum Zurücksetzen deines Passworts wird an folgende Email-Adresse verschickt:',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              SizedBox(height: 20),
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
                enabled: !_isLoading,
              ),
              SizedBox(height: 20),
            ],
            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            _isSuccess ? 'Schließen' : 'Abbrechen',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
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