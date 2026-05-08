int getLevel(int streakMax) {
  final xp = streakMax * 10;
  return (xp / 100).floor() + 1;
}

double getXpProgress(int streakMax) {
  final xp = streakMax * 10;
  return ((xp % 100) / 100.0).clamp(0.0, 1.0);
}

int getXp(int streakMax)     => streakMax * 10;
int getNextXp(int streakMax) => getLevel(streakMax) * 100;

String getRank(int level) {
  if (level >= 9) return 'Legend';
  if (level >= 6) return 'Pro';
  if (level >= 3) return 'Amateur';
  return 'Rookie';
}
