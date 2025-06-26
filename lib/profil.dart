import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  String vorname = "";
  String nachname = "";
  String benutzername = "";

  @override
  void initState() {
    super.initState();
    _ladeInformationen();
  }

  Future<void> _ladeInformationen() async {
    final String jsonString = await rootBundle.loadString(
      'assets/profil/informationen.json',
    );
    final Map<String, dynamic> data = json.decode(jsonString);
    setState(() {
      vorname = data['vorname'];
      nachname = data['nachname'];
      benutzername = data['benutzername'];
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                'assets/profil/profilbild.png',
              ), // Beispielbild
            ),
            SizedBox(height: 16),
            Text(
              "$vorname $nachname",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              benutzername,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    // Bearbeiten-Funktion
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
              "Streax Freunde: 14",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              "Längster Streak: 30",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Spacer(),
            Divider(color: Colors.grey),
            TextButton(
              onPressed: () {
                // Abmelden-Funktion
              },
              child: Text(
                "Abmelden",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
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
