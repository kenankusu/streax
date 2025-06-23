import 'package:flutter/material.dart';

class Fortschrittsbalken extends StatelessWidget {
  final String label;
  final double fortschritt;

  const Fortschrittsbalken({
    required this.label,
    required this.fortschritt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Deine Ziele",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        LinearProgressIndicator(
          value: fortschritt,
          backgroundColor: Colors.grey[300],
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
                SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
