import 'package:flutter/material.dart';

class Fortschrittsbalken extends StatelessWidget {
  final String label;
  final double fortschritt;

  const Fortschrittsbalken({
    required this.label,
    required this.fortschritt,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container( //wrappper für Progress bar, damit border styles verwendet werden können
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
            borderRadius: BorderRadius.circular(100), //Farbe, Rundung und Breite der Border
          ),
          child: Stack( //Überlagerung von % auf dem Balken
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value: fortschritt,
                backgroundColor: Colors.transparent,
                borderRadius: BorderRadius.circular(100), //Rundung des Balkens
                valueColor: AlwaysStoppedAnimation<Color>(
                  fortschritt == 1.0 //if else um die Farbe des Fortschrittsbalkens zu bestimmen
                      ? Colors.green
                      : fortschritt > 0.6
                          ? const Color.fromRGBO(33, 150, 243, 1)
                          : fortschritt >= 0.3
                              ? Colors.yellow
                              : Colors.red,
                ),
                minHeight: 40, //Höhe des Fortschrittsbalkens
              ),
              Text( // Fortschritt als Dezimal in Prozent String umwandeln
                "${(fortschritt * 100).toStringAsFixed(0)}%", // 0, also keine Nachkommastellen
                style: Theme.of(context).textTheme.headlineMedium?.copyWith( fontSize: 30) //font stil übernehmen, aber größere Schriftgröße
              ),
            ],
          ),
        ),
        SizedBox(height: 5), // Padding
        Center( //Zentrierung vom Text
          child: Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
        ),
        SizedBox(height: 30), // Padding unter dem Widget
      ],
    );
  }
}