import '../core/enums.dart';

class Player {
  final String name;
  final Gender gender;
  MilitaryStatus militaryStatus;
  double money;
  List<String> skills;

  Player({
    required this.name,
    required this.gender,
    required this.militaryStatus,
    this.money = 10000.0,
    List<String>? skills,
  }) : skills = skills ?? [];

  Player copyWith({
    String? name,
    Gender? gender,
    MilitaryStatus? militaryStatus,
    double? money,
    List<String>? skills,
  }) {
    return Player(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      militaryStatus: militaryStatus ?? this.militaryStatus,
      money: money ?? this.money,
      skills: skills ?? this.skills,
    );
  }
}
