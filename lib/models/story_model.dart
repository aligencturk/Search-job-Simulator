class Story {
  final DateTime date;
  final String content;
  final StoryType type; // Günlük, Aylık, Yıllık

  Story({
    required this.date,
    required this.content,
    required this.type,
  });
}

enum StoryType {
  Daily, // Günlük
  Monthly, // Aylık
  Yearly, // Yıllık
}

