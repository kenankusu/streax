// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';  // Diesen Import hinzufügen
import 'package:streax/services/database.dart';

class WelcomePage extends StatefulWidget {
  final String uid;

  const WelcomePage({required this.uid, super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  DateTime? selectedBirthdate;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ Verhindert Zurück-Navigation
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Willkommen bei Streax!',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Erstelle dein Profil um zu beginnen',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 60),

                // Form
                Text(
                  'Profil erstellen',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                SizedBox(height: 32),

                // Name Input
                TextFormField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Dein Name',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'z.B. Max Mustermann',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Colors.grey[400],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Username Input
                TextFormField(
                  controller: usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'z.B. max_mustermann',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: Colors.grey[400],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Geburtsdatum-Feld
                GestureDetector(
                  onTap: () => _showBirthdatePicker(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      // Rote Umrandung wenn nicht ausgewählt
                      border: selectedBirthdate == null 
                        ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
                        : null,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake_outlined, color: Colors.grey[400]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedBirthdate != null 
                              ? '${selectedBirthdate!.day.toString().padLeft(2, '0')}.${selectedBirthdate!.month.toString().padLeft(2, '0')}.${selectedBirthdate!.year}'
                              : 'Geburtsdatum',
                            style: TextStyle(
                              color: selectedBirthdate != null ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),

                Spacer(),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _createProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Profil erstellen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 20),

                // Hinweis
                Center(
                  child: Text(
                    'Du kannst dein Profil später in den Einstellungen ändern',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBirthdatePicker() {
    showDialog(
      context: context,
      builder: (context) {
        DateTime tempDate = selectedBirthdate ?? DateTime(2000);
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: tempDate,
                    minimumDate: DateTime(1920),
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (date) => tempDate = date,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => selectedBirthdate = tempDate);
                    Navigator.pop(context);
                  },
                  child: const Text('Übernehmen'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createProfile() async {
    // Validation
    String name = nameController.text.trim();
    String username = usernameController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      _showError('Bitte alle Felder ausfüllen');
      return;
    }

    // Geburtsdatum-Validierung hinzufügen
    if (selectedBirthdate == null) {
      _showError('Bitte Geburtsdatum auswählen');
      return;
    }

    // Username-Validierung mit korrektem RegExp Pattern
    if (username.length < 3) {
      _showError('Username muss mindestens 3 Zeichen haben');
      return;
    }

    // Prüfe ob Username Leerzeichen enthält
    if (username.contains(' ')) {
      _showError('Username darf keine Leerzeichen enthalten');
      return;
    }

    // Prüfe ob Username nur Buchstaben, Zahlen, Punkte und Unterstriche enthält
    RegExp validUsername = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validUsername.hasMatch(username)) {
      _showError(
        'Username darf nur Buchstaben, Zahlen, Punkte und Unterstriche enthalten',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Username-Verfügbarkeitsprüfung
      DatabaseService dbService = DatabaseService(uid: widget.uid);
      bool isAvailable = await dbService.isUsernameAvailable(username);
      if (!isAvailable) {
        _showError('Dieser Username ist bereits vergeben');
        setState(() => isLoading = false);
        return;
      }

      // Profil in Firestore erstellen
      await DatabaseService(uid: widget.uid).updateUserData(
        name,
        '',
        username: username,
        birthdate: selectedBirthdate!.toIso8601String(), // ! weil jetzt immer gesetzt
      );

      // Zurück zur App - Wrapper wird automatisch zur startseite wechseln
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError('Fehler beim Erstellen des Profils');
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }
}
