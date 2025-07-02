import 'package:flutter/material.dart';
import 'package:streax/Services/auth.dart';
import 'package:streax/Services/database.dart';
import 'package:streax/screens/Introscreens/introPage1.dart';
import 'package:streax/screens/Introscreens/introPage2.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'email_verification_screen.dart';


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

  //Controller für den PageView
  final PageController _controller = PageController();

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
                Expanded(
                  child: PageView(
                    controller: _controller,
                    children: [
                      IntroPage1(),
                      IntroPage2(),
                      // Registrierungsformular
                      // Registrierungsformular: Anmelde-Text oben, Rest zentriert
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                            child: GestureDetector(
                              onTap: () {
                                widget.toggleView();
                              },
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
                                          validator: (val) => val!.length < 10 ? 'Passwort muss mindestens 10 Zeichen lang sein' : null,
                                          onChanged: (val) {
                                            setState(() => password = val);
                                          },
                                        ),
                                        SizedBox(height: 30.0),
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
                                                  "Los geht's!",
                                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  if(_formKey.currentState!.validate()){
                                                    setState(() => loading = true);
                                                    
                                                    try {
                                                      Map<String, dynamic> result = await _auth.registerWithEmailAndPassword(email, password);
                                                      
                                                      if(result['success'] == true && result['user'] != null) {
                                                        // User-Profil erstellen mit der UID aus der Map
                                                        await DatabaseService(uid: result['uid']).updateUserData(
                                                          'Neuer',
                                                          'User',
                                                        );
                                                        
                                                        // Zur Email-Verifizierung weiterleiten
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
                    ],
                  ),
                ),
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