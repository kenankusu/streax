import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Authenticate/inputFieldStyle.dart';
import 'package:flutter_application_1/Screens/Shared/loading.dart';
import 'package:flutter_application_1/Services/auth.dart';

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
      body: Column(
        children: [
          SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () {
                widget.toggleView();
              },
              child: Text(
                'Du hast noch keinen Account? Jetzt registrieren!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
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
                          validator: (val) => val!.length < 6 ? 'Passwort muss mindestens 6 Zeichen lang sein' : null,
                          onChanged: (val) {
                            setState(() => password = val);
                          },
                        ),
                        SizedBox(height: 15.0),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Text(
                              'Eingeloggt bleiben',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                                    color: Colors.black.withOpacity(0.5),
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