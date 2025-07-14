import 'package:flutter/material.dart';
import 'package:streax/screens/home/journal.dart'; 

class ProgressBar extends StatelessWidget {
  final String labelText;
  final double progressValue;

  const ProgressBar({
    Key? key,
    required this.labelText,
    required this.progressValue,
  }) : super(key: key);

  /// Fortschritt für verschiedene Zieltypen berechnen
  static double calculateProgress(
    Map<String, dynamic> data, {
    Map<String, Map<String, dynamic>>? eintraege, // <-- Mapping statt List<DateTime>
    double? currentWeight,
  }) {
    switch (data['type']) {
      case 'Training':
        final int targetTrainings = data['targetTrainings'] ?? 0;
        if (targetTrainings == 0 || eintraege == null) return 0.0;

        final int daysLogged = getLoggedTrainingDaysThisWeek(eintraege);
        final double progress = daysLogged / targetTrainings;
        return progress.clamp(0.0, 1.0);

      case 'Event':
        final DateTime? eventDate = DateTime.tryParse(data['eventDate'] ?? '');
        if (eventDate != null) {
          final DateTime now = DateTime.now();
          final int totalDays = eventDate.difference(now.subtract(Duration(days: 30))).inDays;
          final int remainingDays = eventDate.difference(now).inDays;
          return remainingDays <= 0
              ? 1.0
              : (totalDays - remainingDays) / totalDays;
        }
        return 0.0;

      case 'Gewicht':
        if (currentWeight == null || data['targetWeight'] == null) return 0.0;
        final double startWeight = data['startWeight'] ?? currentWeight;
        final double targetWeight = data['targetWeight'];
        if (targetWeight < startWeight) {
          // Abnehmen
          if (currentWeight >= startWeight) return 0.0;
          if (currentWeight <= targetWeight) return 1.0;
          final double progress = (startWeight - currentWeight) / (startWeight - targetWeight);
          return progress.clamp(0.0, 1.0);
        } else if (targetWeight > startWeight) {
          // Zunehmen
          if (currentWeight <= startWeight) return 0.0;
          if (currentWeight >= targetWeight) return 1.0;
          final double progress = (currentWeight - startWeight) / (targetWeight - startWeight);
          return progress.clamp(0.0, 1.0);
        } else {
          return 1.0;
        }
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

/// Widget zur Darstellung eines Ziels (Event, Gewicht, Training)
Widget GoalIndicator(
  Map<String, dynamic> data,
  BuildContext context, {
  Map<String, Map<String, dynamic>>? eintraege,
  double? currentWeight,
}) {
  if (data['type'] == 'Event' && data['eventDate'] != null) {
    final DateTime? eventDate = DateTime.tryParse(data['eventDate']);
    final DateTime now = DateTime.now();
    String countdownText = 'Kein Datum angegeben';
    if (eventDate != null) {
      final int daysLeft = eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (daysLeft > 1) {
        countdownText = 'Noch $daysLeft Tage';
      } else if (daysLeft == 1) {
        countdownText = 'Noch 1 Tag';
      } else if (daysLeft == 0) {
        countdownText = 'Heute';
      } else {
        countdownText = 'Event vorbei';
      }
    }
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Event',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  countdownText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } else {
    String label;
    if (data['type'] == 'Gewicht') {
      label = '${data['targetWeight']?.toInt() ?? 0}kg erreichen';
    } else if (data['type'] == 'Training') {
      final int trainings = data['targetTrainings']?.toInt() ?? 0;
      label = trainings == 1
          ? 'An einem Tag in der Woche Sport machen'
          : 'An $trainings Tagen in der Woche Sport machen';
    } else {
      label = 'Unbekanntes Ziel';
    }
    return ProgressBar(
      labelText: label,
      progressValue: ProgressBar.calculateProgress(
        data,
        eintraege: eintraege,
      ),
    );
  }
}