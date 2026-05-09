import 'package:flutter/material.dart';
import 'package:streax/screens/Home/widgets/week_strip.dart';
import 'package:streax/shared/constants/theme_constants.dart';
import 'package:streax/shared/constants/sport_utils.dart';

// ─── PROGRESS CALCULATION ────────────────────────────────────────────────────

double calculateGoalProgress(
  Map<String, dynamic> data, {
  Map<String, Map<String, dynamic>>? eintraege,
  double? currentWeight,
}) {
  final type = data['type'] as String? ?? '';

  switch (type) {
    // New type: Gewohnheit
    case 'Gewohnheit':
      final target = (data['targetFrequency'] as num?)?.toInt() ?? 0;
      if (target == 0 || eintraege == null) return 0.0;
      return (getLoggedTrainingDaysThisWeek(eintraege) / target).clamp(0.0, 1.0);

    // Legacy type: Training
    case 'Training':
      final target = (data['targetTrainings'] as num?)?.toInt() ?? 0;
      if (target == 0 || eintraege == null) return 0.0;
      return (getLoggedTrainingDaysThisWeek(eintraege) / target).clamp(0.0, 1.0);

    case 'Event':
      final eventDate = DateTime.tryParse(data['eventDate'] ?? '');
      if (eventDate == null) return 0.0;
      final now = DateTime.now();
      final total = eventDate.difference(now.subtract(const Duration(days: 30))).inDays;
      final remaining = eventDate.difference(now).inDays;
      return remaining <= 0 ? 1.0 : ((total - remaining) / total).clamp(0.0, 1.0);

    // New type: Körperziel
    case 'Körperziel':
      if (currentWeight == null) return 0.0;
      final start = (data['startValue'] as num?)?.toDouble() ?? currentWeight;
      final target = (data['targetValue'] as num?)?.toDouble();
      if (target == null) return 0.0;
      if (target < start) {
        if (currentWeight >= start) return 0.0;
        if (currentWeight <= target) return 1.0;
        return ((start - currentWeight) / (start - target)).clamp(0.0, 1.0);
      } else if (target > start) {
        if (currentWeight <= start) return 0.0;
        if (currentWeight >= target) return 1.0;
        return ((currentWeight - start) / (target - start)).clamp(0.0, 1.0);
      }
      return 1.0;

    // Legacy type: Gewicht
    case 'Gewicht':
      if (currentWeight == null || data['targetWeight'] == null) return 0.0;
      final start = (data['startWeight'] as num?)?.toDouble() ?? currentWeight;
      final target = (data['targetWeight'] as num).toDouble();
      if (target < start) {
        if (currentWeight >= start) return 0.0;
        if (currentWeight <= target) return 1.0;
        return ((start - currentWeight) / (start - target)).clamp(0.0, 1.0);
      } else if (target > start) {
        if (currentWeight <= start) return 0.0;
        if (currentWeight >= target) return 1.0;
        return ((currentWeight - start) / (target - start)).clamp(0.0, 1.0);
      }
      return 1.0;

    default:
      return 0.0;
  }
}

// ─── GOAL INDICATOR (entry point called from homepage) ───────────────────────

Widget GoalIndicator(
  Map<String, dynamic> data,
  BuildContext context, {
  Map<String, Map<String, dynamic>>? eintraege,
  double? currentWeight,
}) {
  final type = data['type'] as String? ?? '';

  switch (type) {
    case 'Gewohnheit':
      return _HabitCard(data: data, eintraege: eintraege);
    case 'Training':
      return _HabitCard(data: data, eintraege: eintraege, isLegacy: true);
    case 'Event':
      return _EventCard(data: data);
    case 'Körperziel':
      return _BodyCard(data: data, currentWeight: currentWeight);
    case 'Gewicht':
      return _BodyCard(data: data, currentWeight: currentWeight, isLegacy: true);
    default:
      return const SizedBox.shrink();
  }
}

// ─── SHARED WIDGETS ──────────────────────────────────────────────────────────

