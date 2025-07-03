class Goal {
  final String art;
  final String name;

  Goal({required this.art, required this.name});

  Map<String, String> toMap() {
    return {'art': art, 'name': name};
  }

  static Goal fromMap(Map<String, String> map) {
    return Goal(art: map['art']!, name: map['name']!);
  }
}

// Diese Liste muss vorhanden sein!
const List<String> goalTypes = [
  'Gewicht',
  'Training',
  'Schritte',
  'Event',
];

final List<Goal> defaultGoals = [
  Goal(art: 'Gewicht', name: 'Gewichtsziel erreichen'),
  Goal(art: 'Training', name: '3x pro Woche trainieren'),
  Goal(art: 'Schritte', name: '10.000 Schritte täglich'),
];