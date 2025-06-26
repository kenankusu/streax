import 'package:flutter/material.dart';
import 'widgets/journal.dart';

class AktivitaetHinzufuegen extends StatelessWidget {
  const AktivitaetHinzufuegen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> sportarten = [
      'Laufen',
      'Tischtennis',
      'Bop geben',
      'Krafttraining',
      'Jaxxen',
      'Fußball',
    ];
    String? ausgewaehlteSportart;
    TimeOfDay? vonZeit;
    TimeOfDay? bisZeit;
    DateTime datum = DateTime.now();
    TextEditingController notizenController = TextEditingController();
    int ausgewaehltesEmoji = -1;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Neue Aktivität', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sportart auswählen',
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 6,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 6,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 6,
                      ),
                    ),
                  ),
                  items: sportarten
                      .map((sport) => DropdownMenuItem(
                            value: sport,
                            child: Text(sport, style: Theme.of(context).textTheme.bodySmall),
                          ))
                      .toList(),
                  onChanged: (value) {
                    ausgewaehlteSportart = value;
                  },
                ),
                const SizedBox(height: 16),
                ZeitDatumAuswahl(
                  onVonZeitChanged: (zeit) => vonZeit = zeit,
                  onBisZeitChanged: (zeit) => bisZeit = zeit,
                  onDatumChanged: (d) => datum = d,
                ),
                const SizedBox(height: 16),
                Text('Wie hast du dich gefühlt?', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                EmojiAuswahl(
                  onEmojiSelected: (index) => ausgewaehltesEmoji = index,
                ),
                const SizedBox(height: 16),
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
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      child: ElevatedButton(
                        onPressed: () {
                          // Speichern-Logik: Werte an das Journal übergeben
                          Navigator.of(context).pop();
                          eintraege[datum.weekday - 1] = {
                            'option': ausgewaehlteSportart ?? '',
                            'text': notizenController.text,
                            'emoji': ausgewaehltesEmoji.toString(),
                            'von': vonZeit != null ? vonZeit!.format(context) : '',
                            'bis': bisZeit != null ? bisZeit!.format(context) : '',
                            'datum': datum.toIso8601String(),
                          };
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.black,
                          foregroundColor: const Color.fromARGB(255, 255, 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(500),
                          ),
                          textStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                        child: Text('Speichern', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
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
    final picked = await showTimePicker(
      context: context,
      initialTime: isVon ? (vonZeit ?? TimeOfDay.now()) : (bisZeit ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isVon) {
          vonZeit = picked;
          widget.onVonZeitChanged?.call(vonZeit);
        } else {
          bisZeit = picked;
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
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        datum = picked;
        widget.onDatumChanged?.call(datum);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('von', style: Theme.of(context).textTheme.bodySmall),
            GestureDetector(
              onTap: () => _pickTime(context, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(vonZeit != null ? vonZeit!.format(context) : '--:--', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 8),
            Text('bis', style: Theme.of(context).textTheme.bodySmall),
            GestureDetector(
              onTap: () => _pickTime(context, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(bisZeit != null ? bisZeit!.format(context) : '--:--', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 20)),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datum', style: Theme.of(context).textTheme.bodySmall),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'heute, ${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FotoHinzufuegen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Foto hinzufügen', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
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
    '😄', // sehr glücklich
    '🙂', // glücklich
    '😐', // neutral
    '🙁', // traurig
    '😢', // sehr traurig
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