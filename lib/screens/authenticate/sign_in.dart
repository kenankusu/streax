import 'package:flutter/material.dart';
import 'package:streax/Screens/Authenticate/inputFieldStyle.dart';
import 'package:streax/Screens/Shared/loading.dart';
import 'package:streax/Services/auth.dart';

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
                validator: (val) => val!.length < 6 ? 'Passwort muss mindestens 6 Zeichen lang sein' : null,
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
                  }
                }
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