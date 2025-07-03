import 'package:flutter/material.dart';
import 'package:streax/Models/user.dart';
import 'package:streax/Services/auth.dart';
import '../Shared/navigationbar.dart';
import 'package:streax/Services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importiere der gruppierten Module
import 'profile_widgets.dart';
import 'sport_editing.dart';
import 'delete_account.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final AuthService _auth = AuthService();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Container(),
      );
    }

    if (_isDeleting) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Account wird gelöscht...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Hauptinhalt - füllt den ganzen Bildschirm
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 100), // Top padding für Status Bar, Bottom für Navigation
            child: StreamBuilder<DocumentSnapshot>(
              stream: DatabaseService(uid: user.uid).userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError && _isDeleting) {
                  return Container();
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Titel
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Text(
                        'Profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    
                    // Profil Header (Avatar, Name, Edit/Share buttons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: ProfileHeader(userData: userData, uid: user.uid),
                      ),
                    ),

                    // Sportarten auswählen
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: SportIcons(userData: userData, uid: user.uid),
                      ),
                    ),

                    // Profil Info (Streak, Gewicht, Größe, etc.)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: ProfileInfo(userData: userData),
                      ),
                    ),

                    // Linie oben
                    const Divider(color: Colors.grey, thickness: 0.7, height: 24),

                    // Bottom Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: _buildBottomActions(context, user.uid),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Navigation Bar
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationsLeiste(currentPage: 4),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Widget _buildBottomActions(BuildContext context, String uid) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(Icons.logout, color: Colors.red.shade300),
            label: Text(
              "Abmelden",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade300, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Colors.red.shade300, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _handleLogout,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(Icons.delete_forever, color: Colors.red.shade400),
            label: Text(
              "Account löschen",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade400, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Colors.red.shade400, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              DeleteAccountDialog.show(context, uid, (isDeleting) {
                setState(() {
                  _isDeleting = isDeleting;
                });
              });
            },
          ),
        ),
      ],
    );
  }
}
