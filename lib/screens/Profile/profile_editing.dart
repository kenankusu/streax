import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:streax/services/database.dart';
import '../../utils/snackbar.dart';

class EditProfileDialog {
  // Hilfsfunktion für Picker-Inhalte
  static Widget _buildPickerContent(
    String type,
    dynamic currentValue,
    Function(dynamic) onChanged,
  ) {
    switch (type) {
      case 'weight':
        return CupertinoPicker(
          backgroundColor: Colors.transparent,
          itemExtent: 40,
          scrollController: FixedExtentScrollController(
            initialItem: (currentValue as String).isNotEmpty
                ? int.parse(currentValue) - 30
                : 40,
          ),
          onSelectedItemChanged: (index) => onChanged((index + 30).toString()),
          children: List.generate(
            171,
            (i) => Center(
              child: Text(
                '${i + 30} kg',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        );

      case 'height':
        return CupertinoPicker(
          backgroundColor: Colors.transparent,
          itemExtent: 40,
          scrollController: FixedExtentScrollController(
            initialItem: (currentValue as String).isNotEmpty
                ? int.parse(currentValue) - 140
                : 35,
          ),
          onSelectedItemChanged: (index) => onChanged((index + 140).toString()),
          children: List.generate(
            81,
            (i) => Center(
              child: Text(
                '${i + 140} cm',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        );

      case 'birthdate':
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: currentValue ?? DateTime(2000),
          minimumDate: DateTime(1920),
          maximumDate: DateTime.now(),
          onDateTimeChanged: onChanged,
        );

      default:
        return Container();
    }
  }

  // Dialog zum Bearbeiten des Profils
  static Future<void> show(
    BuildContext context,
    String uid,
    Map<String, dynamic> currentData,
  ) async {
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

    DateTime? selectedBirthdate = currentData['birthdate'] != null
        ? DateTime.tryParse(currentData['birthdate'])
        : null;
    String selectedGender = currentData['gender'] ?? 'Männlich';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Profil bearbeiten',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(firstNameController, 'Vorname'),
                _buildTextField(lastNameController, 'Nachname'),
                _buildTextField(usernameController, 'Username'),

                // Gewicht Picker
                _buildPickerField(
                  context,
                  weightController,
                  'Gewicht (kg)',
                  'weight',
                  setState,
                ),

                // Größe Picker
                _buildPickerField(
                  context,
                  heightController,
                  'Größe (cm)',
                  'height',
                  setState,
                ),

                // Geburtsdatum Picker
                GestureDetector(
                  onTap: () => _showPicker(
                    context,
                    'birthdate',
                    selectedBirthdate,
                    (value) => setState(() => selectedBirthdate = value),
                  ),
                  child: AbsorbPointer(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: selectedBirthdate != null
                            ? '${selectedBirthdate!.day.toString().padLeft(2, '0')}.${selectedBirthdate!.month.toString().padLeft(2, '0')}.${selectedBirthdate!.year}'
                            : 'Geburtstag',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Pflichtfeld',
                      ),
                    ),
                  ),
                ),

                // Geschlecht Dropdown
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  style: TextStyle(color: Colors.white),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: InputDecoration(labelText: 'Geschlecht'),
                  items: ['Männlich', 'Weiblich', 'Divers']
                      .map(
                        (e) =>
                            DropdownMenuItem<String>(value: e, child: Text(e)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedGender = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                if (await _saveProfile(
                  context,
                  uid,
                  firstNameController.text,
                  lastNameController.text,
                  usernameController.text,
                  weightController.text,
                  heightController.text,
                  selectedGender,
                  selectedBirthdate,
                )) {
                  Navigator.pop(context);
                }
              },
              child: Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  // Hilfsfunktionen
  static Widget _buildTextField(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  static Widget _buildPickerField(
    BuildContext context,
    TextEditingController controller,
    String label,
    String type,
    StateSetter setState,
  ) {
    return GestureDetector(
      onTap: () => _showPicker(
        context,
        type,
        controller.text,
        (value) => setState(() => controller.text = value),
      ),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  static void _showPicker(
    BuildContext context,
    String type,
    dynamic currentValue,
    Function(dynamic) onSelected,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: Colors.grey[900],
        child: Column(
          children: [
            Expanded(
              child: _buildPickerContent(type, currentValue, onSelected),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fertig', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool> _saveProfile(
    BuildContext context,
    String uid,
    String firstName,
    String lastName,
    String username,
    String weight,
    String height,
    String gender,
    DateTime? birthdate,
  ) async {
    // Basisvalidierung
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        birthdate == null) {
      SnackBarUtils.showError(context, 'Bitte alle Pflichtfelder ausfüllen');
      return false;
    }

    // Usernamevalidierung
    String newUsername = username.trim();

    // Mindestlänge
    if (newUsername.length < 3) {
      SnackBarUtils.showError(
        context,
        'Username muss mindestens 3 Zeichen haben',
      );
      return false;
    }

    // Keine Leerzeichen
    if (newUsername.contains(' ')) {
      SnackBarUtils.showError(
        context,
        'Username darf keine Leerzeichen enthalten',
      );
      return false;
    }

    // Erlaubte Zeichen
    RegExp validUsername = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validUsername.hasMatch(newUsername)) {
      SnackBarUtils.showError(
        context,
        'Username darf nur Buchstaben, Zahlen, Punkte und Unterstriche enthalten',
      );
      return false;
    }

    // Verfügbarkeitsprüfung, mit Ausnahme des eigenen Usernames
    DatabaseService dbService = DatabaseService(uid: uid);
    bool isAvailable = await dbService.isUsernameAvailable(
      newUsername,
      excludeUid: uid,
    );
    if (!isAvailable) {
      SnackBarUtils.showError(context, 'Dieser Username ist bereits vergeben');
      return false;
    }

    // Speichern wenn alle Validierungen bestanden
    try {
      await dbService.updateUserData(
        firstName.trim(),
        lastName.trim(),
        username: newUsername,
        weight: double.tryParse(weight),
        height: int.tryParse(height),
        gender: gender,
        birthdate: birthdate.toIso8601String(),
      );
      return true;
    } catch (e) {
      SnackBarUtils.showError(context, 'Fehler beim Speichern: $e');
      return false;
    }
  }
}
