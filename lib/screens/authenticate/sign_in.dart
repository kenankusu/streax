import 'package:flutter/material.dart';
import 'package:streax/shared/widgets/loading.dart';
import 'package:streax/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/screens/authenticate/password_reset_dialog.dart';

/// Login-Screen mit Email-Verifizierung und Passwort-Reset
/// Behandelt alle Authentifizierungs-Szenarien inklusive nicht-verifizierter Accounts
class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({ required this.toggleView, super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  
  // Form und Controller
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  
  // Eingabefelder-Status
  String email = '';
  String password = '';
  String error = '';

  /// Führt die Anmeldung durch mit umfassender Fehlerbehandlung
  Future<void> _performSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => loading = true);
    
    try {
      dynamic result = await _auth.signInWithEmailAndPassword(email, password);
      
      if (result == null) {
        setState(() {
          error = 'Login fehlgeschlagen - Email/Passwort prüfen';
          loading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      // Spezifische Firebase Auth Fehler behandeln
      String errorMessage = _getGermanErrorMessage(e.code);
      setState(() {
        error = errorMessage;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Ein unerwarteter Fehler ist aufgetreten';
        loading = false;
      });
    }
  }

  /// Wandelt Firebase-Fehlercodes in deutsche Meldungen um
  String _getGermanErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
        return 'Falsche Email oder Passwort';
      case 'invalid-email':
        return 'Ungültige Email-Adresse';
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert';
      case 'too-many-requests':
        return 'Zu viele Anmeldeversuche. Bitte versuche es später erneut';
      case 'email-not-verified':
        return 'Email-Adresse noch nicht verifiziert';
      case 'network-request-failed':
        return 'Netzwerkfehler. Internetverbindung prüfen';
      default:
        return 'Anmeldung fehlgeschlagen. Bitte versuche es erneut';
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Loading() : Scaffold(
      body: Column(
        children: [
          // Wechsel zur Registrierung
          Center(
            child: Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
            child: GestureDetector(
              onTap: () => widget.toggleView(),
              child: Text(
                'Neu hier? Registrier dich hier!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
                ),
              ),
          ),),
          const SizedBox(height: 10),
          
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
                          'Willkommen zurück!',
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
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
                        
                        // Passwort-Eingabefeld
                        TextFormField(
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Passwort',
                            hintStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.onSurface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) => val!.isEmpty ? 'Passwort eingeben' : null,
                          onChanged: (val) => setState(() => password = val),
                        ),
                        const SizedBox(height: 15.0),
                        
                        // "Passwort vergessen?" Link
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const PasswordResetDialog(),
                              );
                            },
                            child: Text(
                              'Passwort vergessen?',
                              style: TextStyle(
                                color: Colors.grey[600],
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20.0),
                        
                        // Anmelde-Button mit Gradient
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
                                onPressed: _performSignIn,
                                child: Text(
                                  'Anmelden',
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
    );
  }
}