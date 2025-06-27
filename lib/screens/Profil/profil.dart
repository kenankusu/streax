import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/auth.dart';
import '../shared/navigationsleiste.dart'; 
import 'package:flutter_application_1/services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/authenticate/willkommen.dart'; // Import der Willkommens-Seite


class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context)!; // ✅ ! weil User garantiert existiert

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          "Dein Profil",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DatabaseService(uid: user.uid).userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // ✅ Nur noch dieser Check: Profil-Daten erstellen falls sie nicht existieren
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Profil nicht gefunden',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Es scheint als hätten Sie noch kein Profil erstellt',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // ✅ Navigation zur Willkommens-Seite
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WillkommensSeite(uid: user.uid),
                        ),
                      );
                    },
                    child: Text('Jetzt Profil erstellen'),
                  ),
                ],
              ),
            );
          }

          // ✅ User-Daten aus Firestore - guaranteed to exist
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/profil/profilbild.png'),
                ),
                SizedBox(height: 16),
                Text(
                  userData['name'] ?? 'Unbekannter Name', // ✅ Einfacher fallback
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '@${userData['username'] ?? 'unbekannt'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        _showEditDialog(context, user.uid, userData);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        // Teilen-Funktion
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildActivityIcon(context, "+")],
                ),
                SizedBox(height: 16),
                Text(
                  "Streax Freunde: ${userData['freunde_anzahl'] ?? 0}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  "Längster Streak: ${userData['laengster_streak'] ?? 0}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Spacer(),
                Divider(color: Colors.grey),
                TextButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    "Abmelden",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 4),
    );
  }

  // ✅ Dialog für neue Profile
  void _showCreateProfileDialog(BuildContext context, String uid) {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Muss ausgefüllt werden
      builder: (context) => AlertDialog(
        title: Text('Profil erstellen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Dein Name',
                hintText: 'z.B. Max Mustermann',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'z.B. max_mustermann',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && usernameController.text.isNotEmpty) {
                await DatabaseService(uid: uid).updateUserData(
                  nameController.text,
                  usernameController.text,
                  freundeAnzahl: 0,
                  laengsterStreak: 0,
                );
                Navigator.pop(context);
              }
            },
            child: Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  // ✅ Dialog zum Bearbeiten - bleibt gleich
  void _showEditDialog(BuildContext context, String uid, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final usernameController = TextEditingController(text: currentData['username'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService(uid: uid).updateUserData(
                nameController.text,
                usernameController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}
