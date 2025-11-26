import 'dart:async';
import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/department_game_content.dart';
import '../../viewmodels/game_view_model.dart';

class MemoryGameView extends ConsumerStatefulWidget {
  final VoidCallback onGameComplete;
  final VoidCallback onGameFail;

  const MemoryGameView({
    super.key,
    required this.onGameComplete,
    required this.onGameFail,
  });

  @override
  ConsumerState<MemoryGameView> createState() => _MemoryGameViewState();
}

class _MemoryGameViewState extends ConsumerState<MemoryGameView> {
  List<int> _sequence = [];
  int _currentStep = 0;
  bool _isShowingSequence = false;
  bool _isGameRunning = false;
  int _score = 0;
  int _activeButtonIndex = -1; // Hangi butonun yandığını gösterir
  final Random _random = Random();
  bool _distractionActive = false; // Patronun fikri değişti dikkati

  List<String> _buttonLabels = [];
  String _distractionMessage = "";

  void _loadDepartmentContent() {
    final gameVM = ref.read(gameProvider);
    _buttonLabels = DepartmentGameContent.getMemoryButtons(
      gameVM.department?.name,
    );
    _distractionMessage = DepartmentGameContent.getDistractionMessage(
      gameVM.department?.name,
    );
  }

  final List<Color> _buttonColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepartmentContent();
      _startGame();
    });
  }

  void _startGame() {
    setState(() {
      _isGameRunning = true;
      _score = 0;
      _sequence.clear();
      _nextRound();
    });
  }

  void _nextRound() async {
    setState(() {
      _currentStep = 0;
      _isShowingSequence = true;
      _distractionActive = false;
      // Diziye yeni bir adım ekle
      _sequence.add(_random.nextInt(4));
    });

    // Diziyi göster
    for (int i = 0; i < _sequence.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _activeButtonIndex = _sequence[i];
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _activeButtonIndex = -1;
      });
    }

    // Türkiye Mühürü: Şaşırtmaca
    if (_sequence.length > 3 && _random.nextBool()) {
      setState(() {
        _distractionActive = true;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _distractionActive = false;
      });
    }

    setState(() {
      _isShowingSequence = false;
    });
  }

  void _onButtonTap(int index) {
    if (_isShowingSequence || !_isGameRunning || _distractionActive) return;

    if (index == _sequence[_currentStep]) {
      // Doğru basış
      setState(() {
        _currentStep++;
      });

      if (_currentStep >= _sequence.length) {
        // Tur tamamlandı
        setState(() {
          _score++;
        });

        if (_score >= 5) {
          // Kazanma koşulu
          _isGameRunning = false;
          widget.onGameComplete();
        } else {
          // Sonraki tur
          Future.delayed(const Duration(milliseconds: 500), _nextRound);
        }
      }
    } else {
      // Yanlış basış - Oyun Bitti
      _isGameRunning = false;
      widget.onGameFail();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Buton etiketleri henüz yüklenmediyse loading göster
    if (_buttonLabels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          title: const Text("Hafıza ve Sıra"),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text("Hafıza ve Sıra"),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Tur: ${_score + 1} / 5",
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 10),
              Text(
                _isShowingSequence
                    ? "İzle..."
                    : (_distractionActive ? "Bekle!" : "Tekrarla!"),
                style: TextStyle(
                  color: _distractionActive ? Colors.red : Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    bool isActive = _activeButtonIndex == index;
                    return GestureDetector(
                      onTap: () => _onButtonTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _buttonColors[index]
                              : _buttonColors[index].withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: _buttonColors[index],
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                          border: Border.all(
                            color: Colors.white.withOpacity(isActive ? 1 : 0.1),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _buttonLabels[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isActive ? 18 : 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Şaşırtmaca Katmanı
          if (_distractionActive)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: ShakeY(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _distractionMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
