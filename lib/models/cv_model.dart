import '../core/enums.dart';

class CVExperience {
  final String title;
  final String company;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;

  CVExperience({
    required this.title,
    required this.company,
    this.description,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
  });
}

class CVTask {
  final String title;
  final String description;
  final DateTime completedDate;

  CVTask({
    required this.title,
    required this.description,
    required this.completedDate,
  });
}

class CV {
  final String name;
  final Gender gender;
  final MilitaryStatus militaryStatus;
  final String department;
  final List<String> skills;
  final List<CVExperience> experiences;
  final List<CVTask> completedTasks;
  final double money;

  CV({
    required this.name,
    required this.gender,
    required this.militaryStatus,
    required this.department,
    required this.skills,
    this.experiences = const [],
    this.completedTasks = const [],
    this.money = 0,
  });
}
