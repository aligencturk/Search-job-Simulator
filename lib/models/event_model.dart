class Event {
  final DateTime date;
  final String description;
  final List<String> options; // 3 seçenek
  final EventType type; // Günlük, Aylık, Yıllık
  final Map<String, dynamic>? outcomes; // Seçeneğe göre sonuçlar

  Event({
    required this.date,
    required this.description,
    required this.options,
    required this.type,
    this.outcomes,
  });
}

enum EventType {
  Daily, // Günlük
  Monthly, // Aylık
  Yearly, // Yıllık
}
