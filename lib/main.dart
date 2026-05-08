import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/Screens/splashscreen.dart'; 
import 'package:streax/services/database.dart';

void main() async {
  // Flutter-Engine initialisieren für Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase mit plattformspezifischen Einstellungen starten
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialisierung für eingeloggte User
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final db = DatabaseService(uid: user.uid);
    await db.checkStreakStatus();
    db.cleanupStaleRequests(); // fire-and-forget, läuft im Hintergrund
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
