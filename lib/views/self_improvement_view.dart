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
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Kendini Geliştir",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık Kartı
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school,
                        size: 32,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Yeteneklerini Geliştir",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
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

            const SizedBox(height: 24),

            // Mevcut Yetenekler
            const Text(
              "Mevcut Yetenekler",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (player.skills.isEmpty)
              const Text(
                "Henüz yetenek yok.",
                style: TextStyle(color: Colors.grey),
              ),
            ...player.skills.map((skill) {
              return FadeInLeft(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(Icons.star, color: Colors.amber.shade600),
                    title: Text(
                      skill,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: LinearPercentIndicator(
                        lineHeight: 6.0,
                        percent: 1.0, // Öğrenilmiş yetenek tam dolu
                        backgroundColor: Colors.grey.shade200,
                        progressColor: Colors.green,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Yeni Yetenekler
            const Text(
              "Öğrenebileceğin Yetenekler",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.add_circle_outline,
                      color: Colors.red.shade400,
                    ),
                    title: Text(
                      skill,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      game != null
                          ? "Gereksinim: '${game.name}' oyunu"
                          : "Gereksinim: 5.000 TL",
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
