import 'package:flutter/material.dart';
import 'package:streax/services/auth.dart';
import 'package:streax/services/database.dart';
import 'package:streax/screens/introscreens/introPage1.dart';
import 'package:streax/screens/introscreens/introPage2.dart';
import 'package:streax/screens/authenticate/email_verification_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Registrierungs-Screen mit Intro-Seiten und Registrierungsformular
/// Nutzt PageView für eine schöne Einführung in die App
class Register extends StatefulWidget {
  final Function toggleView;
  const Register({ required this.toggleView, super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Eingabefelder-Status
  String email = '';
  String password = '';
  String error = '';

  // Einwilligungen (DSGVO-Pflicht)
  bool _privacyAccepted = false;
  bool _healthDataAccepted = false;
  bool _ageConfirmed = false;

  // Controller für den PageView
  final PageController _controller = PageController();

  /// Führt die Registrierung durch und erstellt ein User-Profil
  Future<void> _performRegistration() async {
  if (!_formKey.currentState!.validate()) return;

  if (!_privacyAccepted || !_healthDataAccepted || !_ageConfirmed) {
    setState(() => error = 'Bitte alle Einwilligungen bestätigen.');
    return;
  }
  
  setState(() => loading = true);
  
  try {
    Map<String, dynamic> result = await _auth.registerWithEmailAndPassword(email, password);
    
    if (result['success'] == true && result['user'] != null) {
      
      // Firestore-Fehler soll Registrierung NICHT blockieren
      try {
        await DatabaseService(uid: result['uid']).updateUserData('Neuer', 'User');
      } catch (dbError) {
        debugPrint('Firestore-Profil konnte nicht erstellt werden: $dbError');
        // Kein return, kein setState(error) – weitermachen!
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: result['email'],
              uid: result['uid'],
            ),
          ),
        );
      }
    } else {
      setState(() {
        error = result['error'] ?? 'Registrierung fehlgeschlagen';
        loading = false;
      });
    }
  } catch (e) {
    setState(() {
      error = 'Registrierung fehlgeschlagen: $e';
      loading = false;
    });
  }
}

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D21),
        title: const Text('Datenschutzerklärung', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            'Verantwortlicher: <Kenan Kusu>\n\n'
            'Wir verarbeiten folgende personenbezogene Daten:\n'
            '• E-Mail-Adresse, Vorname, Nachname, Nutzername\n'
            '• Körperdaten: Gewicht, Größe, Geburtsdatum\n'
            '• Aktivitätsdaten: Sportart, Dauer, Distanz, Stimmung\n'
            '• Profilbild und Aktivitätsfotos\n\n'
            'Rechtsgrundlage: Einwilligung (Art. 6 Abs. 1 lit. a DSGVO) sowie '
            'Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO).\n\n'
            'Gesundheitsdaten werden ausschließlich zur Bereitstellung der App-Funktionen '
            'verarbeitet (Art. 9 Abs. 2 lit. a DSGVO).\n\n'
            'Drittanbieter: Firebase (Google Ireland Ltd.) als Auftragsverarbeiter '
            'für Authentifizierung, Datenbank und Dateispeicherung.\n\n'
            'Deine Rechte: Auskunft, Berichtigung, Löschung, Einschränkung, '
            'Datenübertragbarkeit und Widerspruch jederzeit per E-Mail an '
            'kenan.kusu@gmail.com\n\n'
            'Account und alle Daten können jederzeit in den Profileinstellungen '
            'vollständig gelöscht werden.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _consentCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            side: const BorderSide(color: Colors.white38),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: child)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // PageView mit Intro-Seiten und Registrierung
                Expanded(
                  child: PageView(
                    controller: _controller,
                    children: [
                      const IntroPage1(),
                      const IntroPage2(),
                      // Registrierungsformular als dritte Seite
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Wechsel zur Anmeldung
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                            child: GestureDetector(
                              onTap: () => widget.toggleView(),
                              child: Text(
                                'Du kennst das hier schon? Dann meld dich an',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          
                          // Hauptformular
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          'Es gibt für alles ein erstes Mal',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.headlineLarge,
                                        ),
                                        const SizedBox(height: 20.0),
                                        
                                        // Email-Eingabefeld
                                        TextFormField(
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: 'Deine E-mail',
                                            hintStyle: const TextStyle(color: Colors.white),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.onSurface,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30.0),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          validator: (val) => val!.isEmpty ? 'Email eingeben' : null,
                                          onChanged: (val) => setState(() => email = val),
                                        ),
                                        const SizedBox(height: 20.0),
                                        
                                        // Passwort-Eingabefeld mit Mindestlängen-Validierung
                                        TextFormField(
                                          style: const TextStyle(color: Colors.white),
                                          obscureText: true,
                                          decoration: InputDecoration(
                                            hintText: 'Ein starkes Passwort',
                                            hintStyle: const TextStyle(color: Colors.white),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.onSurface,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30.0),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          validator: (val) => val!.length < 10 ? 'Passwort muss mindestens 10 Zeichen lang sein' : null,
                                          onChanged: (val) => setState(() => password = val),
                                        ),
                                        const SizedBox(height: 20.0),

                                        // Einwilligungen (DSGVO)
                                        _consentCheckbox(
                                          value: _privacyAccepted,
                                          onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                                          child: RichText(
                                            text: TextSpan(
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                                              children: [
                                                const TextSpan(text: 'Ich habe die '),
                                                WidgetSpan(
                                                  child: GestureDetector(
                                                    onTap: () => _showPrivacyPolicy(context),
                                                    child: Text(
                                                      'Datenschutzerklärung',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const TextSpan(text: ' gelesen und stimme zu. *'),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10.0),

                                        _consentCheckbox(
                                          value: _healthDataAccepted,
                                          onChanged: (v) => setState(() => _healthDataAccepted = v ?? false),
                                          child: Text(
                                            'Ich willige in die Verarbeitung meiner Gesundheitsdaten (Gewicht, Größe, Geburtsdatum) zur Nutzung der App ein. *',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                                          ),
                                        ),
                                        const SizedBox(height: 10.0),

                                        _consentCheckbox(
                                          value: _ageConfirmed,
                                          onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
                                          child: Text(
                                            'Ich bestätige, dass ich mindestens 16 Jahre alt bin. *',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '* Pflichtfelder',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38, fontSize: 11),
                                          ),
                                        ),

                                        const SizedBox(height: 20.0),

                                        // Registrierungs-Button mit Gradient
                                        Align(
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: 220,
                                            height: 50,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Theme.of(context).colorScheme.primary,
                                                    Theme.of(context).colorScheme.secondary,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                borderRadius: BorderRadius.circular(30.0),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.5),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30.0),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 32.0),
                                                  minimumSize: const Size(0, 0),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: _performRegistration,
                                                child: Text(
                                                  "Los geht's!",
                                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12.0),
                                        
                                        // Fehlermeldung
                                        Text(
                                          error,
                                          style: const TextStyle(color: Colors.red, fontSize: 14.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Page-Indikator unten
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                  child: SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: WormEffect(
                      dotColor: Theme.of(context).colorScheme.onSurface,
                      activeDotColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}