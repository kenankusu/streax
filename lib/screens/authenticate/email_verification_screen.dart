import 'package:flutter/material.dart';
import 'package:streax/Screens/splashscreen.dart';
import 'package:streax/Services/auth.dart';
import 'dart:async';

/// Screen für die Email-Verifizierung nach der Registrierung
/// Überprüft automatisch alle 3 Sekunden den Verifizierungsstatus
/// und leitet bei erfolgreicher Verifizierung zur App weiter
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _auth = AuthService();
  Timer? _timer;
  bool _isCheckingVerification = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startPeriodicVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Timer bei Widget-Zerstörung stoppen
    super.dispose();
  }

  /// Startet periodische Überprüfung alle 3 Sekunden
  void _startPeriodicVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  /// Prüft Email-Verifizierungsstatus und leitet bei Erfolg weiter
  Future<void> _checkEmailVerification() async {
    // Verhindert Doppelausführung und unnötige Checks nach Verifizierung
    if (_isCheckingVerification || _isVerified) return;
    
    setState(() {
      _isCheckingVerification = true;
    });

    bool isVerified = await _auth.checkEmailVerification();
    
    setState(() {
      _isCheckingVerification = false;
    });

    // Bei erfolgreicher Verifizierung Weiterleitung einleiten
    if (isVerified && !_isVerified) {
      setState(() {
        _isVerified = true;
      });
      
      _timer?.cancel(); // Timer stoppen da nicht mehr benötigt
      
      // Benutzer über Erfolg informieren
      // mounted-Check vor BuildContext-Verwendung nach async
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email verifiziert! Du wirst zur App weitergeleitet..."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );

        // Kurze Pause für User-Feedback, dann Navigation
        await Future.delayed(const Duration(seconds: 2));

        // mounted-Check nach weiterem async Gap
        if (mounted) {
          // Kompletten Navigation-Stack zurücksetzen und zum Wrapper
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Wrapper()),
            (route) => false, // Alle vorherigen Routes entfernen
          );
        }
      }
    }
  }

  /// Sendet Verifizierungs-Email erneut mit 60s Cooldown-Mechanismus
  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    bool success = await _auth.resendEmailVerification();
    
    if (success) {
      // 60 Sekunden Cooldown aktivieren
      setState(() {
        _canResendEmail = false;
        _resendCooldown = 60;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifizierungs-Email erneut gesendet'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Countdown-Timer für Button-Aktivierung
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _resendCooldown--;
          });
          
          // Timer beenden wenn Cooldown abgelaufen
          if (_resendCooldown <= 0) {
            setState(() {
              _canResendEmail = true;
            });
            timer.cancel();
          }
        } else {
          timer.cancel(); // Timer beenden wenn Widget nicht mehr existiert
        }
      });
    } else {
      // Fehlermeldung bei Sende-Fehler
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Senden der Email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        backgroundColor: Colors.brown[400],
        title: const Text('Email verifizieren'),
        automaticallyImplyLeading: false, // Zurück-Button entfernen
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon je nach Verifizierungsstatus
            Icon(
              _isVerified ? Icons.check_circle : Icons.mark_email_unread,
              size: 100,
              color: _isVerified ? Colors.green : Colors.brown[600],
            ),
            const SizedBox(height: 32),
            
            // Überschrift dynamisch je nach Status
            Text(
              _isVerified ? 'Email verifiziert!' : 'Email-Adresse verifizieren',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isVerified ? Colors.green : Colors.brown[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Inhalt je nach Verifizierungsstatus
            if (!_isVerified) ...[
              Text(
                'Wir haben eine Verifizierungs-Email an',
                style: TextStyle(fontSize: 16, color: Colors.brown[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'gesendet. Bitte überprüfe dein Postfach und klicke auf den Verifizierungslink.',
                style: TextStyle(fontSize: 16, color: Colors.brown[700]),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              // Verifizierung erfolgreich - Weiterleitungs-Info
              Text(
                'Du wirst automatisch zur App weitergeleitet...',
                style: TextStyle(fontSize: 16, color: Colors.green[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Loading-Indikator während Verifizierungs-Check
            if (_isCheckingVerification && !_isVerified)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[600]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Überprüfe Verifizierung...',
                    style: TextStyle(color: Colors.brown[600]),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Aktions-Buttons nur wenn noch nicht verifiziert
            if (!_isVerified) ...[
              // Email erneut senden Button
              ElevatedButton(
                onPressed: _canResendEmail ? _resendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[400],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  _canResendEmail 
                    ? 'Email erneut senden'
                    : 'Erneut senden in ${_resendCooldown}s',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              
              // Zurück zur Anmeldung Button
              TextButton(
                onPressed: () async {
                  await _auth.signOut(); // Aktuellen User ausloggen
                  
                  // mounted-Check nach async Operation hinzufügen
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => Wrapper()),
                      (route) => false,
                    );
                  }
                },
                child: Text(
                  'Zur Anmeldung zurück',
                  style: TextStyle(
                    color: Colors.brown[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Hilfe-Box für Spam-Ordner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(height: 8),
                    Text(
                      'Tipp: Überprüfe auch deinen Spam-Ordner, falls die Email nicht ankommt.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}