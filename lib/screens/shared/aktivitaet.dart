import 'package:flutter/material.dart'; // Grundlegende Flutter-Widgets und Material Design
import 'package:image_picker/image_picker.dart'; // Für das Auswählen von Bildern aus Galerie oder Kamera
import 'dart:io'; // Für Dateioperationen auf mobilen Plattformen (z.B. Image.file)
import '../Home/journal.dart'; // Zugriff auf das Journal für das Speichern der Aktivität
import 'package:flutter/foundation.dart'; // Für kIsWeb, um Web-spezifisches Verhalten zu steuern
import 'package:flutter/cupertino.dart'; // Für CupertinoDatePicker

class AktivitaetHinzufuegen extends StatelessWidget {
  const AktivitaetHinzufuegen({super.key});

  @override
  Widget build(BuildContext context) {
    //statische Auswahl an Sportarten
    final List<String> sportarten = [
      'Ruhetag',
      'Krafttraining',
      'Laufen',
      'Tischtennis',
      'Boxen',
      'Fussball',
    ];
    String? ausgewaehlteSportart;
    TimeOfDay? vonZeit;
    TimeOfDay? bisZeit;
    DateTime datum = DateTime.now();
    TextEditingController notizenController = TextEditingController();
    int ausgewaehltesEmoji = -1;// damit kein Emoji standardmäßig ausgewählt ist

    // Ersetze DecoratedBox durch Container mit Gradient-Hintergrund
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Theme.of(context).colorScheme.surface, //unten
            Theme.of(context).colorScheme.surfaceContainer, //oben
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Neue Aktivität', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 50),
                // Dropdown mit Gradient-Hintergrund und DropShadow umhüllen
                Container(
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Sportart auswählen',
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                      filled: true,
                      fillColor: Colors.transparent, // Gradient kommt vom Container
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    dropdownColor: Theme.of(context).colorScheme.surfaceVariant, // Menü in Theme-Farbe
                    items: sportarten
                        .map((sport) => DropdownMenuItem(
                              value: sport,
                              child: Text(sport, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      ausgewaehlteSportart = value;
                    },
                  ),
                ),
                const SizedBox(height: 30),
                ZeitDatumAuswahl(
                  onVonZeitChanged: (zeit) => vonZeit = zeit,
                  onBisZeitChanged: (zeit) => bisZeit = zeit,
                  onDatumChanged: (d) => datum = d,
                ),
                const SizedBox(height: 40),

                //Gefühl-Auswahl
                Text('Wie hast du dich gefühlt?', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 15),
                EmojiAuswahl(
                  onEmojiSelected: (index) => ausgewaehltesEmoji = index,
                ),
                const SizedBox(height: 50),

                // Foto hinzufügen und Notizen
                FotoHinzufuegen(),
                const SizedBox(height: 16),
                TextField(
                  controller: notizenController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: InputDecoration(
                    labelText: 'Notizen',
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2,
                      ),
                    ),
                    // focusedBorder wird entfernt, damit im Fokus der Standardrand erscheint
                  ),
                ),


