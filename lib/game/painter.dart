import 'dart:math';

import 'package:flutter/material.dart';

import 'entities.dart';
import 'engine.dart';
import 'themes.dart';

/// Renders the whole play field with a single CustomPainter:
/// gradient background, drifting bubbles, jellies with faces, particles,
/// floating score text, fever glow and screen shake.
class GamePainter extends CustomPainter {
  GamePainter({
    required this.engine,
    required this.theme,
    required this.time,
  });

  final GameEngine engine;
  final JellyTheme theme;
  final double time;

  static final Random _bubbleRng = Random(7);
  static final List<Offset> _bubbleSeeds =
      List.generate(14, (_) => Offset(_bubbleRng.nextDouble(), _bubbleRng.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Background gradient (fever shifts it warmer).
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: engine.inFever
            ? [theme.bgBottom, theme.bgTop]
            : [theme.bgTop, theme.bgBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Ambient bubbles drifting upward.
    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.07);
    for (var i = 0; i < _bubbleSeeds.length; i++) {
      final seed = _bubbleSeeds[i];
      final speed = 18.0 + (i % 5) * 9;
      final y = h - ((seed.dy * h + time * speed) % (h + 80)) + 40;
      final x = seed.dx * w + sin(time * 0.7 + i) * 14;
      canvas.drawCircle(Offset(x, y), 8 + (i % 4) * 7.0, bubblePaint);
    }

    // Screen shake on bomb hits.
    if (engine.shake > 0) {
      final s = engine.shake * 10;
      canvas.translate(sin(time * 70) * s, cos(time * 63) * s);
    }

    // Jellies.
    for (final j in engine.jellies) {
      _drawJelly(canvas, j);
    }

    // Particles.
    for (final p in engine.particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final color = p.colorIndex == -2
          ? const Color(0xFFFFD700)
          : p.colorIndex == -3
              ? const Color(0xFF2D2D3A)
              : theme.jellies[p.colorIndex % theme.jellies.length];
      final paint = Paint()..color = color.withOpacity(t);
      if (p.isStar) {
        _drawStarShape(canvas, Offset(p.x, p.y), p.r * 1.6, paint,
            rotation: time * 4 + p.x);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.r * t, paint);
      }
    }

    // Floating text.
    for (final t in engine.floatTexts) {
      final alpha = (t.life / t.maxLife).clamp(0.0, 1.0);
      final color = t.colorIndex == -2
          ? const Color(0xFFFFD700)
          : t.colorIndex == -3
              ? const Color(0xFFFF5252)
              : Colors.white;
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            fontSize: 20 * t.scale,
            fontWeight: FontWeight.w900,
            color: color.withOpacity(alpha),
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(alpha * 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(t.x - tp.width / 2, t.y - tp.height / 2));
    }

    // Fever vignette.
    if (engine.inFever) {
      final pulse = 0.12 + 0.06 * sin(time * 8);
      final rect = Rect.fromLTWH(0, 0, w, h);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0xFFFFD700).withOpacity(pulse)],
          stops: const [0.55, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  void _drawJelly(Canvas canvas, Jelly j) {
    final squash = 1 + 0.08 * sin(j.wobblePhase);
    final rx = j.r * squash;
    final ry = j.r / squash;
    final center = Offset(j.x, j.y);

    switch (j.kind) {
      case JellyKind.bomb:
        _drawBomb(canvas, j, center, rx, ry);
        return;
      case JellyKind.star:
        _drawStarJelly(canvas, j, center);
        return;
      case JellyKind.golden:
        _drawBlobBody(canvas, center, rx, ry, const Color(0xFFFFD700),
            const Color(0xFFFFB300));
        _drawFace(canvas, j, center, rx, ry, happy: true);
        // Sparkle marks.
        final sp = Paint()..color = Colors.white.withOpacity(0.9);
        final a = time * 3 + j.id;
        for (var k = 0; k < 3; k++) {
          final ang = a + k * 2.09;
          _drawStarShape(
            canvas,
            center + Offset(cos(ang) * rx * 1.25, sin(ang) * ry * 1.25),
            4.5,
            sp,
            rotation: a,
          );
        }
        return;
      case JellyKind.normal:
        final base = theme.jellies[j.colorIndex % theme.jellies.length];
        final dark = Color.lerp(base, Colors.black, 0.25)!;
        _drawBlobBody(canvas, center, rx, ry, base, dark);
        _drawFace(canvas, j, center, rx, ry);
        return;
    }
  }

  void _drawBlobBody(
      Canvas canvas, Offset c, double rx, double ry, Color base, Color dark) {
    // Soft drop shadow.
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, ry * 0.18), width: rx * 2, height: ry * 2),
      Paint()..color = Colors.black.withOpacity(0.15),
    );
    final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [Color.lerp(base, Colors.white, 0.35)!, base, dark],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(rect),
    );
    // Glossy highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-rx * 0.35, -ry * 0.45),
        width: rx * 0.55,
        height: ry * 0.32,
      ),
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }

  void _drawFace(Canvas canvas, Jelly j, Offset c, double rx, double ry,
      {bool happy = false}) {
    final eyePaint = Paint()..color = const Color(0xFF26233A);
    final eyeY = c.dy - ry * 0.12;
    final eyeDx = rx * 0.32;
    final blink = sin(j.wobblePhase * 0.5 + j.id * 3) > 0.97;

    if (blink) {
      final p = Paint()
        ..color = const Color(0xFF26233A)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(c.dx - eyeDx - 4, eyeY), Offset(c.dx - eyeDx + 4, eyeY), p);
      canvas.drawLine(Offset(c.dx + eyeDx - 4, eyeY), Offset(c.dx + eyeDx + 4, eyeY), p);
    } else {
      canvas.drawCircle(Offset(c.dx - eyeDx, eyeY), rx * 0.10, eyePaint);
      canvas.drawCircle(Offset(c.dx + eyeDx, eyeY), rx * 0.10, eyePaint);
      // Eye sparkle.
      final glint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(c.dx - eyeDx + 1.5, eyeY - 1.5), rx * 0.035, glint);
      canvas.drawCircle(Offset(c.dx + eyeDx + 1.5, eyeY - 1.5), rx * 0.035, glint);
    }

    // Smile.
    final mouth = Paint()
      ..color = const Color(0xFF26233A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final mouthRect = Rect.fromCenter(
      center: c + Offset(0, ry * 0.18),
      width: rx * (happy ? 0.62 : 0.44),
      height: ry * (happy ? 0.5 : 0.34),
    );
    canvas.drawArc(mouthRect, 0.25, pi - 0.5, false, mouth);

    // Blush.
    final blush = Paint()..color = Colors.white.withOpacity(0.30);
    canvas.drawCircle(Offset(c.dx - rx * 0.55, c.dy + ry * 0.10), rx * 0.13, blush);
    canvas.drawCircle(Offset(c.dx + rx * 0.55, c.dy + ry * 0.10), rx * 0.13, blush);
  }

  void _drawBomb(Canvas canvas, Jelly j, Offset c, double rx, double ry) {
    final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, ry * 0.18), width: rx * 2, height: ry * 2),
      Paint()..color = Colors.black.withOpacity(0.2),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [const Color(0xFF5C5C70), const Color(0xFF2B2B3A)],
        ).createShader(rect),
    );
    // Fuse.
    final fuse = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(c.dx, c.dy - ry * 0.9)
      ..quadraticBezierTo(c.dx + rx * 0.3, c.dy - ry * 1.35, c.dx + rx * 0.55, c.dy - ry * 1.2);
    canvas.drawPath(path, fuse);
    // Spark at fuse tip — flickers.
    final sparkOn = sin(time * 20 + j.id) > -0.3;
    if (sparkOn) {
      final tip = Offset(c.dx + rx * 0.55, c.dy - ry * 1.2);
      canvas.drawCircle(tip, 5.5, Paint()..color = const Color(0xFFFFC107));
      canvas.drawCircle(tip, 2.8, Paint()..color = Colors.white);
    }
    // Angry eyebrows + frown so kids read "bad" instantly.
    final p = Paint()
      ..color = const Color(0xFFFF8A80)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final eyeY = c.dy - ry * 0.1;
    canvas.drawLine(Offset(c.dx - rx * 0.45, eyeY - ry * 0.22),
        Offset(c.dx - rx * 0.12, eyeY - ry * 0.06), p);
    canvas.drawLine(Offset(c.dx + rx * 0.45, eyeY - ry * 0.22),
        Offset(c.dx + rx * 0.12, eyeY - ry * 0.06), p);
    canvas.drawCircle(Offset(c.dx - rx * 0.3, eyeY + ry * 0.08), rx * 0.09,
        Paint()..color = const Color(0xFFFF8A80));
    canvas.drawCircle(Offset(c.dx + rx * 0.3, eyeY + ry * 0.08), rx * 0.09,
        Paint()..color = const Color(0xFFFF8A80));
    final frown = Paint()
      ..color = const Color(0xFFFF8A80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
          center: c + Offset(0, ry * 0.5), width: rx * 0.4, height: ry * 0.3),
      pi + 0.4,
      pi - 0.8,
      false,
      frown,
    );
  }

  void _drawStarJelly(Canvas canvas, Jelly j, Offset c) {
    final rot = sin(j.wobblePhase * 0.6) * 0.25;
    final glow = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.25 + 0.1 * sin(time * 5));
    canvas.drawCircle(c, j.r * 1.35, glow);
    _drawStarShape(canvas, c, j.r * 1.15, Paint()..color = const Color(0xFFFFD700),
        rotation: rot);
    _drawStarShape(
        canvas, c, j.r * 0.78, Paint()..color = const Color(0xFFFFEE58),
        rotation: rot);
    // Tiny happy face on the star.
    final eye = Paint()..color = const Color(0xFF7A5C00);
    canvas.drawCircle(c + Offset(-j.r * 0.22, -j.r * 0.05), 2.6, eye);
    canvas.drawCircle(c + Offset(j.r * 0.22, -j.r * 0.05), 2.6, eye);
    final smile = Paint()
      ..color = const Color(0xFF7A5C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: c + Offset(0, j.r * 0.16), width: j.r * 0.36, height: j.r * 0.26),
      0.3,
      pi - 0.6,
      false,
      smile,
    );
  }

  void _drawStarShape(Canvas canvas, Offset c, double r, Paint paint,
      {double rotation = 0}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final ang = rotation - pi / 2 + i * pi / 5;
      final rad = i.isEven ? r : r * 0.45;
      final pt = c + Offset(cos(ang) * rad, sin(ang) * rad);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
