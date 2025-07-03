import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final String labelText;
  final double progressValue;

  const ProgressBar({
    Key? key,
    required this.labelText,
    required this.progressValue,
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