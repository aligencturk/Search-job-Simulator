import '../core/enums.dart';

class Job {
  final String title;
  final double salary;
  final double ghostingChance; // 0.0 - 1.0
  final JobType type;
  final List<String> requiredSkills;

  Job({
    required this.title,
    required this.salary,
    required this.ghostingChance,
    required this.type,
    this.requiredSkills = const [],
  });
}

