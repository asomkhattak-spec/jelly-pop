import 'dart:math';

import 'package:flutter/material.dart';

import '../game/sound.dart';
import '../game/storage.dart';
import '../game/themes.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    SoundManager.instance.tap();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GameScreen()))
        .then((_) => setState(() {}));
  }

  void _shop() {
    SoundManager.instance.tap();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ShopScreen()))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    final theme = themeById(save.selectedTheme);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * pi;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.bgTop, theme.bgBottom],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating decorative jellies.
                  ...List.generate(6, (i) {
                    final x = size.width * (0.08 + 0.16 * i) +
                        sin(t + i * 1.3) * 18;
                    final y = size.height * (i.isEven ? 0.13 : 0.78) +
                        cos(t * 0.8 + i) * 22;
                    final r = 22.0 + (i % 3) * 10;
                    return Positioned(
                      left: x,
                      top: y,
                      child: _MiniJelly(
                        color: theme.jellies[i % theme.jellies.length],
                        radius: r,
                        squash: 1 + 0.08 * sin(t * 2 + i),
                      ),
                    );
                  }),
                  // Mute button.
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      iconSize: 30,
                      color: Colors.white,
                      icon: Icon(save.muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded),
                      onPressed: () {
                        final m = !save.muted;
                        save.setMuted(m);
                        SoundManager.instance.setMuted(m);
                        if (!m) SoundManager.instance.tap();
                        setState(() {});
                      },
                    ),
                  ),
                  // Main column.
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, sin(t * 1.5) * 6),
                          child: Column(
                            children: [
                              Text(
                                'JELLY',
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.rotate(
                                angle: sin(t) * 0.03,
                                child: Text(
                                  'POP!',
                                  style: TextStyle(
                                    fontSize: 76,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    color: const Color(0xFFFFD700),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the jellies. Dodge the bombs!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _BigButton(
                          label: 'PLAY',
                          color: const Color(0xFF6BCB77),
                          icon: Icons.play_arrow_rounded,
                          pulse: 1 + 0.03 * sin(t * 3),
                          onTap: _play,
                        ),
                        const SizedBox(height: 16),
                        _BigButton(
                          label: 'JELLY SHOP',
                          color: const Color(0xFFFF9F45),
                          icon: Icons.storefront_rounded,
                          pulse: 1.0,
                          onTap: _shop,
                          small: true,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatChip(
                              icon: Icons.emoji_events_rounded,
                              label: 'BEST',
                              value: '${save.highScore}',
                              color: const Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 14),
                            _StatChip(
                              icon: Icons.star_rounded,
                              label: 'STARS',
                              value: '${save.stars}',
                              color: const Color(0xFFFFEE58),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniJelly extends StatelessWidget {
  const _MiniJelly({
    required this.color,
    required this.radius,
    required this.squash,
  });
  final Color color;
  final double radius;
  final double squash;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: squash,
      scaleY: 1 / squash,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.45),
            colors: [
              Color.lerp(color, Colors.white, 0.35)!,
              color,
              Color.lerp(color, Colors.black, 0.25)!,
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: radius * 0.55,
              left: radius * 0.5,
              child: _eye(radius),
            ),
            Positioned(
              top: radius * 0.55,
              right: radius * 0.5,
              child: _eye(radius),
            ),
            Positioned(
              top: radius * 0.95,
              child: Container(
                width: radius * 0.5,
                height: radius * 0.28,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF26233A),
                      width: 2.4,
                      style: BorderStyle.solid,
                    ),
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(radius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eye(double r) => Container(
        width: r * 0.2,
        height: r * 0.2,
        decoration: const BoxDecoration(
          color: Color(0xFF26233A),
          shape: BoxShape.circle,
        ),
      );
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.pulse,
    required this.onTap,
    this.small = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final double pulse;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: pulse,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 28 : 46,
            vertical: small ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: small ? 24 : 34),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 20 : 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
