import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/department_game_content.dart';
import '../../viewmodels/game_view_model.dart';

class DilemmaGameView extends ConsumerStatefulWidget {
  final VoidCallback onGameComplete;
  final VoidCallback onGameFail;

  const DilemmaGameView({
    super.key,
    required this.onGameComplete,
    required this.onGameFail,
  });

  @override
  ConsumerState<DilemmaGameView> createState() => _DilemmaGameViewState();
}

class _DilemmaGameViewState extends ConsumerState<DilemmaGameView> {
  int _currentQuestionIndex = 0;
  int _score = 0; // XP yerine doğru karar sayısı olarak takip edelim
  int _timeLeft = 10;
  Timer? _timer;
  bool _isGameRunning = true;
  List<Map<String, dynamic>> _scenarios = [];

  void _loadDepartmentContent() {
    final gameVM = ref.read(gameProvider);
    _scenarios = DepartmentGameContent.getDilemmaScenarios(
      gameVM.department?.name,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepartmentContent();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timeLeft = 10;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    _timer?.cancel();
    // Süre doldu, başarısız sayılır veya 0 puanla devam eder
    _nextQuestion(0, false);
  }

  void _answerQuestion(Map<String, dynamic> option) {
    _timer?.cancel();

    // Türkiye Mühürü: Bazen doğru cevap az puan getirebilir gibi bir mekanik eklenebilir
    // Şimdilik basit puanlama:
    int points = option["score"];
    bool isCorrect = option["isCorrect"];

    // Burada mizahi bir mesaj gösterebiliriz
    if (!isCorrect && points > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Etik değil ama iş bitirici! Puan aldın."),
        ),
      );
    } else if (isCorrect) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Çok profesyonel!")));
    }

    _nextQuestion(points, isCorrect);
  }

  void _nextQuestion(int points, bool isCorrect) {
    if (isCorrect) _score++;

    if (_currentQuestionIndex < _scenarios.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isGameRunning = true;
      });
      _startTimer();
    } else {
      _endGame();
    }
  }

  void _endGame() {
    setState(() {
      _isGameRunning = false;
    });

    // 3 sorudan en az 2'si doğru/makul olmalı
    if (_score >= 2) {
      widget.onGameComplete();
    } else {
      widget.onGameFail();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Senaryolar henüz yüklenmediyse loading göster
    if (_scenarios.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          title: const Text("İkilem ve Karar"),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final scenario = _scenarios[_currentQuestionIndex];
    final options = scenario["options"] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text("İkilem ve Karar"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(
              value: _timeLeft / 10,
              backgroundColor: Colors.grey,
              color: _timeLeft < 4 ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              "Süre: $_timeLeft sn",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Text(
              scenario["question"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ...options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGameRunning
                        ? () => _answerQuestion(option)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      option["text"],
                      style: const TextStyle(fontSize: 18),
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
}
