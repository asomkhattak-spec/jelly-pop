import 'dart:math';

import 'entities.dart';

/// Core simulation for Jelly Pop!
///
/// Jellies float up from the bottom of the screen. Tap them to pop.
/// - normal: points, builds combo + fever charge
/// - golden: big points, big fever charge
/// - star:   collectible currency for the skin shop
/// - bomb:   do NOT tap — costs a heart, kills the combo, shakes the screen
///
/// A round lasts [roundSeconds] or until hearts run out. Fever mode triggers
/// when the charge meter fills: 8 seconds of double points, faster spawns and
/// no bombs.
class GameEngine {
  GameEngine({
    required this.width,
    required this.height,
    Random? rng,
    this.roundSeconds = 60,
  }) : rng = rng ?? Random();

  final double width;
  final double height;
  final Random rng;
  final int roundSeconds;

  // --- tuning constants -------------------------------------------------
  static const double comboWindow = 1.6;
  static const double feverDuration = 8.0;
  static const double feverDecay = 0.025;
  static const double feverPerPop = 0.055;
  static const double feverPerGolden = 0.20;
  static const double tapForgiveness = 1.4; // kid-sized hit boxes
  static const int maxJellies = 26;
  static const int maxParticles = 260;
  static const int startingHearts = 3;

  // --- state -------------------------------------------------------------
  final List<Jelly> jellies = [];
  final List<Particle> particles = [];
  final List<FloatText> floatTexts = [];
  final List<GameEvent> _events = [];

  int score = 0;
  int hearts = startingHearts;
  int combo = 0;
  int bestCombo = 0;
  int starsEarned = 0;
  int pops = 0;
  double timeLeft = 0;
  double elapsed = 0;
  double feverCharge = 0;
  double feverTime = 0;
  double comboTimer = 0;
  double shake = 0;
  bool running = false;
  bool over = false;

  double _spawnTimer = 0.4;
  int _nextId = 0;

  bool get inFever => feverTime > 0;
  int get level => (elapsed / 15).floor();
  int get comboMultiplier => inFever ? 2 : 1;

  List<GameEvent> drainEvents() {
    final out = List<GameEvent>.of(_events);
    _events.clear();
    return out;
  }

  void start() {
    jellies.clear();
    particles.clear();
    floatTexts.clear();
    _events.clear();
    score = 0;
    hearts = startingHearts;
    combo = 0;
    bestCombo = 0;
    starsEarned = 0;
    pops = 0;
    elapsed = 0;
    timeLeft = roundSeconds.toDouble();
    feverCharge = 0;
    feverTime = 0;
    comboTimer = 0;
    shake = 0;
    over = false;
    running = true;
    _spawnTimer = 0.25;
    // Seed a few jellies mid-screen so the first second is never empty.
    for (var i = 0; i < 4; i++) {
      _spawn(seedY: height * (0.45 + 0.12 * i));
    }
  }

  void update(double dt) {
    if (!running) return;
    dt = clampD(dt, 0, 0.05); // tab-switch / hitch guard
    elapsed += dt;
    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      _endRound();
      return;
    }

