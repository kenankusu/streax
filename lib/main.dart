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
    );
  }
}