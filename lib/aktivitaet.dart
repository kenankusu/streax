import 'package:flutter/material.dart';

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
    TimeOfDay? vonZeit;
    TimeOfDay? bisZeit;
    DateTime datum = DateTime.now();
    TextEditingController notizenController = TextEditingController();
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
                            child: Text(sport),
                          ))
                      .toList(),
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                ZeitDatumAuswahl(),
                const SizedBox(height: 16),
                Text('Wie hast du dich gefühlt?', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                EmojiAuswahl(),
                const SizedBox(height: 16),
                FotoHinzufuegen(),
                const SizedBox(height: 16),
                TextField(
                  controller: notizenController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notizen',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // keine Funktion für jetzt
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Speichern'),
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

class ZeitDatumAuswahl extends StatefulWidget {
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
        } else {
          bisZeit = picked;
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
            const Text('von'),
            GestureDetector(
              onTap: () => _pickTime(context, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(vonZeit != null ? vonZeit!.format(context) : '--:--', style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('bis'),
            GestureDetector(
              onTap: () => _pickTime(context, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(bisZeit != null ? bisZeit!.format(context) : '--:--', style: const TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Datum'),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'heute, ${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.',
                  style: const TextStyle(fontSize: 20),
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
        children: const [
          Icon(Icons.camera_alt_outlined, color: Colors.grey),
          SizedBox(width: 8),
          Text('Foto hinzufügen', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class EmojiAuswahl extends StatefulWidget {
  @override
  State<EmojiAuswahl> createState() => _EmojiAuswahlState();
}

class _EmojiAuswahlState extends State<EmojiAuswahl> {
  int ausgewaehlt = 2; // Standard: neutral
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
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      }),
    );
  }
}