    // Fever + combo timers.
    if (inFever) {
      feverTime -= dt;
      if (feverTime <= 0) {
        feverTime = 0;
        feverCharge = 0;
        _events.add(const GameEvent(GameEventType.feverEnded));
      }
    } else {
      feverCharge = clampD(feverCharge - feverDecay * dt, 0, 1);
    }
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }
    shake = max(0, shake - dt * 2.2);

    // Spawning.
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && jellies.length < maxJellies) {
      _spawn();
      final base = max(0.34, 0.95 - level * 0.09);
      _spawnTimer = inFever ? base * 0.55 : base;
      _spawnTimer *= 0.8 + rng.nextDouble() * 0.4;
    }

    // Jelly motion: buoyant rise with a lazy horizontal sway.
    for (final j in jellies) {
      j.age += dt;
      j.wobblePhase += j.wobbleSpeed * dt;
      j.x += j.vx * dt;
      j.y += j.vy * dt;
      j.vx += sin(j.age * 1.7 + j.id) * 6 * dt;
      if (j.x < j.r) {
        j.x = j.r;
        j.vx = j.vx.abs();
      } else if (j.x > width - j.r) {
        j.x = width - j.r;
        j.vx = -j.vx.abs();
      }
      if (j.y < -j.r * 1.5) j.dead = true; // escaped off the top
    }
    jellies.removeWhere((j) => j.dead);

    // Particles.
    for (final p in particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 520 * dt;
      p.vx *= 1 - 1.6 * dt;
    }
    particles.removeWhere((p) => p.life <= 0);

    // Floating score text.
    for (final t in floatTexts) {
      t.life -= dt;
      t.y -= 55 * dt;
    }
    floatTexts.removeWhere((t) => t.life <= 0);
  }

  /// Returns true if the tap consumed a jelly.
  bool tap(double x, double y) {
    if (!running) return false;
    // Topmost (last drawn) jelly wins when hit boxes overlap.
    for (var i = jellies.length - 1; i >= 0; i--) {
      final j = jellies[i];
      final dx = x - j.x, dy = y - j.y;
      final hitR = j.r * tapForgiveness;
      if (dx * dx + dy * dy <= hitR * hitR) {
        _resolveTap(j);
        return true;
      }
    }
    return false;
  }

  void _resolveTap(Jelly j) {
    j.dead = true;
    jellies.remove(j);
    switch (j.kind) {
      case JellyKind.bomb:
        hearts--;
        combo = 0;
        comboTimer = 0;
        shake = 1.0;
        feverCharge = clampD(feverCharge - 0.25, 0, 1);
        _burst(j, 18, dark: true);
        floatTexts.add(FloatText(
          text: 'OUCH!',
          x: j.x,
          y: j.y,
          colorIndex: -3,
          scale: 1.3,
          life: 1.0,
        ));
        _events.add(GameEvent(GameEventType.bombHit, x: j.x, y: j.y));
        if (hearts <= 0) _endRound();
        return;
      case JellyKind.star:
        starsEarned++;
        _burst(j, 12, star: true);
        floatTexts.add(FloatText(
          text: '+1 STAR',
          x: j.x,
          y: j.y,
          colorIndex: -2,
          scale: 1.1,
        ));
        _events.add(GameEvent(GameEventType.starCollected, x: j.x, y: j.y));
        return;
      case JellyKind.golden:
      case JellyKind.normal:
        break;
    }

    combo++;
    comboTimer = comboWindow;
    bestCombo = max(bestCombo, combo);
    pops++;
    final golden = j.kind == JellyKind.golden;
    final base = golden ? 50 + combo * 5 : 10 + combo * 2;
    final points = base * comboMultiplier;
    score += points;

    if (!inFever) {
      feverCharge = clampD(
        feverCharge + (golden ? feverPerGolden : feverPerPop),
        0,
        1,
      );
      if (feverCharge >= 1) {
        feverTime = feverDuration;
        _events.add(const GameEvent(GameEventType.feverStarted));
        floatTexts.add(FloatText(
          text: 'FEVER!',
          x: width / 2,
          y: height * 0.35,
          colorIndex: -2,
          scale: 2.2,
          life: 1.4,
        ));
        // Clear live bombs so fever is pure joy.
        jellies.removeWhere((j) => j.kind == JellyKind.bomb);
      }
    }

    _burst(j, golden ? 16 : 10);
    floatTexts.add(FloatText(
      text: '+$points',
      x: j.x,
      y: j.y,
      colorIndex: golden ? -2 : -1,
      scale: golden ? 1.3 : 1.0,
    ));
    if (combo > 0 && combo % 10 == 0) {
      floatTexts.add(FloatText(
        text: 'COMBO x$combo!',
        x: width / 2,
        y: height * 0.28,
        colorIndex: -2,
        scale: 1.6,
        life: 1.1,
      ));
    }
    _events.add(GameEvent(
      golden ? GameEventType.goldenPopped : GameEventType.popped,
      points: points,
      combo: combo,
      x: j.x,
      y: j.y,
      colorIndex: j.colorIndex,
    ));
  }

  void _endRound() {
    if (over) return;
    over = true;
    running = false;
    _events.add(GameEvent(GameEventType.roundOver, points: score));
  }

  void _spawn({double? seedY}) {
    final r = 30 + rng.nextDouble() * 16;
    final x = r + rng.nextDouble() * (width - r * 2);
    final y = seedY ?? height + r * 1.2;
    final speed = 62 + level * 13 + rng.nextDouble() * 42;

    var kind = JellyKind.normal;
    final roll = rng.nextDouble();
    if (elapsed > 8 && !inFever) {
      final bombChance = min(0.13, 0.05 + level * 0.015);
      if (roll < bombChance) {
        kind = JellyKind.bomb;
      } else if (roll < bombChance + 0.07) {
        kind = JellyKind.golden;
      } else if (roll < bombChance + 0.07 + 0.08) {
        kind = JellyKind.star;
      }
    } else if (roll < 0.07) {
      kind = JellyKind.golden;
    } else if (roll < 0.15) {
      kind = JellyKind.star;
    }

    jellies.add(Jelly(
      id: _nextId++,
      kind: kind,
      colorIndex: rng.nextInt(6),
      x: x,
      y: y,
      vx: (rng.nextDouble() - 0.5) * 30,
      vy: -speed * (kind == JellyKind.star ? 1.15 : 1.0),
      r: kind == JellyKind.bomb ? r * 0.92 : r,
      wobblePhase: rng.nextDouble() * pi * 2,
      wobbleSpeed: 4 + rng.nextDouble() * 3,
    ));
  }

  void _burst(Jelly j, int count, {bool star = false, bool dark = false}) {
    if (particles.length > maxParticles) return;
    for (var i = 0; i < count; i++) {
      final a = rng.nextDouble() * pi * 2;
      final sp = 90 + rng.nextDouble() * 240;
      particles.add(Particle(
        x: j.x,
        y: j.y,
        vx: cos(a) * sp,
        vy: sin(a) * sp - 120,
        r: 3 + rng.nextDouble() * (star ? 4 : 6),
        life: 0.45 + rng.nextDouble() * 0.4,
        colorIndex: dark ? -3 : (star ? -2 : j.colorIndex),
        isStar: star,
      ));
    }
  }
}
