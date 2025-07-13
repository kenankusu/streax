import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:streax/Screens/Shared/user.dart';
import 'package:streax/Services/database.dart';

const List<String> goalTypes = [
  'Gewicht',
  'Training',
  'Schritte',
  'Event',
];

class Goal {
  final String type;
  final String name;

  Goal({required this.type, required this.name});

  Map<String, String> toMap() {
    return {'type': type, 'name': name};
  }

  static Goal fromMap(Map<String, String> map) {
    return Goal(type: map['type']!, name: map['name']!);
  }
}

class GoalDialogs {
  static Future<void> showAddGoalDialog(BuildContext context) async {
    String selectedType = goalTypes.first;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController targetWeightController = TextEditingController();
    final TextEditingController targetTrainingsController = TextEditingController();
    final TextEditingController targetStepsController = TextEditingController();
    DateTime? selectedEventDate;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              title: Text(
                'Neues Ziel hinzufügen',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Event Datum',
                          style: TextStyle(color: Colors.white70),
                        ),
                        subtitle: Text(
                          selectedEventDate != null
                              ? '${selectedEventDate!.day}.${selectedEventDate!.month}.${selectedEventDate!.year}'
                              : 'Datum auswählen',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: Icon(Icons.calendar_today, color: Colors.white70),
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
                      ),
                    ] else if (selectedType == 'Gewicht') ...[
                      TextField(
                        controller: targetWeightController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Zielgewicht (kg)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Training') ...[
                      TextField(
                        controller: targetTrainingsController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Trainings pro Woche',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Schritte') ...[
                      TextField(
                        controller: targetStepsController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Schritte pro Tag',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text('Hinzufügen', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    final user = Provider.of<StreaxUser?>(context, listen: false);
                    if (user != null) {
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte Name und Datum eingeben')),
                            );
                            return;
                          }
                          break;
                        case 'Gewicht':
                          final weight = double.tryParse(targetWeightController.text);
                          if (weight != null && weight > 0) {
                            goalData['targetWeight'] = weight;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte gültiges Gewicht eingeben')),
                            );
                            return;
                          }
                          break;
                        case 'Training':
                          final trainings = int.tryParse(targetTrainingsController.text);
                          if (trainings != null && trainings > 0) {
                            goalData['targetTrainings'] = trainings;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte gültige Anzahl eingeben')),
                            );
                            return;
                          }
                          break;
                        case 'Schritte':
                          final steps = int.tryParse(targetStepsController.text);
                          if (steps != null && steps > 0) {
                            goalData['targetSteps'] = steps;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte gültige Schrittzahl eingeben')),
                            );
                            return;
                          }
                          break;
                      }

                      try {
                        await DatabaseService(uid: user.uid).addGoal(goalData);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ziel erfolgreich hinzugefügt'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Hinzufügen: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
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
    final TextEditingController targetTrainingsController = TextEditingController(
      text: data['targetTrainings']?.toString() ?? ''
    );
    final TextEditingController targetStepsController = TextEditingController(
      text: data['targetSteps']?.toString() ?? ''
    );
    DateTime? selectedEventDate = data['eventDate'] != null 
        ? DateTime.tryParse(data['eventDate']) 
        : null;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              title: Text(
                'Ziel bearbeiten',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Event Datum',
                          style: TextStyle(color: Colors.white70),
                        ),
                        subtitle: Text(
                          selectedEventDate != null
                              ? '${selectedEventDate!.day}.${selectedEventDate!.month}.${selectedEventDate!.year}'
                              : 'Datum auswählen',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: Icon(Icons.calendar_today, color: Colors.white70),
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
                      ),
                    ] else if (selectedType == 'Gewicht') ...[
                      TextField(
                        controller: targetWeightController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Zielgewicht (kg)',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Training') ...[
                      TextField(
                        controller: targetTrainingsController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Trainings pro Woche',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Schritte') ...[
                      TextField(
                        controller: targetStepsController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Schritte pro Tag',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text('Speichern', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    final user = Provider.of<StreaxUser?>(context, listen: false);
                    if (user != null) {
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte Name und Datum eingeben')),
                            );
                            return;
                          }
                          break;
                        case 'Gewicht':
                          final weight = double.tryParse(targetWeightController.text);
                          if (weight != null && weight > 0) {
                            goalData['targetWeight'] = weight;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte gültiges Gewicht eingeben')),
                            );
                            return;
                          }
                          break;
                        case 'Training':
                          final trainings = int.tryParse(targetTrainingsController.text);
                          if (trainings != null && trainings > 0) {
                            goalData['targetTrainings'] = trainings;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte gültige Anzahl eingeben')),
                            );
                            return;
                          }
                          break;
                        case 'Schritte':
                          final steps = int.tryParse(targetStepsController.text);
                          if (steps != null && steps > 0) {
                            goalData['targetSteps'] = steps;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bitte gültige Schrittzahl eingeben')),
                            );
                            return;
                          }
                          break;
                      }

                      try {
                        await DatabaseService(uid: user.uid).updateGoal(goal.id, goalData);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ziel erfolgreich aktualisiert'),
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
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}