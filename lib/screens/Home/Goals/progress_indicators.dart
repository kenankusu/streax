import 'package:flutter/material.dart';

class Fortschrittsbalken extends StatelessWidget {
  final String label;
  final double fortschritt;

  const Fortschrittsbalken({
    Key? key,
    required this.label,
    required this.fortschritt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: fortschritt,
            backgroundColor: Colors.grey[700],
            borderRadius: BorderRadius.circular(100),
            valueColor: AlwaysStoppedAnimation<Color>(
              fortschritt == 1.0
                  ? Color(0xFFB1D43A) // Grün bei 100%
                  : fortschritt > 0.6
                      ? Color(0xFF1C499E) // Blau bei >60%
                      : fortschritt >= 0.3
                          ? Colors.orange // Orange bei 30-60%
                          : Colors.red, // Rot bei <30%
            ),
            minHeight: 8,
          ),
          SizedBox(height: 4),
          Text(
            "${(fortschritt * 100).toStringAsFixed(0)}%",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}