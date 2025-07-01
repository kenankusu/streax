import 'package:flutter/material.dart';
import 'package:streax/services/database.dart';
import '../../utils/snackbar.dart';

// Profil bearbeiten

class EditProfileDialog {
  static void show(
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
        title: const Text('Profil bearbeiten'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Vorname'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Nachname'),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Gewicht (kg)',
                    hintText: 'z.B. 70',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: 'Größe (cm)',
                    hintText: 'z.B. 175',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Geschlecht'),
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
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              final result = await _validateAndSave(
                context,
                uid,
                firstNameController,
                lastNameController,
                usernameController,
                weightController,
                heightController,
                selectedGender,
              );

              if (result) {
                Navigator.pop(context);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  static Future<bool> _validateAndSave(
    BuildContext context,
    String uid,
    TextEditingController firstNameController,
    TextEditingController lastNameController,
    TextEditingController usernameController,
    TextEditingController weightController,
    TextEditingController heightController,
    String selectedGender,
  ) async {
    // Validierung
    if (firstNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Vorname darf nicht leer sein');
      return false;
    }

    if (lastNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Nachname darf nicht leer sein');
      return false;
    }

    if (usernameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Username darf nicht leer sein');
      return false;
    }

    // Username-Validierung mit korrektem RegExp Pattern
    String newUsername = usernameController.text.trim();

    // Prüfe ob Username mindestens 3 Zeichen lang ist
    if (newUsername.length < 3) {
      SnackBarUtils.showError(
        context,
        'Username muss mindestens 3 Zeichen haben',
      );
      return false;
    }

    // Prüfe ob Username Leerzeichen enthält
    if (newUsername.contains(' ')) {
      SnackBarUtils.showError(
        context,
        'Username darf keine Leerzeichen enthalten',
      );
      return false;
    }

    // Prüfe ob Username nur Buchstaben, Zahlen, Punkte und Unterstriche enthält
    RegExp validUsername = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validUsername.hasMatch(newUsername)) {
      SnackBarUtils.showError(
        context,
        'Username darf nur Buchstaben, Zahlen, Punkte und Unterstriche enthalten',
      );
      return false;
    }

    // Username-Verfügbarkeitsprüfung
    DatabaseService dbService = DatabaseService(uid: uid);
    bool isAvailable = await dbService.isUsernameAvailable(newUsername);
    if (!isAvailable) {
      SnackBarUtils.showError(context, 'Dieser Username ist bereits vergeben');
      return false;
    }

    // Gewicht parsen und validieren
    double? weight;
    if (weightController.text.isNotEmpty) {
      weight = double.tryParse(weightController.text);
      if (weight == null || weight <= 0 || weight > 500) {
        SnackBarUtils.showError(
          context,
          'Bitte gültiges Gewicht eingeben (1-500 kg)',
        );
        return false;
      }
    }

    // Größe parsen und validieren
    int? height;
    if (heightController.text.isNotEmpty) {
      height = int.tryParse(heightController.text);
      if (height == null || height <= 0 || height > 300) {
        SnackBarUtils.showError(
          context,
          'Bitte gültige Größe eingeben (1-300 cm)',
        );
        return false;
      }
    }

    try {
      await DatabaseService(uid: uid).updateUserData(
        firstNameController.text.trim(),
        lastNameController.text.trim(),
        username: usernameController.text.trim(),
        weight: weight,
        height: height,
        gender: selectedGender != 'Nicht angegeben' ? selectedGender : null,
      );

      SnackBarUtils.showSuccess(context, 'Profil erfolgreich aktualisiert!');
      return true;
    } catch (e) {
      SnackBarUtils.showError(context, 'Fehler beim Speichern: $e');
      return false;
    }
  }
}
