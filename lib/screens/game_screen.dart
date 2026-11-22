import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/engine.dart';
import '../game/entities.dart';
import '../game/painter.dart';
import '../game/sound.dart';
import '../game/storage.dart';
import '../game/themes.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  GameEngine? _engine;
  late final Ticker _ticker;
  late JellyTheme _theme;
  Duration _last = Duration.zero;
  double _clock = 0;

  int _countdown = 3; // 3,2,1 then GO (0), then -1 = playing
  double _countdownTimer = 0;
  bool _paused = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _theme = themeById(SaveData.instance.selectedTheme);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureEngine(Size size) {
    if (_engine != null || size.isEmpty) return;
    _engine = GameEngine(width: size.width, height: size.height);
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _clock += dt;
    final engine = _engine;
    if (engine == null || _paused || _finished) {
      if (mounted) setState(() {});
      return;
    }

    if (_countdown >= 0) {
      _countdownTimer += dt;
      if (_countdownTimer >= 0.7) {
        _countdownTimer = 0;
        _countdown--;
        if (_countdown == 0) {
          SoundManager.instance.go();
        } else if (_countdown < 0) {
          engine.start();
        } else {
          SoundManager.instance.tick();
        }
      }
      setState(() {});
      return;
    }

    engine.update(dt);
    _consumeEvents(engine);
    setState(() {});
  }

  void _consumeEvents(GameEngine engine) {
    final save = SaveData.instance;
    for (final e in engine.drainEvents()) {
      switch (e.type) {
        case GameEventType.popped:
          SoundManager.instance.pop(e.combo);
          if (save.haptics) HapticFeedback.selectionClick();
          break;
        case GameEventType.goldenPopped:
          SoundManager.instance.golden();
          if (save.haptics) HapticFeedback.mediumImpact();
          break;
        case GameEventType.starCollected:
          SoundManager.instance.star();
          if (save.haptics) HapticFeedback.lightImpact();
          break;
        case GameEventType.bombHit:
          SoundManager.instance.bomb();
          if (save.haptics) HapticFeedback.heavyImpact();
          break;
        case GameEventType.feverStarted:
          SoundManager.instance.fever();
          if (save.haptics) HapticFeedback.mediumImpact();
          break;
        case GameEventType.feverEnded:
          break;
        case GameEventType.roundOver:
          _finish(engine);
          break;
      }
    }
  }

  Future<void> _finish(GameEngine engine) async {
    if (_finished) return;
    _finished = true;
    final save = SaveData.instance;
    final newRecord = engine.score > save.highScore;
    await save.addStars(engine.starsEarned);
    await save.addPops(engine.pops);
    await save.incGames();
    await save.setBestComboEver(engine.bestCombo);
    if (newRecord) await save.setHighScore(engine.score);
    if (newRecord) {
      SoundManager.instance.record();
    } else {
      SoundManager.instance.over();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        score: engine.score,
        bestCombo: engine.bestCombo,
        stars: engine.starsEarned,
        pops: engine.pops,
        newRecord: newRecord,
        heartsLeft: engine.hearts,
      ),
    ));
  }

  void _onTapDown(TapDownDetails d) {
    final engine = _engine;
    if (engine == null || _countdown >= 0 || _paused || _finished) return;
    engine.tap(d.localPosition.dx, d.localPosition.dy);
  }

  void _togglePause() {
    if (_countdown >= 0 || _finished) return;
    SoundManager.instance.tap();
    setState(() => _paused = !_paused);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _ensureEngine(size);
          final engine = _engine;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: GamePainter(
                    engine: engine ??
                        GameEngine(width: size.width, height: size.height),
                    theme: _theme,
                    time: _clock,
                  ),
                ),
                if (engine != null) _hud(engine),
                if (_countdown >= 0) _countdownOverlay(),
                if (_paused) _pauseOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hud(GameEngine engine) {
    final playing = _countdown < 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                // Score.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${engine.score}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Hearts.
                Row(
                  children: List.generate(GameEngine.startingHearts, (i) {
                    final alive = i < engine.hearts;
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        alive
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: alive
                            ? const Color(0xFFFF5D8F)
                            : Colors.white.withOpacity(0.4),
                        size: 26,
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // Stars this round.
                Icon(Icons.star_rounded,
                    color: const Color(0xFFFFD700), size: 24),
                Text(
                  '${engine.starsEarned}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                // Timer.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: engine.timeLeft <= 10 && playing
                        ? const Color(0xFFFF5252).withOpacity(0.8)
                        : Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${engine.timeLeft.ceil()}s',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pause_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fever meter / fever timer.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.black.withOpacity(0.25)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: engine.inFever
                          ? (engine.feverTime / GameEngine.feverDuration)
                              .clamp(0.0, 1.0)
                          : engine.feverCharge.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: engine.inFever
                                ? [
                                    const Color(0xFFFFD700),
                                    const Color(0xFFFF6D00)
                                  ]
                                : [
                                    const Color(0xFFFFEE58),
                                    const Color(0xFFFFD700)
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (engine.inFever)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🔥 FEVER — DOUBLE POINTS! 🔥',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: const Color(0xFFFFD700),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            if (playing && engine.combo >= 3 && !engine.inFever)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'COMBO x${engine.combo}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _countdownOverlay() {
    final label = _countdown == 0 ? 'GO!' : '$_countdown';
    return Container(
      color: Colors.black.withOpacity(0.35),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_countdown),
        tween: Tween(begin: 1.6, end: 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 110,
            fontWeight: FontWeight.w900,
            color: _countdown == 0 ? const Color(0xFF6BCB77) : Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.55),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PAUSED',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6BCB77),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: _togglePause,
            icon: const Icon(Icons.play_arrow_rounded, size: 30),
            label: const Text(
              'KEEP POPPING',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              SoundManager.instance.tap();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.home_rounded, color: Colors.white70),
            label: const Text(
              'QUIT TO HOME',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
