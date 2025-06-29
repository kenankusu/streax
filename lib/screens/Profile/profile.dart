import 'package:flutter/material.dart';
import 'package:streax/Models/user.dart';
import 'package:streax/Services/auth.dart';
import '../Shared/navigationbar.dart'; 
import 'package:streax/Services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context);
    
    if (user == null) {
      return Scaffold(body: Center(child: Text('Nicht angemeldet')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Profil', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack( // Stack hinzugefügt
        children: [
          // Hauptinhalt in Positioned
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 100, // Platz für Navigation
            child: StreamBuilder<DocumentSnapshot>(
              stream: DatabaseService(uid: user.uid).userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // ✅ Profil ist immer vorhanden → direkt anzeigen
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
                        userData['name'] ?? 'Unbekannter Name',
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
          ),
          // Schwebende Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationsLeiste(currentPage: 4),
          ),
        ],
      ),
    );
  }

  // ✅ Edit-Dialog für bestehende Profile
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
