import 'package:flutter/material.dart';
import 'package:streax/Services/auth.dart';
import 'package:streax/Services/database.dart';
import 'package:streax/screens/Introscreens/introPage1.dart';
import 'package:streax/screens/Introscreens/introPage2.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'email_verification_screen.dart';

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

  // Controller für den PageView
  final PageController _controller = PageController();

  /// Führt die Registrierung durch und erstellt ein User-Profil
  Future<void> _performRegistration() async {
  if (!_formKey.currentState!.validate()) return;
  
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
                                        const SizedBox(height: 30.0),
                                        
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