import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jelly_pop/game/engine.dart';
import 'package:jelly_pop/game/entities.dart';

void main() {
  GameEngine makeEngine() =>
      GameEngine(width: 400, height: 800, rng: Random(42));

  test('start seeds jellies and resets state', () {
    final e = makeEngine();
    e.start();
    expect(e.running, true);
    expect(e.score, 0);
    expect(e.hearts, GameEngine.startingHearts);
    expect(e.jellies.length, 4);
    expect(e.timeLeft, 60);
  });

  test('tapping a normal jelly scores points and builds combo', () {
    final e = makeEngine();
    e.start();
    final target = Jelly(
      id: 999,
      kind: JellyKind.normal,
      colorIndex: 0,
      x: 200,
      y: 400,
      vx: 0,
      vy: 0,
      r: 40,
      wobblePhase: 0,
      wobbleSpeed: 5,
    );
    e.jellies.add(target);
    expect(e.tap(200, 400), true);
    expect(e.score, greaterThan(0));
    expect(e.combo, 1);
    expect(e.pops, 1);
  });

  test('miss tap consumes nothing', () {
    final e = makeEngine();
    e.start();
    e.jellies.clear();
    expect(e.tap(10, 10), false);
    expect(e.score, 0);
  });

  test('bomb costs a heart and resets combo', () {
    final e = makeEngine();
    e.start();
    e.combo = 5;
    e.jellies.add(Jelly(
      id: 1000,
      kind: JellyKind.bomb,
      colorIndex: 0,
      x: 100,
      y: 100,
      vx: 0,
      vy: 0,
      r: 35,
      wobblePhase: 0,
      wobbleSpeed: 5,
    ));
    expect(e.tap(100, 100), true);
    expect(e.hearts, GameEngine.startingHearts - 1);
    expect(e.combo, 0);
    expect(e.shake, greaterThan(0));
  });

  test('three bombs end the round', () {
    final e = makeEngine();
    e.start();
    for (var i = 0; i < 3; i++) {
      e.jellies.add(Jelly(
        id: 2000 + i,
        kind: JellyKind.bomb,
        colorIndex: 0,
        x: 50,
        y: 50,
        vx: 0,
        vy: 0,
        r: 35,
        wobblePhase: 0,
        wobbleSpeed: 5,
      ));
      e.tap(50, 50);
    }
    expect(e.over, true);
    expect(e.running, false);
    final events = e.drainEvents();
    expect(events.any((ev) => ev.type == GameEventType.roundOver), true);
  });

  test('star jelly adds currency, not score', () {
    final e = makeEngine();
    e.start();
    e.jellies.add(Jelly(
      id: 3000,
      kind: JellyKind.star,
      colorIndex: 0,
      x: 300,
      y: 300,
      vx: 0,
      vy: 0,
      r: 35,
      wobblePhase: 0,
      wobbleSpeed: 5,
    ));
    e.tap(300, 300);
    expect(e.starsEarned, 1);
    expect(e.score, 0);
  });

  test('fever triggers at full charge and doubles points', () {
    final e = makeEngine();
    e.start();
    e.feverCharge = 0.99;
    e.jellies.add(Jelly(
      id: 4000,
      kind: JellyKind.normal,
      colorIndex: 0,
      x: 200,
      y: 200,
      vx: 0,
      vy: 0,
      r: 40,
      wobblePhase: 0,
      wobbleSpeed: 5,
    ));
    e.tap(200, 200);
    expect(e.inFever, true);
    final scoreAfterFirst = e.score;
    e.jellies.add(Jelly(
      id: 4001,
      kind: JellyKind.normal,
      colorIndex: 1,
      x: 200,
      y: 200,
      vx: 0,
      vy: 0,
      r: 40,
      wobblePhase: 0,
      wobbleSpeed: 5,
    ));
    e.tap(200, 200);
    final secondPoints = e.score - scoreAfterFirst;
    expect(secondPoints, (10 + 2 * 2) * 2); // combo=2, fever x2
  });

  test('timer expiry ends round', () {
    final e = GameEngine(width: 400, height: 800, rng: Random(1), roundSeconds: 1);
    e.start();
    for (var i = 0; i < 100; i++) {
      e.update(0.02);
    }
    expect(e.over, true);
    expect(e.timeLeft, 0);
  });

  test('combo decays after window', () {
    final e = makeEngine();
    e.start();
    e.jellies.add(Jelly(
      id: 5000,
      kind: JellyKind.normal,
      colorIndex: 0,
      x: 10,
      y: 10,
      vx: 0,
      vy: 0,
      r: 40,
      wobblePhase: 0,
      wobbleSpeed: 5,
    ));
    e.tap(10, 10);
    expect(e.combo, 1);
    for (var i = 0; i < 100; i++) {
      e.update(0.02); // 2s > 1.6s window
    }
    expect(e.combo, 0);
  });

  test('simulation stays bounded over a full round', () {
    final e = makeEngine();
    e.start();
    for (var i = 0; i < 60 * 60; i++) {
      e.update(1 / 60);
      if (i % 20 == 0 && e.jellies.isNotEmpty) {
        final j = e.jellies.last;
        e.tap(j.x, j.y);
      }
      expect(e.jellies.length, lessThanOrEqualTo(GameEngine.maxJellies + 4));
      expect(e.particles.length, lessThanOrEqualTo(GameEngine.maxParticles + 30));
      if (e.over) break;
    }
    expect(e.score, greaterThan(0));
  });
}
