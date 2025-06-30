import 'package:flutter/material.dart';
import 'package:streax/Screens/Authenticate/inputFieldStyle.dart';
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
  
  // Checkbox state für "Eingeloggt bleiben"
  bool stayLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return loading ? Loading() : Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        backgroundColor: Colors.brown[400],
        elevation: 0.0,
        title: Text('Anmelden bei Streax'),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(Icons.person),
            label: Text('Registrieren'),
            onPressed: () => widget.toggleView(),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20.0),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Email eingeben' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              SizedBox(height: 20.0),
              TextFormField(
                obscureText: true,
                decoration: textInputDecoration.copyWith(hintText: 'Passwort'),
                validator: (val) => val!.length < 10 ? 'Passwort muss mindestens 10 Zeichen lang sein' : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              SizedBox(height: 15.0),
              
              // "Eingeloggt bleiben" Checkbox
              Row(
                children: [
                  Checkbox(
                    value: stayLoggedIn,
                    onChanged: (value) {
                      setState(() {
                        stayLoggedIn = value ?? false;
                      });
                    },
                    activeColor: Colors.brown[400],
                  ),
                  Expanded(
                    child: Text(
                      'Eingeloggt bleiben',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20.0),
              ElevatedButton(
                child: Text(
                  'Anmelden',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if(_formKey.currentState!.validate()){
                    setState(() => loading = true);
                    
                    try {
                      // Checkbox-Wert an Auth-Service übergeben
                      dynamic result = await _auth.signInWithEmailAndPassword(
                        email, 
                        password, 
                        stayLoggedIn: stayLoggedIn
                      );
                      
                      if(result == null) {
                        setState(() {
                          error = 'Login fehlgeschlagen - Email/Passwort prüfen';
                          loading = false;
                        });
                      }
                    } on FirebaseAuthException catch (e) {
                      setState(() {
                        loading = false;
                        // Spezifische Fehlermeldungen für Login
                        switch (e.code) {
                          case 'invalid-credential':
                            error = 'Email oder Passwort ist falsch';
                            break;
                          case 'user-not-found':
                            error = 'Kein Account mit dieser Email-Adresse gefunden';
                            break;
                          case 'wrong-password':
                            error = 'Falsches Passwort';
                            break;
                          case 'invalid-email':
                            error = 'Ungültige Email-Adresse';
                            break;
                          case 'user-disabled':
                            error = 'Dieser Account wurde deaktiviert';
                            break;
                          case 'too-many-requests':
                            error = 'Zu viele Anmeldeversuche. Bitte später erneut versuchen';
                            break;
                          case 'network-request-failed':
                            error = 'Netzwerkfehler. Bitte Internetverbindung prüfen';
                            break;
                          default:
                            error = 'Anmeldung fehlgeschlagen. Bitte Email und Passwort prüfen';
                        }
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
              SizedBox(height: 12.0),
              
              // ✅ Neuer "Passwort vergessen" Link
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => PasswordResetDialog(),
                  );
                },
                child: Text(
                  'Passwort vergessen?',
                  style: TextStyle(
                    color: Colors.brown[600],
                    decoration: TextDecoration.underline,
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
    );
  }
}