Widget _progressBar(double progress, List<Color> colors) {
  return Container(
    height: 5,
    decoration: BoxDecoration(
      color: const Color(0xFF1A1D21),
      borderRadius: BorderRadius.circular(3),
    ),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: progress.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

Widget _badge(String text, Color textColor, Color bg, Color border) {
  return Container(
    padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
    decoration: BoxDecoration(
      color: bg,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textColor),
    ),
  );
}

// ─── HABIT CARD (Gewohnheit / legacy Training) ───────────────────────────────

class _HabitCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, Map<String, dynamic>>? eintraege;
  final bool isLegacy;

  const _HabitCard({required this.data, this.eintraege, this.isLegacy = false});

  @override
  Widget build(BuildContext context) {
    final String sport;
    final String name;
    final double progress;

    if (isLegacy) {
      sport = '';
      final n = (data['targetTrainings'] as num?)?.toInt() ?? 0;
      name = n == 1 ? '1× pro Woche trainieren' : '${n}× pro Woche trainieren';
      progress = calculateGoalProgress(data, eintraege: eintraege);
    } else {
      sport = data['sport'] as String? ?? '';
      final freq = (data['targetFrequency'] as num?)?.toInt() ?? 0;
      final period = data['period'] as String? ?? 'Woche';
      name = '${freq}× ${sport.isNotEmpty ? sport : 'Sport'} pro $period';
      progress = calculateGoalProgress(data, eintraege: eintraege);
    }

    final emoji = sport.isNotEmpty ? sportEmoji(sport) : '🏋️';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E),
        border: Border.all(color: const Color(0xFF1A3A5A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _badge('Gewohnheit', kBlue, const Color(0xFF0B2233), const Color(0xFF1A4A6A)),
            ],
          ),
          const SizedBox(height: 10),
          _progressBar(progress, const [kBlue, kGreen]),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% diese Woche',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EVENT CARD ──────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _EventCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Event';
    final sport = data['sport'] as String? ?? '';
    final emoji = sport.isNotEmpty ? sportEmoji(sport) : '🏆';
    final eventDate = DateTime.tryParse(data['eventDate'] ?? '');
    final now = DateTime.now();
    int daysLeft = 0;
    String dateStr = '';
    double progress = 0;

    if (eventDate != null) {
      daysLeft = eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      const months = [
        'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
        'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
      ];
      dateStr = '${eventDate.day}. ${months[eventDate.month - 1]} ${eventDate.year}';
      progress = calculateGoalProgress(data);
    }

    final badgeText = daysLeft > 0
        ? '$daysLeft ${daysLeft == 1 ? 'Tag' : 'Tage'}'
        : daysLeft == 0
            ? 'Heute'
            : 'Vorbei';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1208),
        border: Border.all(color: const Color(0xFF4A2E08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _badge(badgeText, kMid, const Color(0xFF231800), const Color(0xFF5A3000)),
            ],
          ),
          const SizedBox(height: 10),
          _progressBar(progress, const [kMid, kFire]),
          const SizedBox(height: 6),
          Text(
            [if (sport.isNotEmpty) '$emoji $sport', if (dateStr.isNotEmpty) dateStr]
                .join(' · '),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BODY CARD (Körperziel / legacy Gewicht) ─────────────────────────────────

class _BodyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final double? currentWeight;
  final bool isLegacy;

  const _BodyCard({required this.data, this.currentWeight, this.isLegacy = false});

  @override
  Widget build(BuildContext context) {
    final String name;
    String dateStr = '';
    double progress = 0;

    if (isLegacy) {
      final target = (data['targetWeight'] as num?)?.toDouble() ?? 0;
      name = '${target.toInt()} kg erreichen';
      progress = calculateGoalProgress(data, currentWeight: currentWeight);
    } else {
      final metric = data['messgröße'] as String? ?? 'Gewicht';
      final start = (data['startValue'] as num?)?.toDouble() ?? 0;
      final target = (data['targetValue'] as num?)?.toDouble() ?? 0;
      const units = {'Gewicht': 'kg', 'Körperfett': '%', 'Muskelmasse': 'kg'};
      final unit = units[metric] ?? 'kg';
      name = '$metric: ${start.toStringAsFixed(1)} → ${target.toStringAsFixed(1)} $unit';
      progress = calculateGoalProgress(data, currentWeight: currentWeight);

      final bisWann = DateTime.tryParse(data['bisWann'] ?? '');
      if (bisWann != null) {
        const months = [
          'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
          'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
        ];
        dateStr = 'bis ${bisWann.day}. ${months[bisWann.month - 1]} ${bisWann.year}';
      }
    }

    const metricEmoji = {
      'Gewicht': '⚖️',
      'Körperfett': '📊',
      'Muskelmasse': '💪',
    };
    final metric = data['messgröße'] as String? ?? 'Gewicht';
    final emoji = isLegacy ? '⚖️' : (metricEmoji[metric] ?? '⚖️');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A14),
        border: Border.all(color: const Color(0xFF0E4030)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _badge('Körperziel', kGreen, const Color(0xFF0B2620), const Color(0xFF0E5040)),
            ],
          ),
          const SizedBox(height: 10),
          _progressBar(progress, const [kGreen, kBlue]),
          const SizedBox(height: 6),
          Text(
            dateStr.isNotEmpty
                ? '${(progress * 100).toStringAsFixed(0)}% · $dateStr'
                : '${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LEGACY PROGRESSBAR (kept for ZielePopup compatibility) ──────────────────

class ProgressBar extends StatelessWidget {
  final String labelText;
  final double progressValue;

  const ProgressBar({super.key, required this.labelText, required this.progressValue});

  static double calculateProgress(
    Map<String, dynamic> data, {
    Map<String, Map<String, dynamic>>? eintraege,
    double? currentWeight,
  }) =>
      calculateGoalProgress(data, eintraege: eintraege, currentWeight: currentWeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labelText,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[700],
            borderRadius: BorderRadius.circular(100),
            valueColor: AlwaysStoppedAnimation<Color>(
              progressValue == 1.0
                  ? kGreen
                  : progressValue > 0.6
                      ? kBlue
                      : progressValue >= 0.3
                          ? Colors.orange
                          : Colors.red,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progressValue * 100).toStringAsFixed(0)}%',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
