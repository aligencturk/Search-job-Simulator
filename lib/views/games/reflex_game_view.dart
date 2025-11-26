import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReflexGameView extends ConsumerStatefulWidget {
  final VoidCallback onGameComplete; // Başarılı olursa
  final VoidCallback onGameFail; // Başarısız olursa

  const ReflexGameView({
    super.key,
    required this.onGameComplete,
    required this.onGameFail,
  });

  @override
  ConsumerState<ReflexGameView> createState() => _ReflexGameViewState();
}

class _ReflexGameViewState extends ConsumerState<ReflexGameView> {
  int _score = 0;
  int _timeLeft = 15; // 15 saniye
  Timer? _gameTimer;
  Timer? _targetTimer;
  int _activeTargetIndex = -1; // 0-3 arası, -1 yok
  bool _isGameRunning = false;
  final Random _random = Random();

  // Hedef renkleri
  final List<Color> _padColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameRunning = true;
      _score = 0;
      _timeLeft = 15;
    });

    // Oyun süresi
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endGame();
      }
    });

    // Hedef değişimi (Hız artırılabilir)
    _spawnTarget();
  }

  void _spawnTarget() {
    if (!_isGameRunning) return;

    setState(() {
      _activeTargetIndex = _random.nextInt(4);
    });

    // Bir sonraki hedef süresi (skor arttıkça hızlanır)
    int nextDelay = max(500, 1500 - (_score * 50));
    _targetTimer = Timer(Duration(milliseconds: nextDelay), _spawnTarget);
  }

  void _onPadTap(int index) {
    if (!_isGameRunning) return;

    if (index == _activeTargetIndex) {
      // Doğru vuruş
      setState(() {
        _score++;
        _activeTargetIndex = -1; // Vurulduktan sonra kaybolsun
      });
      // Hemen yeni hedef (beklemeyi iptal et)
      _targetTimer?.cancel();
      _spawnTarget();
    } else {
      // Yanlış vuruş
      setState(() {
        _score = max(0, _score - 1);
      });
      // Titreşim veya ses eklenebilir
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    setState(() {
      _isGameRunning = false;
    });

    // Kazanma koşulu: 15 saniyede en az 10 doğru
    if (_score >= 10) {
      widget.onGameComplete();
    } else {
      widget.onGameFail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text("Refleks Oyunu"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Bilgi Paneli
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Skor: $_score",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Süre: $_timeLeft",
                  style: TextStyle(
                    color: _timeLeft <= 5 ? Colors.red : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Oyun Alanı (4 Pad)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(4, (index) {
                bool isActive = index == _activeTargetIndex;
                return GestureDetector(
                  onTap: () => _onPadTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _padColors[index]
                          : _padColors[index].withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? Colors.white : Colors.transparent,
                        width: 4,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: _padColors[index],
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: isActive
                        ? const Center(
                            child: Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: 48,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
