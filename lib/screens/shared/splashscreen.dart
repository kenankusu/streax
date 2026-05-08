import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:streax/Models/user.dart';
import 'package:streax/Screens/Home/homepage.dart';
import 'package:streax/Screens/Authenticate/email_verification_screen.dart';
import 'package:streax/Services/auth.dart';
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

  ThemeData _buildAppTheme() {
    const bg       = Color(0xFF111214);
    const card     = Color(0xFF1A1D21);
    const cardHigh = Color(0xFF252830);
    const border   = Color(0xFF2A2D35);
    const blue     = Color(0xFF2A9FFF);
    const green    = Color(0xFF1CE9B0);
    const accent   = Color(0xFF4A8FA8);
    const dimText  = Color(0xFF666666);

    return ThemeData(
      textTheme: GoogleFonts.barlowTextTheme().copyWith(
        headlineLarge: GoogleFonts.barlowCondensed(
          color: Colors.white, fontSize: 40,
          fontWeight: FontWeight.w900, letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.barlowCondensed(
          color: Colors.white, fontSize: 34,
          fontWeight: FontWeight.w900, letterSpacing: 1.0,
        ),
        headlineSmall: GoogleFonts.barlowCondensed(
          color: Colors.white, fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.barlow(
          color: Colors.white, fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.barlow(
          color: Colors.white, fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.barlow(
          color: Colors.white, fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.barlow(
          color: accent, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 1.2,
        ),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary:              blue,
        onPrimary:            Colors.white,
        secondary:            green,
        onSecondary:          Colors.black,
        error:                Colors.red,
        onError:              Colors.white,
        tertiary:             accent,
        surface:              bg,
        onSurface:            dimText,
        surfaceContainer:     card,
        surfaceContainerHighest: cardHigh,
      ),
      scaffoldBackgroundColor: bg,
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.barlow(color: dimText, fontSize: 14),
        hintStyle:  GoogleFonts.barlow(color: const Color(0xFF444444), fontSize: 13),
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.barlow(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1D21),
        contentTextStyle: GoogleFonts.barlow(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A2D35)),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 20, fontWeight: FontWeight.w900,
          letterSpacing: 2, color: Colors.white,
        ),
      ),
    );
  }
}