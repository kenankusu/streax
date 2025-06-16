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
          bodyLarge: TextStyle(color: Colors.white, fontSize: 20),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 18),
          bodySmall: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