                const SizedBox(height: 40),
                SizedBox(
                  child: ElevatedButton(
                    onPressed: () {
                      String dateKey = "${datum.year.toString().padLeft(4, '0')}-${datum.month.toString().padLeft(2, '0')}-${datum.day.toString().padLeft(2, '0')}";
                      eintraege[dateKey] = {
                        'option': ausgewaehlteSportart ?? '',
                        'text': notizenController.text,
                        'emoji': ausgewaehltesEmoji.toString(),
                        'von': vonZeit != null ? vonZeit!.format(context) : '',
                        'bis': bisZeit != null ? bisZeit!.format(context) : '',
                        'datum': datum.toIso8601String(),
                        'icon': sportartIcons[ausgewaehlteSportart ?? ''] ?? '',
                      };
                      Navigator.of(context).pop();
                      // ggf. Callback für setState aufrufen, falls nötig
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shadowColor: Colors.black,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      elevation: 8,
                    ),
                    child: Text(
                      'Speichern',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const Map<String, String> sportartIcons = {
  'Ruhetag': 'assets/icons/journal/rest.png',
  'Krafttraining': 'assets/icons/journal/gym.png',
  'Boxen': 'assets/icons/journal/boxen.png',
  'Laufen': 'assets/icons/journal/laufen.png',
  'Tischtennis': 'assets/icons/journal/tt.png',
  'Fussball': 'assets/icons/journal/fussball.png',
};

// ZeitDatumAuswahl anpassen:
class ZeitDatumAuswahl extends StatefulWidget {
  final ValueChanged<TimeOfDay?>? onVonZeitChanged;
  final ValueChanged<TimeOfDay?>? onBisZeitChanged;
  final ValueChanged<DateTime>? onDatumChanged;
  const ZeitDatumAuswahl({this.onVonZeitChanged, this.onBisZeitChanged, this.onDatumChanged, super.key});
  @override
  State<ZeitDatumAuswahl> createState() => _ZeitDatumAuswahlState();
}

class _ZeitDatumAuswahlState extends State<ZeitDatumAuswahl> {
  TimeOfDay? vonZeit = TimeOfDay.now();
  TimeOfDay? bisZeit = TimeOfDay.now();
  DateTime datum = DateTime.now();

  Future<void> _pickTime(BuildContext context, bool isVon) async {
    TimeOfDay? pickedTime;
    DateTime initialDateTime = DateTime(
      2000,
      1,
      1,
      isVon ? (vonZeit?.hour ?? 0) : (bisZeit?.hour ?? 0),
      isVon ? (vonZeit?.minute ?? 0) : (bisZeit?.minute ?? 0),
    );
    DateTime tempTime = initialDateTime;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDateTime,
                    use24hFormat: true, // 24-Stunden-Anzeige
                    onDateTimeChanged: (DateTime newTime) {
                      tempTime = newTime;
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    pickedTime = TimeOfDay(hour: tempTime.hour, minute: tempTime.minute);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Übernehmen'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        if (isVon) {
          vonZeit = pickedTime;
          widget.onVonZeitChanged?.call(vonZeit);
        } else {
          bisZeit = pickedTime;
          widget.onBisZeitChanged?.call(bisZeit);
        }
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: datum,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        datum = picked;
        widget.onDatumChanged?.call(datum);
      });
    }
  }

  String _formatTime24h(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    Widget zeitFeld(String label, String value, VoidCallback onTap) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Label linksbündig
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
          GestureDetector(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36, maxHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center, // Wert zentriert
              child: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 18)),
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          zeitFeld('von', _formatTime24h(vonZeit), () => _pickTime(context, true)),
          const SizedBox(width: 6),
          zeitFeld('bis', _formatTime24h(bisZeit), () => _pickTime(context, false)),
          const SizedBox(width: 6),
          zeitFeld(
            'Datum',
            '${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}',
            () => _pickDate(context),
          ),
        ],
      ),
    );
  }
}

class FotoHinzufuegen extends StatefulWidget {
  @override
  State<FotoHinzufuegen> createState() => _FotoHinzufuegenState();
}

class _FotoHinzufuegenState extends State<FotoHinzufuegen> {
  XFile? _bild;
  final ImagePicker _picker = ImagePicker();

  Future<void> _bildAuswaehlen() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _bild = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // FotoHinzufuegen: Icon und Text weiß
    return GestureDetector(
      onTap: _bildAuswaehlen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _bild != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_bild!.path, width: 48, height: 48, fit: BoxFit.cover)
                        : Image.file(File(_bild!.path), width: 48, height: 48, fit: BoxFit.cover),
                  )
                : const Icon(Icons.camera_alt_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _bild != null ? 'Foto ausgewählt' : 'Foto hinzufügen',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// EmojiAuswahl anpassen:
class EmojiAuswahl extends StatefulWidget {
  final ValueChanged<int>? onEmojiSelected;
  const EmojiAuswahl({this.onEmojiSelected, super.key});
  @override
  State<EmojiAuswahl> createState() => _EmojiAuswahlState();
}

class _EmojiAuswahlState extends State<EmojiAuswahl> {
  int ausgewaehlt = -1; // Kein Emoji standardmäßig ausgewählt
  final List<String> emojis = [
    '😢', // sehr traurig
    '🙁', // traurig
    '😐', // neutral
    '🙂', // glücklich
    '😄', // sehr glücklich
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(emojis.length, (index) {
        final ausgewaehltEmoji = ausgewaehlt == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              ausgewaehlt = index;
              widget.onEmojiSelected?.call(ausgewaehlt);
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: ausgewaehltEmoji
                  ? Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 3,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              emojis[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 32),
            ),
          ),
        );
      }),
    );
  }
}
