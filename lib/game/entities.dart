import 'dart:math';

/// Entity types for the Jelly Pop! game engine. Pure Dart — no Flutter imports,
/// so the whole simulation is unit-testable off-device.

enum JellyKind { normal, golden, bomb, star }

enum GameEventType {
  popped,
  goldenPopped,
  starCollected,
  bombHit,
  feverStarted,
  feverEnded,
  roundOver,
}

class GameEvent {
  final GameEventType type;
  final int points;
  final int combo;
  final double x;
  final double y;
  final int colorIndex;

  const GameEvent(
    this.type, {
    this.points = 0,
    this.combo = 0,
    this.x = 0,
    this.y = 0,
    this.colorIndex = 0,
  });
}

class Jelly {
  final int id;
  final JellyKind kind;
  final int colorIndex;
  double x;
  double y;
  double vx;
  double vy;
  final double r;
  double wobblePhase;
  final double wobbleSpeed;
  double age = 0;
  bool dead = false;

  Jelly({
    required this.id,
    required this.kind,
    required this.colorIndex,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.wobblePhase,
    required this.wobbleSpeed,
  });
}

class Particle {
  double x, y, vx, vy, r, life, maxLife;
  final int colorIndex;
  final bool isStar;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.life,
    required this.colorIndex,
    this.isStar = false,
  }) : maxLife = life;
}

class FloatText {
  final String text;
  double x, y, life;
  final double maxLife;
  final int colorIndex; // -1 = white, -2 = gold, -3 = red
  final double scale;

  FloatText({
    required this.text,
    required this.x,
    required this.y,
    this.life = 0.9,
    this.colorIndex = -1,
    this.scale = 1.0,
  }) : maxLife = life;
}

double clampD(double v, double lo, double hi) => max(lo, min(hi, v));
