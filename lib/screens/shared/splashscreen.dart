import 'package:flutter/material.dart';
import 'package:streax/screens/shared/user.dart';
import 'package:streax/screens/home/homepage.dart';
import 'package:streax/screens/authenticate/email_verification_screen.dart';
import 'package:streax/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:streax/screens/authenticate/authenticate.dart';
import 'dart:async';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _showSplash = true;
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    
    // Splash-Animation für kurze Zeit anzeigen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Während Splash-Phase nur Animation zeigen
    if (_showSplash) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: Image.asset(
                'assets/animations/streax-splash-animation.gif',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    // Nach Splash: StreamProvider für gesamte App mit derselben AuthService-Instanz
    return StreamProvider<StreaxUser?>.value(
      value: _auth.user,
      initialData: null,
      child: Consumer<StreaxUser?>(
        builder: (context, user, child) {

          // Fall 1: User ist eingeloggt aber Email noch nicht verifiziert
          if (user == null && _auth.isUserLoggedInButNotVerified) {
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              return MaterialApp(
                home: EmailVerificationScreen(email: currentUser.email ?? '',
                uid: currentUser.uid), //UID muss auch übergeben werden, damit die welcome page auch nach verifizierung funktioniert
                debugShowCheckedModeBanner: false,
                theme: _buildAppTheme(),
              );
            }
          }
          
          // Fall 2: User nicht eingeloggt -> Anmelde-/Registrierungsseite
          if (user == null) {
            return MaterialApp(
              home: Authenticate(),
              debugShowCheckedModeBanner: false,
              theme: _buildAppTheme(),
            );
          } else {
            // Fall 3: User eingeloggt und verifiziert -> Hauptapp mit Navigation
            return MaterialApp(
              title: 'streax',
              debugShowCheckedModeBanner: false,
              theme: _buildAppTheme(),
              home: Homepage(), // Startseite mit Navigationsleiste
            );
          }
        },
      ),
    );
  }

  // App-Theme ausgelagert für bessere Wartbarkeit
  ThemeData _buildAppTheme() {
    return ThemeData(
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontSize: 40),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(color: Colors.white, fontSize: 28),
        bodySmall: TextStyle(color: Colors.white, fontSize: 16),
      ),
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: const Color.fromARGB(255, 0, 115, 255),
        onPrimary: Colors.white,
        secondary: const Color.fromARGB(255, 100, 223, 211),
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        tertiary: const Color.fromARGB(255, 22, 0, 147),
        surface: const Color.fromARGB(255, 28, 32, 31),
        onSurface: const Color.fromARGB(255, 107, 109, 108),
        surfaceContainer: const Color.fromARGB(255, 43, 47, 46),
      ),
    );
  }
}