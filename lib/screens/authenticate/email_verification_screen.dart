import 'package:flutter/material.dart';
import 'package:streax/Screens/splashscreen.dart';
import 'package:streax/Services/auth.dart';
import 'dart:async';


import 'package:streax/screens/Welcome/welcome.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String uid;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.uid,
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

  // Periodische Überprüfung alle 3 Sekunden starten
  void _startPeriodicVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  // Email-Verifizierungsstatus prüfen und bei Erfolg weiterleiten
  Future<void> _checkEmailVerification() async {
    // Doppelte Ausführung verhindern
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
      
      _timer?.cancel(); // Timer nicht mehr benötigt
      
      // Benutzer über Erfolg informieren
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email verifiziert! Du wirst zur App weitergeleitet..."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );

      // Kurze Pause für User-Feedback, dann Navigation
      await Future.delayed(const Duration(seconds: 2));

      // Nach Verifizierung: Weiterleitung zur WelcomePage
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => WelcomePage(uid: widget.uid)),
          (route) => false, // Alle vorherigen Routes entfernen
        );
      }
    }
  }

  // Verifizierungs-Email erneut senden mit Cooldown-Mechanismus
  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    bool success = await _auth.resendEmailVerification();
    
    if (success) {
      // 60 Sekunden Cooldown aktivieren
      setState(() {
        _canResendEmail = false;
        _resendCooldown = 60;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifizierungs-Email erneut gesendet'),
          backgroundColor: Colors.green,
        ),
      );

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
      // Fehlermeldung bei unsuccessful send
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Senden der Email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(//Appbar anpassen, aktuell unsichtbar
        automaticallyImplyLeading: false, // Zurück-Button entfernen
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mail Icon je nach Verifizierungsstatus
            Icon(
              _isVerified ? Icons.check_circle : Icons.mark_email_unread,
              size: 100,
              color: _isVerified ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,),
            const SizedBox(height: 32),
            
            // Überschrift dynamisch je nach Status
            Text(
              _isVerified ? 'Email verifiziert!' : 'Email-Adresse verifizieren',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isVerified ? Theme.of(context).colorScheme.secondary : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Inhalt je nach Verifizierungsstatus
            if (!_isVerified) ...[
              Text(
                'Wir haben eine Verifizierungs-Email an',
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'gesendet. Bitte überprüfe dein Postfach und klicke auf den Verifizierungslink.',
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              // Verifizierung erfolgreich - Weiterleitungs-Info
              Text(
                'Du wirst automatisch zur App weitergeleitet...',
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Überprüfe Verifizierung...',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Aktions-Buttons nur wenn noch nicht verifiziert
            if (!_isVerified) ...[
              // Email erneut senden Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _canResendEmail ? _resendVerificationEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _canResendEmail
                        ? 'Email erneut senden'
                        : 'Erneut senden in ${_resendCooldown}s',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Zurück zur Anmeldung Button
              TextButton(
                onPressed: () async {
                  await _auth.signOut(); // Aktuellen User ausloggen
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
                    color: Theme.of(context).colorScheme.primary,
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