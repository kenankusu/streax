import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/navigationsleiste.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  String vorname = "";
  String nachname = "";
  String benutzername = "";
  final List<String> hinzugefuegteSportarten = [];

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
    final List<String> sportarten = ['Laufen', 'Boxen', 'Tischtennis'];
    final Map<String, String> sportIcons = {
      'Laufen': 'assets/icons/journal/rest.png',
      'Boxen': 'assets/icons/journal/boxen.png',
      'Tischtennis': 'assets/icons/journal/tt.png',
    };

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
              backgroundImage: AssetImage('assets/profil/profilbild.png'),
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
                    // Bearbeitenfunktion kommt noch
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Teilenfunktion kommt noch
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Deine Sportarten:",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...hinzugefuegteSportarten.map((sport) {
                  return Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(sportIcons[sport]!, width: 36, height: 36),
                        SizedBox(height: 4),
                        Text(
                          sport,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                GestureDetector(
                  onTap: () async {
                    final verfuegbareSportarten = sportarten
                        .where(
                          (sport) => !hinzugefuegteSportarten.contains(sport),
                        )
                        .toList();

                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                          title: Text(
                            "Sportart auswählen",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: verfuegbareSportarten.map((sport) {
                              return ListTile(
                                leading: Image.asset(
                                  sportIcons[sport]!,
                                  width: 36,
                                  height: 36,
                                ),
                                title: Text(
                                  sport,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                onTap: () {
                                  setState(() {
                                    hinzugefuegteSportarten.add(sport);
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 36),
                  ),
                ),
              ],
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
                // Abmeldenfunktion kommt noch
              },
              child: Text(
                "Abmelden",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: NavigationsLeiste(currentPage: 4),
    );
  }
}
