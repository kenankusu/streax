import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:streax/services/database.dart';
import '../../utils/snackbar.dart';

class EditProfileDialog {
  // Mappings für Geschlecht
  static String mapGenderToValue(String? input) {
    switch (input?.toLowerCase()) {
      case 'männlich':
      case 'm':
        return 'm';
      case 'weiblich':
      case 'w':
        return 'w';
      case 'divers':
      case 'd':
        return 'd';
      default:
        return 'd';
    }
  }

  static String mapGenderToLabel(String? value) {
    switch (value) {
      case 'm':
        return 'Männlich';
      case 'w':
        return 'Weiblich';
      case 'd':
        return 'Divers';
      default:
        return 'Divers';
    }
  }

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

  static Future<void> show(
    BuildContext context,
    String uid,
    Map<String, dynamic> currentData,
  ) async {
    final firstNameController = TextEditingController(text: currentData['firstName'] ?? '');
    final lastNameController = TextEditingController(text: currentData['lastName'] ?? '');
    final usernameController = TextEditingController(text: currentData['username'] ?? '');
    final weightController = TextEditingController(text: currentData['weight']?.toString() ?? '');
    final heightController = TextEditingController(text: currentData['height']?.toString() ?? '');

    DateTime? selectedBirthdate = currentData['birthdate'] != null
        ? DateTime.tryParse(currentData['birthdate'])
        : null;

    String selectedGender = mapGenderToValue(currentData['gender']);

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

                _buildPickerField(context, weightController, 'Gewicht (kg)', 'weight', setState),
                _buildPickerField(context, heightController, 'Größe (cm)', 'height', setState),

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

                DropdownButtonFormField<String>(
                  value: selectedGender,
                  style: TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[850],
                  decoration: InputDecoration(labelText: 'Geschlecht'),
                  items: [
                    DropdownMenuItem(value: 'm', child: Text(mapGenderToLabel('m'))),
                    DropdownMenuItem(value: 'w', child: Text(mapGenderToLabel('w'))),
                    DropdownMenuItem(value: 'd', child: Text(mapGenderToLabel('d'))),
                  ],
                  onChanged: (value) => setState(() => selectedGender = value!),
                ),

                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTextField(TextEditingController controller, String label) {
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
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        birthdate == null) {
      SnackBarUtils.showError(context, 'Bitte alle Pflichtfelder ausfüllen');
      return false;
    }

    String newUsername = username.trim();

    if (newUsername.length < 3) {
      SnackBarUtils.showError(context, 'Username muss mindestens 3 Zeichen haben');
      return false;
    }

    if (newUsername.contains(' ')) {
      SnackBarUtils.showError(context, 'Username darf keine Leerzeichen enthalten');
      return false;
    }

    RegExp validUsername = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validUsername.hasMatch(newUsername)) {
      SnackBarUtils.showError(
        context,
        'Username darf nur Buchstaben, Zahlen, Punkte und Unterstriche enthalten',
      );
      return false;
    }

    DatabaseService dbService = DatabaseService(uid: uid);
    bool isAvailable = await dbService.isUsernameAvailable(newUsername, excludeUid: uid);
    if (!isAvailable) {
      SnackBarUtils.showError(context, 'Dieser Username ist bereits vergeben');
      return false;
    }

    try {
      await dbService.updateUserData(
        firstName.trim(),
        lastName.trim(),
        username: newUsername,
        weight: double.tryParse(weight) ?? 0.0,
        height: double.tryParse(height) ?? 0.0,
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
