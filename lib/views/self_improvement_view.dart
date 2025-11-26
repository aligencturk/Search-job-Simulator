import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../core/department_game_content.dart';
import '../models/minigame_model.dart';
import '../viewmodels/game_view_model.dart';
import 'games/dilemma_game_view.dart';
import 'games/grind_game_view.dart';
import 'games/memory_game_view.dart';
import 'games/reflex_game_view.dart';
import 'games/timing_game_view.dart';

class SelfImprovementView extends ConsumerWidget {
  const SelfImprovementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameVM = ref.watch(gameProvider);
    final player = gameVM.player;

    if (player == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Kendini Geliştir")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık Kartı
            FadeInDown(
              child: Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Yeteneklerini Geliştir",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Yeni yetenekler öğren, kariyerini ilerlet",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mevcut Yetenekler
            Text(
              "Mevcut Yetenekler",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...player.skills.map((skill) {
              return FadeInLeft(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(skill),
                    subtitle: LinearPercentIndicator(
                      lineHeight: 8.0,
                      percent: 0.5, // Şimdilik sabit
                      backgroundColor: Colors.grey.shade300,
                      progressColor: Colors.blue,
                      barRadius: const Radius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Yeni Yetenekler
            Text(
              "Öğrenebileceğin Yetenekler",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._getAvailableSkills(player.skills, gameVM.department?.name).map((
              skill,
            ) {
              final gameTypeForSkill =
                  DepartmentGameContent.getGameTypeForSkill(
                    skill,
                    gameVM.department?.name,
                  );
              final game = gameTypeForSkill != null
                  ? miniGames.firstWhere(
                      (g) => g.type == gameTypeForSkill,
                      orElse: () => miniGames.first,
                    )
                  : null;

              return FadeInRight(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                    title: Text(skill),
                    subtitle: Text(
                      game != null
                          ? "Bu yeteneği öğrenmek için '${game.name}' oyununu tamamlamalısın"
                          : "Bu yeteneği öğrenmek için 5.000 TL gerekiyor",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: game != null
                          ? () {
                              // İlgili oyunu başlat
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      _buildGameView(game, ref, context),
                                ),
                              );
                            }
                          : player.money >= 5000
                          ? () {
                              // Oyun yoksa direkt para ile öğren
                              ref.read(gameProvider).addSkill(skill, 5000);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("$skill yeteneği eklendi!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      child: Text(game != null ? "Oyna" : "Öğren"),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView(MiniGame game, WidgetRef ref, BuildContext context) {
    void onComplete() {
      ref.read(gameProvider).completeMinigame(game, true);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Eğitim tamamlandı!"),
          backgroundColor: Colors.green,
        ),
      );
    }

    void onFail() {
      ref.read(gameProvider).completeMinigame(game, false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Başarısız!"),
          backgroundColor: Colors.red,
        ),
      );
    }

    switch (game.type) {
      case GameType.Reflex:
        return ReflexGameView(onGameComplete: onComplete, onGameFail: onFail);
      case GameType.Timing:
        return TimingGameView(onGameComplete: onComplete, onGameFail: onFail);
      case GameType.Memory:
        return MemoryGameView(onGameComplete: onComplete, onGameFail: onFail);
      case GameType.Dilemma:
        return DilemmaGameView(onGameComplete: onComplete, onGameFail: onFail);
      case GameType.Grind:
        return GrindGameView(onGameComplete: onComplete, onGameFail: onFail);
    }
  }

  List<String> _getAvailableSkills(
    List<String> currentSkills,
    String? departmentName,
  ) {
    final allSkills = DepartmentGameContent.getAvailableSkills(departmentName);
    return allSkills.where((skill) => !currentSkills.contains(skill)).toList();
  }
}
