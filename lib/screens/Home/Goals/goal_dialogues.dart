import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Services/database.dart';
import 'goal_data.dart';

class GoalDialogs {
  // Ziel hinzufügen Dialog
  static void showAddGoalDialog(BuildContext context, Function() onGoalAdded) {
    String? selectedArt;
    String name = '';
    double gewichtWert = 70.0;
    double trainingsWert = 3.0;
    double schritteWert = 10000.0;
    DateTime eventDatum = DateTime.now().add(Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              'Ziel hinzufügen',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown für Zieltyp
                _buildDropdown(context, selectedArt, (value) {
                  setState(() => selectedArt = value);
                }),
                SizedBox(height: 20),

                // Felder basierend auf Zieltyp
                if (selectedArt == 'Event') ...[
                  _buildTextField(
                    context,
                    'Name des Events',
                    name,
                    (value) => name = value,
                  ),
                  SizedBox(height: 20),
                  _buildDatePicker(context, eventDatum, (date) {
                    setState(() => eventDatum = date);
                  }),
                ] else if (selectedArt == 'Gewicht') ...[
                  _buildSlider(
                    context,
                    'Zielgewicht: ${gewichtWert.toInt()} kg',
                    gewichtWert,
                    40.0,
                    150.0,
                    110,
                    (value) {
                      setState(() => gewichtWert = value);
                    },
                  ),
                ] else if (selectedArt == 'Training') ...[
                  _buildSlider(
                    context,
                    'Trainingseinheiten: ${trainingsWert.toInt()}x pro Woche',
                    trainingsWert,
                    1.0,
                    7.0,
                    6,
                    (value) {
                      setState(() => trainingsWert = value);
                    },
                  ),
                ] else if (selectedArt == 'Schritte') ...[
                  _buildSlider(
                    context,
                    'Tägliches Schrittziel: ${_formatNumber(schritteWert.toInt())} Schritte',
                    schritteWert,
                    3000.0,
                    30000.0,
                    27,
                    (value) {
                      setState(() => schritteWert = value);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            _buildActions(context, () async {
              if (_validate(context, selectedArt, name, eventDatum)) {
                await _saveGoal(
                  context,
                  selectedArt!,
                  name,
                  gewichtWert,
                  trainingsWert,
                  schritteWert,
                  eventDatum,
                );
                Navigator.pop(context);
                onGoalAdded();
              }
            }),
          ],
        ),
      ),
    );
  }

  // Ziel bearbeiten Dialog
  static void showEditGoalDialog(
    BuildContext context,
    String goalId,
    Map<String, dynamic> goalData,
    Function() onGoalUpdated,
  ) {
    String selectedArt = goalData['type'];
    String name = goalData['name'] ?? '';
    double gewichtWert = goalData['targetWeight']?.toDouble() ?? 70.0;
    double trainingsWert = goalData['targetTrainings']?.toDouble() ?? 3.0;
    double schritteWert = goalData['targetSteps']?.toDouble() ?? 10000.0;
    DateTime eventDatum = goalData['eventDate'] != null
        ? DateTime.parse(goalData['eventDate'])
        : DateTime.now().add(Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              'Ziel bearbeiten',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gesperrter Zieltyp
                _buildLockedType(context, selectedArt),
                SizedBox(height: 20),

                // Felder basierend auf Zieltyp
                if (selectedArt == 'Event') ...[
                  _buildTextField(
                    context,
                    'Name des Events',
                    name,
                    (value) => name = value,
                  ),
                  SizedBox(height: 20),
                  _buildDatePicker(context, eventDatum, (date) {
                    setState(() => eventDatum = date);
                  }),
                ] else if (selectedArt == 'Gewicht') ...[
                  _buildSlider(
                    context,
                    'Zielgewicht: ${gewichtWert.toInt()} kg',
                    gewichtWert,
                    40.0,
                    150.0,
                    110,
                    (value) {
                      setState(() => gewichtWert = value);
                    },
                  ),
                ] else if (selectedArt == 'Training') ...[
                  _buildSlider(
                    context,
                    'Trainingseinheiten: ${trainingsWert.toInt()}x pro Woche',
                    trainingsWert,
                    1.0,
                    7.0,
                    6,
                    (value) {
                      setState(() => trainingsWert = value);
                    },
                  ),
                ] else if (selectedArt == 'Schritte') ...[
                  _buildSlider(
                    context,
                    'Tägliches Schrittziel: ${_formatNumber(schritteWert.toInt())} Schritte',
                    schritteWert,
                    3000.0,
                    30000.0,
                    27,
                    (value) {
                      setState(() => schritteWert = value);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            _buildActions(context, () async {
              if (_validate(context, selectedArt, name, eventDatum)) {
                await _updateGoal(
                  context,
                  goalId,
                  selectedArt,
                  name,
                  gewichtWert,
                  trainingsWert,
                  schritteWert,
                  eventDatum,
                );
                Navigator.pop(context);
                onGoalUpdated();
              }
            }),
          ],
        ),
      ),
    );
  }

