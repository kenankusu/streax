import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/screens/shared/splashscreen.dart';
import 'package:streax/services/database.dart';   

void main() async {
  // Flutter-Engine initialisieren für Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase mit plattformspezifischen Einstellungen starten
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Streak-Status prüfen, falls User eingeloggt
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await DatabaseService(uid: user.uid).checkStreakStatus();
  }

  runApp(streax());
}

class streax extends StatelessWidget {
  const streax({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrapper();
  }
}
