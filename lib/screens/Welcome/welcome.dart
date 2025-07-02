// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';  // Diesen Import hinzufügen
import 'package:streax/services/database.dart';
import 'package:streax/Screens/splashscreen.dart'; // Für Wrapper-Navigation nach Profilanlage

class WelcomePage extends StatefulWidget {
  final String uid;

  const WelcomePage({required this.uid, super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String? selectedGender;
  //Fragezeichen für Nullable: Werte die, anfangs leer sein dürfen
  final firstNameController = TextEditingController();
  //TextEditingController ermöglicht den Wert des Feldes auszulesen
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  DateTime? selectedBirthdate;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Verhindert Zurück-Navigation
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Begrüßung
                        SizedBox(height: 50),
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/streax-type.png',
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 40),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                                  children: [
                                    TextSpan(text: 'Lass uns '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: Stack(
                                        children: [
                                          Text(
                                            'loslegen',
                                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              decoration: TextDecoration.none,
                                            ),
                                          ), //Unterstrich-Effekt
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 2,
                                            child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Theme.of(context).colorScheme.primary,
                                                    Theme.of(context).colorScheme.secondary,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextSpan(text: '!'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Erstelle jetzt dein Profil, um zu beginnen.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 60),

                        // Form Title
                        Text(
                          'Profil erstellen',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),

                        SizedBox(height: 32),

                        // Vorname Input
                        TextFormField(
                          controller: firstNameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Vorname',
                            labelStyle: TextStyle(color: Colors.white),
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
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Nachname Input
                        TextFormField(
                          controller: lastNameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Nachname',
                            labelStyle: TextStyle(color: Colors.white),
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
                              color: Colors.white,
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
                            labelStyle: TextStyle(color: Colors.white),
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
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Gewicht Input
                        TextFormField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Gewicht (kg)',
                            labelStyle: TextStyle(color: Colors.white),
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
                              Icons.monitor_weight,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Height Input
                        TextFormField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Größe (cm)',
                            labelStyle: TextStyle(color: Colors.white),
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
                              Icons.height,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Gender Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedGender,
                          style: TextStyle(color: Colors.white),
                          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                          decoration: InputDecoration(
                            labelText: 'Geschlecht',
                            labelStyle: TextStyle(color: Colors.white),
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
                            prefixIcon: Icon(Icons.wc, color: Colors.white),
                          ),
                          // Werte und Firestore: 'm', 'w', 'd' -- nur Label ist deutsch
                          items: [
                            DropdownMenuItem(value: 'm', child: Text('Männlich', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'w', child: Text('Weiblich', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'd', child: Text('Divers', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (value) => setState(() => selectedGender = value),
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
                              // Keine rote Umrandung mehr, immer wie die anderen Felder
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
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Button & Note fixed at the bottom
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _createProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                            padding: EdgeInsets.zero,
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
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Du kannst dein Profil später in den Einstellungen bearbeiten.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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
    String vorname = firstNameController.text.trim();
    String nachname = lastNameController.text.trim();
    String username = usernameController.text.trim();

    String weight = weightController.text.trim();
    String height = heightController.text.trim();

    if (vorname.isEmpty || nachname.isEmpty || username.isEmpty || weight.isEmpty || height.isEmpty || selectedGender == null) {
      _showError('Bitte fülle alle Felder aus');
      return;
    }

    // Überprüfung Geburtsdatum
    if (selectedBirthdate == null) {
      _showError('Wähle ein Geburtsdatum aus');
      return;
    }

    // Überprüfung Username auf länge und Zeichen
    if (username.length < 3) {
      _showError('Der Username muss mindestens 3 Zeichen lang sein');
      return;
    }
    if (username.contains(' ')) {
      _showError('Usernames dürfen keine Leerzeichen enthalten');
      return;
    }
    RegExp validUsername = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validUsername.hasMatch(username)) {
      _showError('Username darf nur Buchstaben, Zahlen, Punkte und Unterstriche enthalten');
      return;
    }

    //Überprüfung der Nutzereingabe für Gewicht und Größe
    double? weightValue = double.tryParse(weight);
    double? heightValue = double.tryParse(height);
    if (weightValue == null || weightValue < 20 || weightValue > 400) {
      _showError('Bitte gib ein korrektes Gewicht an (20-400 kg)');
      return;
    }
    if (heightValue == null || heightValue < 80 || heightValue > 250) {
      _showError('Bitte gib eine korrekte Größe an (80-250 cm)');
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
        vorname,
        nachname,
        username: username,
        birthdate: selectedBirthdate!.toIso8601String(),
        weight: weightValue,
        height: heightValue,
        gender: selectedGender,
      );

      // Auth-Status und User-Daten neu laden, damit Provider/Wrapper aktualisiert wird
      // (wichtig für Navigation nach Profilanlage)
      await Future.delayed(const Duration(milliseconds: 300)); // Kurze Pause für Firestore Sync
      // ignore: use_build_context_synchronously
      await Future.delayed(const Duration(milliseconds: 100)); // Doppelt, um Race-Conditions zu vermeiden
      // ignore: use_build_context_synchronously
      await Future.delayed(const Duration(milliseconds: 100)); // Nochmals, falls Firebase langsam ist
      // ignore: use_build_context_synchronously
      // FirebaseAuth reload (optional, falls Email-Status relevant)
      // await FirebaseAuth.instance.currentUser?.reload();

      // Navigation: Wrapper komplett neu laden, damit App-Flow weitergeht
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Wrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Profil-Fehler: $e');
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
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }
}
