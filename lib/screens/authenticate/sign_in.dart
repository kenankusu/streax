import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/authenticate/inputFeldStyle.dart';
import 'package:flutter_application_1/screens/shared/loading.dart';
import 'package:flutter_application_1/services/auth.dart';

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
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        backgroundColor: Colors.brown[400],
        elevation: 0.0,
        title: const Text('Melde dich an'),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(Icons.person),
            label: Text('Registrieren'),
            onPressed: () async {
              widget.toggleView();
            }
          )
        ]
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 20.0),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'E-Mail'),
                validator: (val) => val?.isEmpty ?? true ? 'Gib eine E-Mail ein' : null,
                onChanged: (val) {
                  setState(() => email = val);
                }
              ),
              SizedBox(height: 20.0),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Passwort'),
                validator: (val) => (val?.length ?? 0) < 6 ? 'Gib ein Passwort mit mindestens 6 Zeichen ein' : null,
                obscureText: true,
                onChanged: (val) {
                  setState(() => password = val);
                }
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  foregroundColor: Colors.white,
                ),
                child: Text('Anmelden'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => loading = true);
                    dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                    if (result == null) {
                      setState(() {
                        error = 'Ungültige Zugangsdaten. Bitte versuche es erneut.';
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
              )
            ]
          )
        )
      ),
    );
  }
}