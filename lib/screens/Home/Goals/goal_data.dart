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

const List<String> goalTypes = [
  'Gewicht',
  'Training',
  'Schritte',
  'Event',
];
