import 'package:flutter/material.dart';

// Einträge werden nach Wochentag-Index gespeichert (0=Mo, 6=So)
final Map<int, Map<String, String>> eintraege = {};

final Map<String, String> optionIconMap = {
  'Rest': 'assets/icons/journal/rest.png',
  'Fitnessstudio': 'assets/icons/journal/gym.png',
  'Tischtennis': 'assets/icons/journal/tt.png',
  'Boxen': 'assets/icons/journal/boxen.png',
};
final String defaultIconPath = 'assets/icons/journal/fail.png';

String _iconPathForOption(String? option) {
  if (option == null) return defaultIconPath;
  return optionIconMap[option] ?? defaultIconPath;
}

class journal extends StatefulWidget {
  const journal({super.key});

  @override
  State<journal> createState() => _JournalState();
}

class _JournalState extends State<journal> {
  final List<String> wochentage = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];

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


        String? iconPath;
        if (idx < today) {
          iconPath = _iconPathForOption(option);
        } else if (idx == today && hasEntry) {
          iconPath = _iconPathForOption(option);
        } else {
          iconPath = null;
        }

        // Farben bestimmen
        Color bgColor;
        if (idx == today && hasEntry) {
          bgColor = const Color.fromARGB(255, 0, 40, 150); // dunkleres Blau für heute mit Eintrag
        } else if (hasEntry) {
          bgColor = const Color.fromARGB(255, 0, 68, 255); // blau für Tage mit Eintrag
        } else if (idx == today) {
          bgColor = const Color.fromARGB(255, 0, 68, 255); // Standard blau für heute ohne Eintrag
        } else {
          bgColor = const Color.fromARGB(255, 75, 73, 73); // Standard grau
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0), // Abstand zwischen den Blöcken verkleinern
          child: GestureDetector(
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
                              icon: Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Bearbeiten',
                              onPressed: () {
                                Navigator.of(context).pop(); // Dialog schließen
                                showJournalContextMenu(
                                  context,
                                  () => setState(() {}),
                                  tagIndex: idx, // Index des Tages übergeben
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
                            child: Text('OK', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
            child: Container(
              width: 49,   
              height: 80,  
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10), 
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0), // Mehr Abstand nach oben
                      child: iconPath != null
                          ? Image.asset(
                              iconPath,
                              width: 36,   // Größeres Icon
                              height: 36,
                              fit: BoxFit.contain,
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16, 
                          fontWeight: idx == today ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            child: Text('OK', style: TextStyle(color: Colors.blue)),
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
                        activeColor: Colors.blue,
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                          (states) => states.contains(WidgetState.selected) ? Colors.blue : Colors.white,
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
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
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
                child: Text('Abbrechen', style: TextStyle(color: Colors.blue)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  eintraege[index] = {
                    'option': selectedOption ?? '',
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

