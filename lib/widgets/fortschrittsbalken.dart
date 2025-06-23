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
        Text("Deine Ziele",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        Container( //wrappper für Progress bar, damit border styles verwendet werden können.
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: LinearProgressIndicator( //Progressbar
            value: fortschritt,
            backgroundColor: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            valueColor: AlwaysStoppedAnimation<Color>(
              fortschritt >= 1.0
                  ? Colors.green
                  : fortschritt > 0.6
                      ? Colors.blue
                      : fortschritt >= 0.3
                          ? Colors.yellow
                          : Colors.red,
            ),
            minHeight: 14,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        )
      ],
    );
  }
}