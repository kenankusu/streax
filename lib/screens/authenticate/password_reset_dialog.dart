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
      backgroundColor: Colors.brown[100],
      title: Text(
        'Passwort zurücksetzen',
        style: TextStyle(color: Colors.brown[800]),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isSuccess) ...[
              Text(
                'Gib deine Email-Adresse ein, um einen Link zum Zurücksetzen deines Passworts zu erhalten:',
                style: TextStyle(color: Colors.brown[700]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email-Adresse',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                enabled: !_isLoading,
              ),
              SizedBox(height: 16),
            ],
            if (_message.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green[800] : Colors.red[800],
                  ),
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
            style: TextStyle(color: Colors.brown[600]),
          ),
        ),
        if (!_isSuccess)
          ElevatedButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[400],
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
                    style: TextStyle(color: Colors.white),
                  ),
          ),
      ],
    );
  }
}