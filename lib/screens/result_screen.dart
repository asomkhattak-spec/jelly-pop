import 'package:flutter/material.dart';

import '../game/sound.dart';
import '../game/storage.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.score,
    required this.bestCombo,
    required this.stars,
    required this.pops,
    required this.newRecord,
    required this.heartsLeft,
  });

  final int score;
  final int bestCombo;
  final int stars;
  final int pops;
  final bool newRecord;
  final int heartsLeft;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _headline {
    if (widget.newRecord) return 'NEW RECORD!';
    if (widget.heartsLeft <= 0) return 'BOOM! GAME OVER';
    if (widget.score >= 1500) return 'AMAZING!';
    if (widget.score >= 800) return 'GREAT POPPING!';
    if (widget.score >= 300) return 'NICE ONE!';
    return 'GOOD TRY!';
  }

  String get _emoji {
    if (widget.newRecord) return '🏆';
    if (widget.heartsLeft <= 0) return '💥';
    if (widget.score >= 1500) return '🤩';
    if (widget.score >= 800) return '🎉';
    return '😊';
  }

  void _again() {
    SoundManager.instance.tap();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _home() {
    SoundManager.instance.tap();
    Navigator.of(context).pop();
  }

  void _shop() {
    SoundManager.instance.tap();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B4DFF), Color(0xFF9B5CFF)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeOutBack.transform(
                  _controller.value.clamp(0.0, 1.0));
              final countTo =
                  (widget.score * Curves.easeOut.transform(_controller.value))
                      .round();
              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: t,
                        child: Text(_emoji,
                            style: const TextStyle(fontSize: 72)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _headline,
                        style: TextStyle(
                          fontSize: widget.newRecord ? 34 : 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: widget.newRecord
                              ? const Color(0xFFFFD700)
                              : Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$countTo',
                        style: const TextStyle(
                          fontSize: 84,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'POINTS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _stat('⭐', '+${widget.stars}', 'STARS'),
                          _stat('🫧', '${widget.pops}', 'POPS'),
                          _stat('🔗', 'x${widget.bestCombo}', 'COMBO'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Best: ${save.highScore}   •   Star bank: ${save.stars}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _button('PLAY AGAIN', const Color(0xFF6BCB77),
                          Icons.replay_rounded, _again),
                      const SizedBox(height: 12),
                      _button('SPEND STARS', const Color(0xFFFF9F45),
                          Icons.storefront_rounded, _shop,
                          small: true),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _home,
                        icon: const Icon(Icons.home_rounded,
                            color: Colors.white70),
                        label: const Text(
                          'HOME',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, Color color, IconData icon, VoidCallback onTap,
      {bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 26 : 40, vertical: small ? 12 : 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: small ? 22 : 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: small ? 17 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
