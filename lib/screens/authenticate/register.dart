import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Authenticate/inputFieldStyle.dart';
import 'package:flutter_application_1/Screens/Shared/loading.dart';
import 'package:flutter_application_1/Services/auth.dart';
import 'package:flutter_application_1/Screens/Welcome/welcome.dart'; // ✅ Import hinzufügen

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
        title: const Text('Registriere dich'),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(Icons.person),
            label: Text('Anmelden'),
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
                child: Text('Registrieren'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => loading = true);
                    dynamic result = await _auth.registerWithEmailAndPassword(email, password);
                    if (result == null) {
                      setState(() {
                        error = 'Registration fehlgeschlagen';
                        loading = false;
                      });
                    } else {
                      // ✅ Navigation zur eigenen Willkommens-Seite
                      setState(() => loading = false);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WillkommensSeite(uid: result.uid),
                        ),
                      );
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