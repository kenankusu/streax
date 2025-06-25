import 'package:flutter/material.dart';

// Einträge werden nach Wochentag-Index gespeichert (0=Mo, 6=So)
final Map<int, Map<String, String>> eintraege = {};

final Map<String, String> optionIconMap = {
  'Rest': 'assets/icons/journal/rest.png',
  'Fitnessstudio': 'assets/icons/journal/gym.png',
  'Tischtennis': 'assets/icons/journal/tt.png',
  'Boxen': 'assets/icons/journal/boxen.png',
};

class journal extends StatefulWidget {
  const journal({super.key});
  @override
  State<journal> createState() => _JournalState();
}

class _JournalState extends State<journal> {
  final List<String> wochentage = ["MO", "DI", "MI", "DO", "FR", "SA", "SO"];

  @override
  Widget build(BuildContext context) {
    int today = DateTime.now().weekday - 1; // 0=Mo, 6=So

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: wochentage.asMap().entries.map((entry) {
        int idx = entry.key;
        String tag = entry.value;
        final eintrag = eintraege[idx];
        bool hasEntry = eintrag != null && eintrag['option'] != null && eintrag['option'] != '';
        String? option = eintrag?['option'];

        // Farben bestimmen
        Color borderColor;
        if (hasEntry) {
          borderColor = Theme.of(context).colorScheme.primary;
        } else {
          borderColor = const Color.fromARGB(255, 75, 73, 73); // Standard grau
        }

        String? iconPath;
        if (idx < today) {
          iconPath = optionIconMap[option];
        } else if (idx == today && hasEntry) {
          iconPath = optionIconMap[option];
        } else {
          iconPath = null;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Column(
            children: [
              // Tagesbezeichnung über der Box
              Text(
                tag,
                style: TextStyle(
                  color: idx == today ? Theme.of(context).colorScheme.primary : Colors.white,
                  fontSize: 16,
                  fontWeight: idx == today ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: hasEntry
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color.fromARGB(255, 75, 73, 73),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    eintrag['option'] ?? '',
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                  tooltip: 'Bearbeiten',
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    showJournalContextMenu(
                                      context,
                                      () => setState(() {}),
                                      tagIndex: idx,
                                      initialOption: eintrag['option'],
                                      initialText: eintrag['text'],
                                      isEdit: true,
                                    );
                                  },
                                ),
                              ],
                            ),
                            content: Text(
                              eintrag['text'] ?? '',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                child: Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: borderColor,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: iconPath != null
                        ? Image.asset(
                            iconPath,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          )
                        : SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Kontextmenü-Funktion zum Erstellen eines Eintrags
Future<void> showJournalContextMenu(
  BuildContext context,
  VoidCallback refresh, {
  int? tagIndex, // Index des zu bearbeitenden Tages, null = heute
  String? initialOption,
  String? initialText,
  bool isEdit = false,
}) async {
  String? selectedOption = initialOption;
  String inputText = initialText ?? '';
  int index = tagIndex ?? DateTime.now().weekday - 1;

  // Nur beim Erstellen prüfen, ob schon ein Eintrag existiert:
  if (!isEdit && eintraege[index] != null) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 75, 73, 73),
        title: Text('Hinweis', style: TextStyle(color: Colors.white)),
        content: Text('Für heute existiert bereits ein Eintrag.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
    return;
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 75, 73, 73),
            title: Text('Sportart auswählen', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...[
                    'Rest',
                    'Fitnessstudio',
                    'Tischtennis',
                    'Boxen',
                  ].map((option) => RadioListTile<String>(
                        activeColor: Theme.of(context).colorScheme.primary,
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                          (states) => states.contains(WidgetState.selected) ? Theme.of(context).colorScheme.primary : Colors.white,
                        ),
                        visualDensity: VisualDensity.compact,
                        title: Text(option, style: TextStyle(color: Colors.white)),
                        value: option,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value;
                          });
                        },
                      )),
                  TextField(
                    controller: TextEditingController(text: inputText),
                    decoration: InputDecoration(
                      labelText: 'Beschreibe dein heutiges Training..',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    onChanged: (value) {
                      inputText = value;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Abbrechen', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: (selectedOption == null || selectedOption!.isEmpty)
                    ? null
                    : () {
                        eintraege[index] = {
                          'option': ?selectedOption,
                          'text': inputText,
                        };
                        refresh();
                        Navigator.of(context).pop();
                      },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}

