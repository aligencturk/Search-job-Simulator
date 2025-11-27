class Event {
  final DateTime date;
  final String description;
  final List<EventChoice> choices;
  final EventType type;

  // Geriye uyumluluk için options getter'ı
  List<String> get options => choices.map((e) => e.text).toList();

  Event({
    required this.date,
    required this.description,
    required this.choices,
    required this.type,
  });
}

class EventChoice {
  final String text;
  final String resultText;
  final int mentalDelta;
  final int moneyDelta;
  final String outcomeType;

  EventChoice({
    required this.text,
    required this.resultText,
    required this.mentalDelta,
    required this.moneyDelta,
    required this.outcomeType,
  });

  factory EventChoice.fromMap(Map<String, dynamic> map) {
    return EventChoice(
      text: map['text'] ?? '',
      resultText: map['result_text'] ?? '',
      mentalDelta: map['mental_delta'] ?? 0,
      moneyDelta: map['money_delta'] ?? 0,
      outcomeType: map['outcome_type'] ?? 'default',
    );
  }
}

enum EventType { Daily, Monthly, Yearly }
