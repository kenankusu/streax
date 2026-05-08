import 'package:flutter/material.dart';

// ─── Sport-Kategorien ─────────────────────────────────────────────────────────
enum SportCategory {
  /// Distanz + Dauer (Laufen, Radfahren, Schwimmen …)
  distance,
  /// Training / Spiel + Dauer (Fussball, Basketball …)
  ballsport,
  /// Training / Kampf + Dauer (Boxen, Kickboxen …)
  combat,
  /// Nur Dauer (Krafttraining, Yoga …)
  general,
}

const Map<String, SportCategory> kSportCategories = {
  'Laufen':          SportCategory.distance,
  'Radfahren':       SportCategory.distance,
  'Fahrradfahren':   SportCategory.distance,
  'Schwimmen':       SportCategory.distance,
  'Rudern':          SportCategory.distance,
  'Leichtathletik':  SportCategory.distance,
  'Wandern':         SportCategory.distance,
  'Fussball':        SportCategory.ballsport,
  'Basketball':      SportCategory.ballsport,
  'Handball':        SportCategory.ballsport,
  'Volleyball':      SportCategory.ballsport,
  'Tischtennis':     SportCategory.ballsport,
  'Tennis':          SportCategory.ballsport,
  'Badminton':       SportCategory.ballsport,
  'Padel':           SportCategory.ballsport,
  'Golf':            SportCategory.ballsport,
  'American Football': SportCategory.ballsport,
  'Boxen':           SportCategory.combat,
  'Kickboxen':       SportCategory.combat,
  'Muay Thai':       SportCategory.combat,
  'Ringen':          SportCategory.combat,
};

/// Gibt die Kategorie für eine Sportart zurück (default: general)
SportCategory sportCategory(String sport) =>
    kSportCategories[sport] ?? SportCategory.general;

// ─── Vollständige Sportartenliste ─────────────────────────────────────────────
const List<String> kAllSports = [
  'American Football', 'Badminton',    'Basketball',   'Boxen',
  'Calisthenics',      'Crossfit',     'Fahrradfahren','Fussball',
  'Golf',              'Handball',     'Kickboxen',    'Klettern',
  'Krafttraining',     'Leichtathletik','Laufen',      'Muay Thai',
  'Padel',             'Pilates',      'Radfahren',    'Reiten',
  'Ringen',            'Rudern',       'Schwimmen',    'Ski',
  'Snowboarding',      'Tennis',       'Tischtennis',  'Turnen',
  'Volleyball',        'Wandern',      'Yoga',
];

// ─── Sport → Emoji ────────────────────────────────────────────────────────────
const Map<String, String> kSportEmojis = {
  'American Football': '🏈',
  'Badminton':         '🏸',
  'Basketball':        '🏀',
  'Boxen':             '🥊',
  'Calisthenics':      '💪',
  'Crossfit':          '🔥',
  'Fahrradfahren':     '🚴',
  'Fussball':          '⚽',
  'Golf':              '⛳',
  'Handball':          '🤾',
  'Kickboxen':         '🥊',
  'Klettern':          '🧗',
  'Krafttraining':     '🏋️',
  'Leichtathletik':    '🏅',
  'Laufen':            '🏃',
  'Muay Thai':         '🥊',
  'Padel':             '🎾',
  'Pilates':           '🧘',
  'Radfahren':         '🚴',
  'Reiten':            '🏇',
  'Ringen':            '🤼',
  'Rudern':            '🚣',
  'Schwimmen':         '🏊',
  'Ski':               '⛷️',
  'Snowboarding':      '🏂',
  'Tennis':            '🎾',
  'Tischtennis':       '🏓',
  'Turnen':            '🤸',
  'Volleyball':        '🏐',
  'Wandern':           '🥾',
  'Yoga':              '🧘',
};

// ─── Sport → Icon-Asset-Pfad ──────────────────────────────────────────────────
const Map<String, String> kSportIconPaths = {
  'Krafttraining': 'assets/icons/journal/gym.png',
  'Boxen':         'assets/icons/journal/boxen.png',
  'Laufen':        'assets/icons/journal/laufen.png',
  'Tischtennis':   'assets/icons/journal/tt.png',
  'Fussball':      'assets/icons/journal/fussball.png',
};

// ─── Primäre Sportarten für den addActivity-Screen ───────────────────────────
const List<Map<String, String>> kPrimarySports = [
  {'name': 'Laufen',        'emoji': '🏃'},
  {'name': 'Radfahren',     'emoji': '🚴'},
  {'name': 'Krafttraining', 'emoji': '🏋️'},
  {'name': 'Fussball',      'emoji': '⚽'},
];

// ─── Helper: Emoji für eine Sportart ─────────────────────────────────────────
String sportEmoji(String sport) {
  // Exakter Treffer (z.B. 'Laufen')
  if (kSportEmojis.containsKey(sport)) return kSportEmojis[sport]!;
  // Fallback: case-insensitiv
  final key = kSportEmojis.keys.firstWhere(
    (k) => k.toLowerCase() == sport.toLowerCase(),
    orElse: () => '',
  );
  return key.isNotEmpty ? kSportEmojis[key]! : '🏅';
}

// ─── Helper: Icon-Asset-Pfad für eine Sportart ───────────────────────────────
String? sportIconPath(String sport) => kSportIconPaths[sport];

// ─── Helper: Widget-Icon für eine Sportart (immer Emoji) ─────────────────────
Widget sportIconWidget(String sport, {double size = 28}) {
  return Text(
    sportEmoji(sport),
    style: TextStyle(fontSize: size * 0.85),
  );
}
