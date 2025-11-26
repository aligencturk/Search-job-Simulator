import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimingGameView extends ConsumerStatefulWidget {
  final VoidCallback onGameComplete;
  final VoidCallback onGameFail;

  const TimingGameView({
    super.key,
    required this.onGameComplete,
    required this.onGameFail,
  });

  @override
  ConsumerState<TimingGameView> createState() => _TimingGameViewState();
}

class _TimingGameViewState extends ConsumerState<TimingGameView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _score = 0;
  int _attempts = 5; // 5 deneme hakkı
  bool _isGameRunning = true;

  // Hedef alan (0.0 - 1.0 arası)
  final double _targetStart = 0.45;
  final double _targetEnd = 0.55;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Hız ayarı
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stopAndCheck() {
    if (!_isGameRunning) return;

    double currentPos = _controller.value;

    // Hedefin içinde mi?
    if (currentPos >= _targetStart && currentPos <= _targetEnd) {
      setState(() {
        _score++;
        _attempts--;
      });

      // Hızlandır
      _controller.duration = Duration(
        milliseconds: (_controller.duration!.inMilliseconds * 0.9).toInt(),
      );
      _controller.repeat(reverse: true); // Yeni hızla devam et

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mükemmel!"),
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      setState(() {
        _attempts--;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kaçırdın!"),
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (_attempts <= 0) {
      _endGame();
    }
  }

  void _endGame() {
    _controller.stop();
    setState(() {
      _isGameRunning = false;
    });

    // Kazanma koşulu: 5 denemede en az 3 başarı
    if (_score >= 3) {
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
        title: const Text("Zamanlama Oyunu"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Başarılı: $_score / ${5 - _attempts + _score} (Kalan Hak: $_attempts)",
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 40),

          // Oyun Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Hedef Alan (Yeşil)
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: _targetEnd - _targetStart, // 0.1 genişlik
                      heightFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Hareketli Gösterge
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(
                          _controller.value * 2 - 1,
                          0,
                        ), // -1 to 1 mapping
                        child: Container(
                          width: 10,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),

          SizedBox(
            width: 200,
            height: 200,
            child: ElevatedButton(
              onPressed: _isGameRunning ? _stopAndCheck : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
              ),
              child: const Text(
                "DUR",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
