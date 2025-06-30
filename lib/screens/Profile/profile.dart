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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 100,
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

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profil Header (Avatar, Name, Edit/Share buttons)
                      ProfileHeader(userData: userData, uid: user.uid),

                      const SizedBox(height: 16),

                      // Sportarten auswählen
                      SportIcons(userData: userData, uid: user.uid),

                      const SizedBox(height: 16),

                      // Profil Info (Streak, Gewicht, Größe, etc.)
                      ProfileInfo(userData: userData),

                      const Spacer(),

                      // Linie unten
                      Divider(color: Colors.grey),
                      _buildBottomActions(context, user.uid),
                    ],
                  ),
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

  Widget _buildBottomActions(BuildContext context, String uid) {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            await _auth.signOut();
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          },
          child: Text(
            "Abmelden",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            DeleteAccountDialog.show(context, uid, (isDeleting) {
              setState(() {
                _isDeleting = isDeleting;
              });
            });
          },
          child: Text(
            "Account löschen",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
