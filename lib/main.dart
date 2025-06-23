import 'package:flutter/material.dart';
import 'startseite.dart';

void main() => runApp(streax());

class streax extends StatelessWidget {
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
          headlineSmall: TextStyle(color: Colors.white, fontSize: 16),
          bodySmall: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
