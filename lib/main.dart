import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:streax/Screens/splashscreen.dart';

void main() async {
  // Flutter-Engine initialisieren für Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase mit plattformspezifischen Einstellungen starten
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(streax());
}

class streax extends StatelessWidget {
  const streax({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrapper übernimmt komplette App-Logik inkl. StreamProvider und MaterialApp
    return Wrapper();
  }
}
