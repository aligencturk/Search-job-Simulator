import 'dart:async';
import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GrindGameView extends ConsumerStatefulWidget {
  final VoidCallback onGameComplete;
  final VoidCallback onGameFail;

  const GrindGameView({
    super.key,
    required this.onGameComplete,
    required this.onGameFail,
  });

  @override
  ConsumerState<GrindGameView> createState() => _GrindGameViewState();
}

class _GrindGameViewState extends ConsumerState<GrindGameView> {
  int _clicks = 0;
  int _timeLeft = 15;
  Timer? _gameTimer;
  bool _isGameRunning = true;
  bool _isSystemError = false; // Türkiye Mühürü: Sistem Hatası
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        _checkRandomEvent();
      } else {
        _endGame();
      }
    });
  }

  void _checkRandomEvent() async {
    if (_isSystemError) return;

    // %20 şansla sistem hatası
    if (_timeLeft > 2 && _random.nextInt(100) < 20) {
      setState(() {
        _isSystemError = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        setState(() {
          _isSystemError = false;
        });
      }
    }
  }

  void _onTap() {
    if (!_isGameRunning || _isSystemError) return;

    setState(() {
      _clicks++;
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _isGameRunning = false;
    });

    // Hedef: 15 saniyede en az 60 tıklama (Saniyede 4 tık)
    if (_clicks >= 60) {
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
        title: const Text("Veri Girişi (Grind)"),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Süre: $_timeLeft",
                style: TextStyle(
                  color: _timeLeft < 5 ? Colors.red : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Girişler: $_clicks",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: _onTap,
                  child: Pulse(
                    manualTrigger: true,
                    controller: (controller) {
                      // Her tıklamada animasyon tetiklenebilir ama performans için gerek yok
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _isSystemError ? Colors.grey : Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isSystemError ? Colors.grey : Colors.blue.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isSystemError ? Icons.error_outline : Icons.touch_app,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isSystemError ? "SİSTEM HATASI! BEKLEYİN..." : "TIKLA!",
                style: TextStyle(
                  color: _isSystemError ? Colors.red : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Sistem Hatası Overlay
          if (_isSystemError)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Sistem Hatası"),
                    ],
                  ),
                  content: const Text("Sunucu yanıt vermiyor. Lütfen bekleyiniz..."),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

