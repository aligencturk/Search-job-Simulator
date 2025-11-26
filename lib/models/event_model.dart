class Event {
  final DateTime date;
  final String description;
  final List<String> options; // 3 seçenek
  final EventType type; // Günlük, Aylık, Yıllık

  Event({
    required this.date,
    required this.description,
    required this.options,
    required this.type,
  });
}

enum EventType {
  Daily, // Günlük
  Monthly, // Aylık
  Yearly, // Yıllık
}
