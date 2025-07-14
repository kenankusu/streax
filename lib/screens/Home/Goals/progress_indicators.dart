import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final String labelText;
  final double progressValue;

  const ProgressBar({
    Key? key,
    required this.labelText,
    required this.progressValue,
  }) : super(key: key);

  static double calculateProgress(Map<String, dynamic> data, {double? currentWeight}) {
    // Fortschrittsberechnung für verschiedene Zielarten
    switch (data['type']) {
      case 'Event':
        final eventDate = DateTime.tryParse(data['eventDate'] ?? '');
        if (eventDate != null) {
          final now = DateTime.now();
          final totalDays = eventDate
              .difference(DateTime.now().subtract(Duration(days: 30)))
              .inDays;
          final remainingDays = eventDate.difference(now).inDays;
          return remainingDays <= 0
              ? 1.0
              : (totalDays - remainingDays) / totalDays;
        }
        return 0.0;
      case 'Gewicht':
        // Beispiel: Fortschritt für Gewichtsziel
        if (currentWeight == null || data['targetWeight'] == null) return 0.0;
        final startWeight = data['startWeight'] ?? currentWeight;
        final targetWeight = data['targetWeight'];
        if (targetWeight < startWeight) {
          // Abnehmen
          if (currentWeight >= startWeight) return 0.0;
          if (currentWeight <= targetWeight) return 1.0;
          final progress = (startWeight - currentWeight) / (startWeight - targetWeight);
          return progress.clamp(0.0, 1.0);
        } else if (targetWeight > startWeight) {
          // Zunehmen
          if (currentWeight <= startWeight) return 0.0;
          if (currentWeight >= targetWeight) return 1.0;
          final progress = (currentWeight - startWeight) / (targetWeight - startWeight);
          return progress.clamp(0.0, 1.0);
        } else {
          return 1.0;
        }
      case 'Training':
        return 0.4;
      default:
        return 0.0;
    }
  }

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
            labelText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[700],
            borderRadius: BorderRadius.circular(100),
            valueColor: AlwaysStoppedAnimation<Color>(
              progressValue == 1.0
                  ? Color(0xFFB1D43A)
                  : progressValue > 0.6
                      ? Color(0xFF1C499E)
                      : progressValue >= 0.3
                          ? Colors.orange
                          : Colors.red,
            ),
            minHeight: 8,
          ),
          SizedBox(height: 4),
          Text(
            "${(progressValue * 100).toStringAsFixed(0)}%",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}