import 'package:flutter/material.dart';
import 'startseite.dart';

void main() => runApp(streax());

class streax extends StatelessWidget {
  const streax({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'streax',
      home: startseite(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          headlineLarge: TextStyle(color: Colors.white, fontSize: 40),
          headlineMedium: TextStyle(color: Colors.white,fontSize: 34, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontSize: 28),
          bodySmall: TextStyle(color: Colors.white, fontSize: 16),
        ),
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color.fromARGB(255, 0, 115, 255), //Zweite Akzentfarbe
          onPrimary: Colors.white,
          secondary: const Color.fromARGB(255, 100, 223, 211), //Highlight Farbe
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          tertiary: const Color.fromARGB(255, 22, 0, 147), //Hauptakzentfarbe
          surface: const Color.fromARGB(255, 28, 32, 31), //Hintergrundfarbe aller Seiten
          onSurface: const Color.fromARGB(255, 107, 109, 108), //Highlight Farbe
          surfaceContainer: const Color.fromARGB(255, 43, 47, 46), //Hintergrundfarbe der Container, z.B. Navigation bar
        ),
      )
    );
  }
}
