import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streax/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/shared/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';

const List<String> goalTypes = ['Gewicht', 'Training', 'Event'];

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
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Zieltyp',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      items: goalTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    if (selectedType == 'Event') ...[
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Event Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => selectedEventDate = picked);
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Datum auswählen',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
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
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (_) => Container(
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
                                      onSelectedItemChanged: (i) => setState(
                                          () => targetWeightController.text = (i + 40).toString()),
                                      children: List.generate(
                                        161,
                                        (i) => Center(
                                          child: Text('${i + 40} kg',
                                              style: const TextStyle(color: Colors.white, fontSize: 18)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Fertig', style: TextStyle(color: Colors.blue)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: targetWeightController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Zielgewicht (kg)',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Training') ...[
                      const Text('Trainings pro Woche', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: zielTrainings.toDouble(),
                              min: 1,
                              max: 7,
                              divisions: 6,
                              activeColor: Theme.of(context).colorScheme.primary,
                              inactiveColor:
                                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                              onChanged: (v) => setState(() => zielTrainings = v.round()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('$zielTrainings x',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
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
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                        ),
                        onPressed: isValid()
                            ? () async {
                                final u = FirebaseAuth.instance.currentUser;
                                if (u == null) return;
                                final goalData = <String, dynamic>{
                                  'type': selectedType,
                                  'createdAt': FieldValue.serverTimestamp(),
                                };
                                switch (selectedType) {
                                  case 'Event':
                                    if (nameController.text.trim().isEmpty ||
                                        selectedEventDate == null) {
                                      SnackBarUtils.showError(
                                          context, 'Bitte Name und Datum eingeben');
                                      return;
                                    }
                                    goalData['name'] = nameController.text.trim();
                                    goalData['eventDate'] = selectedEventDate!.toIso8601String();
                                  case 'Gewicht':
                                    final w = double.tryParse(targetWeightController.text);
                                    if (w == null || w <= 0) {
                                      SnackBarUtils.showError(
                                          context, 'Bitte gültiges Gewicht eingeben');
                                      return;
                                    }
                                    goalData['targetWeight'] = w;
                                  case 'Training':
                                    if (zielTrainings <= 0) {
                                      SnackBarUtils.showError(
                                          context, 'Bitte gültige Anzahl eingeben');
                                      return;
                                    }
                                    goalData['targetTrainings'] = zielTrainings;
                                }
                                try {
                                  await DatabaseService(uid: u.uid).addGoal(goalData);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    SnackBarUtils.showSuccess(
                                        context, 'Ziel erfolgreich hinzugefügt');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackBarUtils.showError(context, 'Fehler beim Hinzufügen: $e');
                                  }
                                }
                              }
                            : null,
                        child: const Text('Hinzufügen',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final nameController = TextEditingController(text: data['name'] ?? '');
    final targetWeightController =
        TextEditingController(text: data['targetWeight']?.toString() ?? '');
    DateTime? selectedEventDate =
        data['eventDate'] != null ? DateTime.tryParse(data['eventDate']) : null;
    int zielTrainings = (data['targetTrainings'] as num?)?.toInt() ?? 3;

    bool isValid() {
      switch (selectedType) {
        case 'Event':
          return nameController.text.trim().isNotEmpty && selectedEventDate != null;
        case 'Gewicht':
          final w = double.tryParse(targetWeightController.text);
          return w != null && w > 0;
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
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Zieltyp',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      items: goalTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    if (selectedType == 'Event') ...[
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                selectedEventDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => selectedEventDate = picked);
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Datum auswählen',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
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
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (_) => Container(
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
                                      onSelectedItemChanged: (i) => setState(
                                          () => targetWeightController.text = (i + 40).toString()),
                                      children: List.generate(
                                        161,
                                        (i) => Center(
                                          child: Text('${i + 40} kg',
                                              style: const TextStyle(color: Colors.white, fontSize: 18)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Fertig', style: TextStyle(color: Colors.blue)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: targetWeightController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Zielgewicht (kg)',
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (selectedType == 'Training') ...[
                      const Text('Trainings pro Woche', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: zielTrainings.toDouble(),
                              min: 1,
                              max: 7,
                              divisions: 6,
                              activeColor: Theme.of(context).colorScheme.primary,
                              inactiveColor:
                                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                              onChanged: (v) => setState(() => zielTrainings = v.round()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('$zielTrainings x',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
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
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                        ),
                        onPressed: isValid()
                            ? () async {
                                final u = FirebaseAuth.instance.currentUser;
                                if (u == null) return;
                                final goalData = <String, dynamic>{
                                  'type': selectedType,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };
                                switch (selectedType) {
                                  case 'Event':
                                    if (nameController.text.trim().isEmpty ||
                                        selectedEventDate == null) {
                                      SnackBarUtils.showError(
                                          context, 'Bitte Name und Datum eingeben');
                                      return;
                                    }
                                    goalData['name'] = nameController.text.trim();
                                    goalData['eventDate'] = selectedEventDate!.toIso8601String();
                                  case 'Gewicht':
                                    final w = double.tryParse(targetWeightController.text);
                                    if (w == null || w <= 0) {
                                      SnackBarUtils.showError(
                                          context, 'Bitte gültiges Gewicht eingeben');
                                      return;
                                    }
                                    goalData['targetWeight'] = w;
                                  case 'Training':
                                    if (zielTrainings <= 0) {
                                      SnackBarUtils.showError(
                                          context, 'Bitte gültige Anzahl eingeben');
                                      return;
                                    }
                                    goalData['targetTrainings'] = zielTrainings;
                                }
                                try {
                                  await DatabaseService(uid: u.uid).updateGoal(goal.id, goalData);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    SnackBarUtils.showSuccess(
                                        context, 'Ziel erfolgreich aktualisiert');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackBarUtils.showError(
                                        context, 'Fehler beim Aktualisieren: $e');
                                  }
                                }
                              }
                            : null,
                        child: const Text('Speichern',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
