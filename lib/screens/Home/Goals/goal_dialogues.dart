import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streax/Services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/Screens/Shared/snackbar.dart';
import 'package:flutter/cupertino.dart';

const List<String> goalTypes = [
  'Gewicht',
  'Training',
  'Event',
];

class GoalDialogs {
  static Future<void> showAddGoalDialog(BuildContext context) async {
    String selectedType = goalTypes.first;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController targetWeightController = TextEditingController();
    DateTime? selectedEventDate;
    int zielTrainings = 3;

    bool isValid() {
      switch (selectedType) {
        case 'Event':
          return nameController.text.trim().isNotEmpty && selectedEventDate != null;
        case 'Gewicht':
          final weight = double.tryParse(targetWeightController.text);
          return weight != null && weight > 0;
        case 'Training':
          return zielTrainings > 0;
        default:
          return false;
      }
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Zieltyp',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      items: goalTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedType = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    if (selectedType == 'Event') ...[
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Event Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedEventDate = picked;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Datum auswählen',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              suffixIcon: Icon(Icons.calendar_today, color: Colors.white70),
                            ),
                            controller: TextEditingController(
                              text: selectedEventDate != null
                                  ? '${selectedEventDate!.day}.${selectedEventDate!.month}.${selectedEventDate!.year}'
                                  : '',
                            ),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Gewicht') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => Container(
                                  height: 250,
                                  color: Colors.grey[900],
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: CupertinoPicker(
                                          backgroundColor: Colors.transparent,
                                          itemExtent: 40,
                                          scrollController: FixedExtentScrollController(
                                            initialItem: targetWeightController.text.isNotEmpty
                                                ? int.parse(targetWeightController.text) - 40
                                                : 30,
                                          ),
                                          onSelectedItemChanged: (index) {
                                            setState(() {
                                              targetWeightController.text = (index + 40).toString();
                                            });
                                          },
                                          children: List.generate(
                                            161,
                                            (i) => Center(
                                              child: Text(
                                                '${i + 40} kg',
                                                style: TextStyle(color: Colors.white, fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Fertig', style: TextStyle(color: Colors.blue)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: targetWeightController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Zielgewicht (kg)',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white30),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (selectedType == 'Training') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trainings pro Woche',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: zielTrainings.toDouble(),
                                  min: 1,
                                  max: 7,
                                  divisions: 6,
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  inactiveColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  onChanged: (value) {
                                    setState(() {
                                      zielTrainings = value.round();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                '$zielTrainings x',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        backgroundColor: Colors.transparent,
                        side: BorderSide.none,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: isValid()
                            ? () async {
                                final firebaseUser = FirebaseAuth.instance.currentUser;
                                if (firebaseUser != null) {
                                  Map<String, dynamic> goalData = {
                                    'type': selectedType,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };

                                  switch (selectedType) {
                                    case 'Event':
                                      if (nameController.text.trim().isNotEmpty && selectedEventDate != null) {
                                        goalData['name'] = nameController.text.trim();
                                        goalData['eventDate'] = selectedEventDate!.toIso8601String();
                                      } else {
                                        SnackBarUtils.showError(context, 'Bitte Name und Datum eingeben');
                                        return;
                                      }
                                      break;
                                    case 'Gewicht':
                                      final weight = double.tryParse(targetWeightController.text);
                                      if (weight != null && weight > 0) {
                                        goalData['targetWeight'] = weight;
                                      } else {
                                        SnackBarUtils.showError(context, 'Bitte gültiges Gewicht eingeben');
                                        return;
                                      }
                                      break;
                                    case 'Training':
                                      if (zielTrainings > 0) {
                                        goalData['targetTrainings'] = zielTrainings;
                                      } else {
                                        SnackBarUtils.showError(context, 'Bitte gültige Anzahl eingeben');
                                        return;
                                      }
                                      break;
                                  }

                                  try {
                                    await DatabaseService(uid: firebaseUser.uid).addGoal(goalData);
                                    Navigator.of(context).pop();
                                    SnackBarUtils.showSuccess(context, 'Ziel erfolgreich hinzugefügt');
                                  } catch (e) {
                                    SnackBarUtils.showError(context, 'Fehler beim Hinzufügen: $e');
                                  }
                                }
                              }
                            : null,
                        child: Text(
                          'Hinzufügen',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> showEditGoalDialog(BuildContext context, DocumentSnapshot goal) async {
    final data = goal.data() as Map<String, dynamic>;
    String selectedType = data['type'] ?? goalTypes.first;
    final TextEditingController nameController = TextEditingController(text: data['name'] ?? '');
    final TextEditingController targetWeightController = TextEditingController(
      text: data['targetWeight']?.toString() ?? ''
    );
    DateTime? selectedEventDate = data['eventDate'] != null 
        ? DateTime.tryParse(data['eventDate']) 
        : null;
    int zielTrainings = data['targetTrainings'] ?? 3;

    bool isValid() {
      switch (selectedType) {
        case 'Event':
          return nameController.text.trim().isNotEmpty && selectedEventDate != null;
        case 'Gewicht':
          final weight = double.tryParse(targetWeightController.text);
          return weight != null && weight > 0;
        case 'Training':
          return zielTrainings > 0;
        default:
          return false;
      }
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Zieltyp',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      items: goalTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedType = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    if (selectedType == 'Event') ...[
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEventDate ?? DateTime.now().add(Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedEventDate = picked;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Datum auswählen',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              suffixIcon: Icon(Icons.calendar_today, color: Colors.white70),
                            ),
                            controller: TextEditingController(
                              text: selectedEventDate != null
                                  ? '${selectedEventDate!.day}.${selectedEventDate!.month}.${selectedEventDate!.year}'
                                  : '',
                            ),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Gewicht') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) => Container(
                                  height: 250,
                                  color: Colors.grey[900],
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: CupertinoPicker(
                                          backgroundColor: Colors.transparent,
                                          itemExtent: 40,
                                          scrollController: FixedExtentScrollController(
                                            initialItem: targetWeightController.text.isNotEmpty
                                                ? int.parse(targetWeightController.text) - 40
                                                : 30,
                                          ),
                                          onSelectedItemChanged: (index) {
                                            setState(() {
                                              targetWeightController.text = (index + 40).toString();
                                            });
                                          },
                                          children: List.generate(
                                            161,
                                            (i) => Center(
                                              child: Text(
                                                '${i + 40} kg',
                                                style: TextStyle(color: Colors.white, fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Fertig', style: TextStyle(color: Colors.blue)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: targetWeightController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Zielgewicht (kg)',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white30),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (selectedType == 'Training') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trainings pro Woche',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: zielTrainings.toDouble(),
                                  min: 1,
                                  max: 7,
                                  divisions: 6,
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  inactiveColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  onChanged: (value) {
                                    setState(() {
                                      zielTrainings = value.round();
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                '$zielTrainings x',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        backgroundColor: Colors.transparent,
                        side: BorderSide.none,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: isValid()
                            ? () async {
                                final firebaseUser = FirebaseAuth.instance.currentUser;
                                if (firebaseUser != null) {
                                  Map<String, dynamic> goalData = {
                                    'type': selectedType,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  };

                                  switch (selectedType) {
                                    case 'Event':
                                      if (nameController.text.trim().isNotEmpty && selectedEventDate != null) {
                                        goalData['name'] = nameController.text.trim();
                                        goalData['eventDate'] = selectedEventDate!.toIso8601String();
                                      } else {
                                        SnackBarUtils.showError(context, 'Bitte Name und Datum eingeben');
                                        return;
                                      }
                                      break;
                                    case 'Gewicht':
                                      final weight = double.tryParse(targetWeightController.text);
                                      if (weight != null && weight > 0) {
                                        goalData['targetWeight'] = weight;
                                      } else {
                                        SnackBarUtils.showError(context, 'Bitte gültiges Gewicht eingeben');
                                        return;
                                      }
                                      break;
                                    case 'Training':
                                      if (zielTrainings > 0) {
                                        goalData['targetTrainings'] = zielTrainings;
                                      } else {
                                        SnackBarUtils.showError(context, 'Bitte gültige Anzahl eingeben');
                                        return;
                                      }
                                      break;
                                  }

                                  try {
                                    await DatabaseService(uid: firebaseUser.uid).updateGoal(goal.id, goalData);
                                    Navigator.of(context).pop();
                                    SnackBarUtils.showSuccess(context, 'Ziel erfolgreich aktualisiert');
                                  } catch (e) {
                                    SnackBarUtils.showError(context, 'Fehler beim Aktualisieren: $e');
                                  }
                                }
                              }
                            : null,
                        child: Text(
                          'Speichern',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}