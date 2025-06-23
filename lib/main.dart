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


      // ThemeData für einheitliches Design
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: TextTheme( // Text Theme für einheitliche Schriftstile
          labelLarge: TextStyle(color: Colors.white, fontSize: 18),
          labelMedium: TextStyle(color: Colors.white, fontSize: 16),
          labelSmall: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}