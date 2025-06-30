import 'package:flutter/material.dart';
import 'package:streax/Models/user.dart';
import 'package:streax/Services/auth.dart';
import '../Shared/navigationbar.dart';
import 'package:streax/Services/database.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final AuthService _auth = AuthService();
  bool _isDeleting = false; // Flag für Account-Löschung

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<StreaxUser?>(context);

    if (user == null) {
      // Navigation zurück zum Wrapper nach dem Frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Container(), // Leer - Wrapper übernimmt
      );
    }

    // Während der Account-Löschung nur Loading anzeigen
    if (_isDeleting) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
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
        title: Text('Profil', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
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

                // Fehler während Account-Löschung ignorieren
                if (snapshot.hasError && _isDeleting) {
                  return Container();
                }

                // Profil ist immer vorhanden → direkt anzeigen
                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(
                          'assets/profil/profilbild.png',
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${userData['firstName'] ?? 'Unbekannter'} ${userData['lastName'] ?? 'Name'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        '@${userData['username'] ?? 'unbekannt'}',
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
                      // "Deine Sportarten" Label über der horizontalen Liste
                      Text(
                        "Deine Sportarten:",
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      // Horizontale scrollbare Liste mit Sportarten und Plus-Button
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 16),
                            // Ausgewählte Sportarten
                            if (userData['sports'] != null &&
                                (userData['sports'] as List).isNotEmpty)
                              ...((userData['sports'] as List<dynamic>)
                                  .cast<String>()
                                  .map(
                                    (sport) => _buildSportIcon(context, sport),
                                  )
                                  .toList()),
                            // Plus-Button
                            GestureDetector(
                              onTap: () => _showSportSelectionDialog(
                                context,
                                user.uid,
                                userData,
                              ),
                              child: _buildActivityIcon(context, "+"),
                            ),
                            SizedBox(width: 16),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Streax Freunde: ${userData['friends_count'] ?? 0}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        "Dein längster streak: ${userData['longest_streak'] ?? 0}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        "Dein Gewicht: ${userData['weight'] != null ? '${userData['weight']} kg' : 'Nicht angegeben'}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        "Deine Größe: ${userData['height'] != null ? '${userData['height']} cm' : 'Nicht angegeben'}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        "Geschlecht: ${userData['gender'] ?? 'Nicht angegeben'}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Spacer(),
                      Divider(color: Colors.grey),
                      // Abmeldefunktion -> man landet wieder beim wrapper
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
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _showDeleteAccountDialog(context, user.uid);
                        },
                        child: Text(
                          "Account löschen",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.red),
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

  // Edit-Dialog für bestehende Profile
  void _showEditDialog(
    BuildContext context,
    String uid,
    Map<String, dynamic> currentData,
  ) {
    final firstNameController = TextEditingController(
      text: currentData['firstName'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: currentData['lastName'] ?? '',
    );
    final usernameController = TextEditingController(
      text: currentData['username'] ?? '',
    );
    final weightController = TextEditingController(
      text: currentData['weight']?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: currentData['height']?.toString() ?? '',
    );
    String selectedGender = currentData['gender'] ?? 'Nicht angegeben';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil bearbeiten'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: 'Vorname'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Nachname'),
                ),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: 'Gewicht (kg)',
                    hintText: 'z.B. 70',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: heightController,
                  decoration: InputDecoration(
                    labelText: 'Größe (cm)',
                    hintText: 'z.B. 175',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: false),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(labelText: 'Geschlecht'),
                  items: ['Nicht angegeben', 'Männlich', 'Weiblich', 'Divers']
                      .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGender = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              // Validierung
              if (firstNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vorname darf nicht leer sein')),
                );
                return;
              }

              if (lastNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nachname darf nicht leer sein')),
                );
                return;
              }

              if (usernameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Username darf nicht leer sein')),
                );
                return;
              }

              // Gewicht parsen und validieren
              double? weight;
              if (weightController.text.isNotEmpty) {
                weight = double.tryParse(weightController.text);
                if (weight == null || weight <= 0 || weight > 500) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bitte gültiges Gewicht eingeben (1-500 kg)',
                      ),
                    ),
                  );
                  return;
                }
              }

              // Größe parsen und validieren
              int? height;
              if (heightController.text.isNotEmpty) {
                height = int.tryParse(heightController.text);
                if (height == null || height <= 0 || height > 300) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bitte gültige Größe eingeben (1-300 cm)'),
                    ),
                  );
                  return;
                }
              }

              try {
                await DatabaseService(uid: uid).updateUserData(
                  firstNameController.text.trim(),
                  lastNameController.text.trim(),
                  username: usernameController.text.trim(),
                  weight: weight,
                  height: height,
                  gender: selectedGender != 'Nicht angegeben'
                      ? selectedGender
                      : null,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profil erfolgreich aktualisiert!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler beim Speichern: $e')),
                );
              }
            },
            child: Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // Account-Löschung Dialog
  void _showDeleteAccountDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Account löschen',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bist du sicher, dass du deinen Account unwiderruflich löschen möchtest?\n\nAlle deine Daten, Aktivitäten und dein Fortschritt gehen dabei verloren.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation(context, uid);
            },
            child: Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Finale Bestätigung
  void _showFinalDeleteConfirmation(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Letzte Bestätigung',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Dies ist deine letzte Chance!\n\nWenn du auf "Endgültig löschen" klickst, wird dein Account sofort und unwiderruflich gelöscht.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Doch nicht löschen',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, uid);
            },
            child: Text(
              'Endgültig löschen',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Account tatsächlich löschen - Überarbeitet
  Future<void> _deleteAccount(BuildContext context, String uid) async {
    // Sofort _isDeleting auf true setzen um UI zu ändern
    setState(() {
      _isDeleting = true;
    });

    try {
      // 1. Alle Firestore-Daten löschen
      bool firestoreDeleted = await DatabaseService(
        uid: uid,
      ).deleteAllUserData();

      // 2. Firebase Auth Account löschen
      bool authDeleted = await _auth.deleteAccount();

      // Da der Account gelöscht ist, wird automatisch der Wrapper aktiviert
      // und zur Login-Seite navigiert. Kein manueller Dialog nötig.

      if (!firestoreDeleted || !authDeleted) {
        // Nur bei Fehlern Dialog anzeigen
        setState(() {
          _isDeleting = false;
        });
        _showErrorDialog(
          context,
          'Beim Löschen des Accounts ist ein Fehler aufgetreten.',
        );
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      _showErrorDialog(context, 'Unerwarteter Fehler: $e');
    }
  }

  // Fehler-Dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Fehler', style: TextStyle(color: Colors.red)),
        content: Text(message, style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.red)),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Sportarten',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // Sportarten-Auswahl Dialog
  void _showSportSelectionDialog(
    BuildContext context,
    String uid,
    Map<String, dynamic> currentData,
  ) {
    List<String> availableSports = [
      'Laufen',
      'Radfahren',
      'Schwimmen',
      'Krafttraining',
      'Yoga',
      'Pilates',
      'Tennis',
      'Fußball',
      'Basketball',
      'Volleyball',
      'Wandern',
      'Klettern',
      'Boxen',
      'Martial Arts',
      'Crossfit',
      'Tanzen',
      'Golf',
      'Badminton',
      'Skifahren',
      'Snowboarden',
      'Surfen',
      'Reiten',
      'Rudern',
      'Calisthenics',
      'Andere',
    ];

    List<String> selectedSports = currentData['sports'] != null
        ? List<String>.from(currentData['sports'])
        : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Sportarten auswählen',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Wähle deine Lieblingssportarten aus:',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  SizedBox(height: 16),
                  ...availableSports
                      .map(
                        (sport) => CheckboxListTile(
                          title: Text(
                            sport,
                            style: TextStyle(color: Colors.white),
                          ),
                          value: selectedSports.contains(sport),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedSports.add(sport);
                              } else {
                                selectedSports.remove(sport);
                              }
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                          checkColor: Colors.white,
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await DatabaseService(
                    uid: uid,
                  ).updateUserSports(selectedSports);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sportarten erfolgreich gespeichert!'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Speichern: $e')),
                  );
                }
              },
              child: Text(
                'Speichern',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportIcon(BuildContext context, String sportName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onLongPress: () => _showRemoveSportDialog(context, sportName),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  sportName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              sportName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog zum Entfernen einer Sportart
  void _showRemoveSportDialog(BuildContext context, String sportName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sportart entfernen'),
        content: Text('Möchten Sie "$sportName" aus Ihren Sportarten entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Aktuelle Sportarten laden
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                if (userDoc.exists) {
                  List<String> currentSports =
                      (userDoc.data()?['sports'] as List<dynamic>?)
                          ?.cast<String>() ?? [];

                  // Sportart entfernen
                  currentSports.remove(sportName);

                  // Aktualisierte Liste speichern
                  await DatabaseService(uid: user.uid)
                      .updateUserSports(currentSports);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$sportName wurde entfernt'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
