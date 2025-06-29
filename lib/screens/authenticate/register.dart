import 'package:flutter/material.dart';
import 'package:streax/screens/authenticate/inputFieldStyle.dart';
import 'package:streax/screens/shared/loading.dart';
import 'package:streax/services/auth.dart';
import 'package:streax/services/database.dart';
import 'package:streax/screens/introscreens/introPage1.dart';
import 'package:streax/screens/introscreens/introPage2.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
  
  // Checkbox state für "Eingeloggt bleiben"
  bool stayLoggedIn = false;

  //Controller für den PageView
  PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () {
                widget.toggleView();
              },
              child: Text(
                'Du kennst das hier schon? Dann meld dich an',
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
            child: PageView(
              controller: _controller,
              children: [
                IntroPage1(), //Die ersten Einführungsseiten
                IntroPage2(),

                // Registrierungsformular
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Es gibt für alles ein erstes Mal',
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
                              hintText: 'Ein starkes Passwort',
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
                                    "Los geht's!",
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () async {
                                    if(_formKey.currentState!.validate()){
                                      setState(() => loading = true);
                                      dynamic result = await _auth.registerWithEmailAndPassword(
                                        email, 
                                        password, 
                                        stayLoggedIn: stayLoggedIn
                                      );
                                      if(result == null) {
                                        setState(() {
                                          error = 'Registrierung fehlgeschlagen - Email bereits vergeben?';
                                          loading = false;
                                        });
                                      } else {
                                        await DatabaseService(uid: result.uid).updateUserData(
                                          'Neuer User',
                                          'user${DateTime.now().millisecondsSinceEpoch}',
                                        );
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SmoothPageIndicator(controller: _controller, count: 3),
          ),
        ],
      ),
    );
  }
}