  // Ziel löschen Dialog hinzufügen
  static void showDeleteGoalDialog(
    BuildContext context,
    String goalId,
    String goalName,
    Function() onGoalDeleted,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text('Ziel löschen', style: TextStyle(color: Colors.white)),
        content: Text(
          'Möchtest du "$goalName" wirklich löschen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteGoal(context, goalId, onGoalDeleted);
            },
            child: Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Ziel in Firebase speichern
  static Future<void> _saveGoal(
    BuildContext context,
    String type,
    String name,
    double weight,
    double trainings,
    double steps,
    DateTime eventDate,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> goalData = {'type': type, 'name': name};

      // Typspezifische Daten hinzufügen
      switch (type) {
        case 'Event':
          goalData['eventDate'] = eventDate.toIso8601String();
          break;
        case 'Gewicht':
          goalData['targetWeight'] = weight;
          break;
        case 'Training':
          goalData['targetTrainings'] = trainings;
          break;
        case 'Schritte':
          goalData['targetSteps'] = steps;
          break;
      }

      await DatabaseService(uid: user.uid).addGoal(goalData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ziel erfolgreich erstellt!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Ziel in Firebase aktualisieren
  static Future<void> _updateGoal(
    BuildContext context,
    String goalId,
    String type,
    String name,
    double weight,
    double trainings,
    double steps,
    DateTime eventDate,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> goalData = {'type': type, 'name': name};

      // Typspezifische Daten hinzufügen
      switch (type) {
        case 'Event':
          goalData['eventDate'] = eventDate.toIso8601String();
          break;
        case 'Gewicht':
          goalData['targetWeight'] = weight;
          break;
        case 'Training':
          goalData['targetTrainings'] = trainings;
          break;
        case 'Schritte':
          goalData['targetSteps'] = steps;
          break;
      }

      await DatabaseService(uid: user.uid).updateGoal(goalId, goalData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ziel erfolgreich aktualisiert!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Aktualisieren: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Ziel löschen
  static Future<void> _deleteGoal(
    BuildContext context,
    String goalId,
    Function() onGoalDeleted,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await DatabaseService(uid: user.uid).deleteGoal(goalId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ziel erfolgreich gelöscht!'),
          backgroundColor: Colors.green,
        ),
      );

      onGoalDeleted();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UI Komponenten
  static Widget _buildDropdown(
    BuildContext context,
    String? selectedArt,
    Function(String?) onChanged,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.5),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: DropdownButtonFormField<String>(
          value: selectedArt,
          decoration: InputDecoration(
            labelText: 'Art des Ziels',
            labelStyle: TextStyle(color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18.5),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
          style: TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          items: goalTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: TextStyle(color: Colors.white)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Widget _buildTextField(
    BuildContext context,
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white30),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white,
              width: 2,
            ), // Blau → Weiß
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  static Widget _buildDatePicker(
    BuildContext context,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: TextButton(
        onPressed: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  surface: Theme.of(context).colorScheme.surfaceContainer,
                  onSurface: Colors.white,
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd.MM.yyyy').format(date),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Icon(Icons.calendar_today, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    int divisions,
    Function(double) onChanged,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 4,
            valueIndicatorColor: Theme.of(context).colorScheme.primary,
            valueIndicatorTextStyle: TextStyle(color: Colors.white),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            label: value.round().toString(),
          ),
        ),
      ],
    );
  }

  static Widget _buildLockedType(BuildContext context, String type) {
    return Container(
      width: 280,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.white30, size: 20),
          SizedBox(width: 8),
          Text(type, style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  static Widget _buildActions(BuildContext context, VoidCallback onSave) {
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.5),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.5),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    'Abbrechen',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: TextButton(
                onPressed: onSave,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Speichern',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _extractValues(
    Map<String, String> goal,
    String type,
    Function(String, double, double, double, DateTime) callback,
  ) {
    String name = '';
    double gewicht = 70.0;
    double training = 3.0;
    double schritte = 10000.0;
    DateTime datum = DateTime.now().add(Duration(days: 30));

    String goalName = goal['name']!;

    switch (type) {
      case 'Event':
        if (goalName.contains('(')) {
          name = goalName.split(' (')[0].trim();
          try {
            String dateStr = goalName.split('(')[1].split(')')[0];
            datum = DateFormat('dd/MM/yyyy').parse(dateStr);
          } catch (e) {}
        }
        break;
      case 'Gewicht':
        RegExp regExp = RegExp(r'(\d+)\s*kg');
        var match = regExp.firstMatch(goalName);
        if (match != null) gewicht = double.tryParse(match.group(1)!) ?? 70.0;
        break;
      case 'Training':
        RegExp regExp = RegExp(r'(\d+)x');
        var match = regExp.firstMatch(goalName);
        if (match != null) training = double.tryParse(match.group(1)!) ?? 3.0;
        break;
      case 'Schritte':
        RegExp regExp = RegExp(r'([\d.]+)\s*Schritte');
        var match = regExp.firstMatch(goalName);
        if (match != null) {
          String numberStr = match.group(1)!.replaceAll('.', '');
          schritte = double.tryParse(numberStr) ?? 10000.0;
        }
        break;
    }

    callback(name, gewicht, training, schritte, datum);
  }

  static bool _validate(
    BuildContext context,
    String? type,
    String name,
    DateTime date,
  ) {
    if (type == null) return false;

    if (type == 'Event') {
      if (name.isEmpty) {
        _showError(context, 'Bitte geben Sie einen Event-Namen ein.');
        return false;
      }
      if (date.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
        _showError(
          context,
          'Das Event-Datum muss heute oder in der Zukunft liegen.',
        );
        return false;
      }
    }
    return true;
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  static String _createGoalName(
    String type,
    String name,
    double gewicht,
    double training,
    double schritte,
    DateTime datum,
  ) {
    switch (type) {
      case 'Gewicht':
        return 'Zielgewicht ${gewicht.toInt()} kg';
      case 'Training':
        return '${training.toInt()}x Training pro Woche';
      case 'Schritte':
        return '${_formatNumber(schritte.toInt())} Schritte täglich';
      case 'Event':
        return '$name (${DateFormat('dd/MM/yyyy').format(datum)})';
      default:
        return '';
    }
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}
