import 'package:flutter/material.dart';
import 'package:streax/Screens/Shared/loading.dart';
import 'package:streax/Services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'password_reset_dialog.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({ required this.toggleView, super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  
  // text field state
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading ? Loading() : Scaffold(
      body: Column(
        children: [
          
          Center(
            child: Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
            child: GestureDetector(
              onTap: () {
                widget.toggleView();
              },
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
          SizedBox(height: 10),
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
                        SizedBox(height: 20.0),
                        TextFormField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Deine E-mail',
                            hintStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.onSurface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) => val!.isEmpty ? 'Email eingeben' : null,
                          onChanged: (val) {
                            setState(() => email = val);
                          },
                        ),
                        SizedBox(height: 20.0),
                        TextFormField(
                          style: TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Passwort',
                            hintStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.onSurface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) => val!.isEmpty ? 'Passwort eingeben' : null,
                          onChanged: (val) {
                            setState(() => password = val);
                          },
                        ),
                        SizedBox(height: 15.0),
                        
                        // "Passwort vergessen?" Link
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => PasswordResetDialog(),
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
                        
                        SizedBox(height: 20.0),
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
                                    offset: Offset(0, 4),
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
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Anmelden',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async {
                                  if(_formKey.currentState!.validate()){
                                    setState(() => loading = true);
                                    
                                    try {
                                      dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                                      
                                      if(result == null) {
                                        setState(() {
                                          error = 'Login fehlgeschlagen - Email/Passwort prüfen';
                                          loading = false;
                                        });
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      // Spezifische Firebase Auth Fehler behandeln
                                      String errorMessage;
                                      switch (e.code) {
                                        case 'invalid-credential':
                                          errorMessage = 'Falsche Email oder Passwort';
                                          break;
                                        case 'invalid-email':
                                          errorMessage = 'Ungültige Email-Adresse';
                                          break;
                                        case 'user-disabled':
                                          errorMessage = 'Dieser Account wurde deaktiviert';
                                          break;
                                        case 'too-many-requests':
                                          errorMessage = 'Zu viele Anmeldeversuche. Versuche es später erneut';
                                          break;
                                        case 'email-not-verified':
                                          errorMessage = 'Email-Adresse noch nicht verifiziert';
                                          break;
                                        case 'network-request-failed':
                                          errorMessage = 'Netzwerkfehler. Internetverbindung prüfen';
                                          break;
                                        default:
                                          errorMessage = 'Anmeldung fehlgeschlagen. Bitte versuche es erneut';
                                      }
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
                                }
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.0),
                        Text(
                          error,
                          style: TextStyle(color: Colors.red, fontSize: 14.0),
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