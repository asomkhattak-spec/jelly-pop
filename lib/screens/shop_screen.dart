import 'package:flutter/material.dart';

import '../game/sound.dart';
import '../game/storage.dart';
import '../game/themes.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  Future<void> _selectOrBuy(JellyTheme theme) async {
    final save = SaveData.instance;
    final unlocked = save.unlockedThemes.contains(theme.id);
    if (unlocked) {
      SoundManager.instance.tap();
      await save.selectTheme(theme.id);
      setState(() {});
      return;
    }
    if (save.stars >= theme.cost) {
      await save.setStars(save.stars - theme.cost);
      await save.unlockTheme(theme.id);
      await save.selectTheme(theme.id);
      SoundManager.instance.star();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF6BCB77),
          behavior: SnackBarBehavior.floating,
          content: Text(
            '${theme.emoji} ${theme.name} unlocked!',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ));
      }
    } else {
      SoundManager.instance.bomb();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFFF5D8F),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Need ${theme.cost - save.stars} more stars — catch ⭐ in game!',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    final selected = save.selectedTheme;
    final unlocked = save.unlockedThemes;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF70A6), Color(0xFFFF9770)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        SoundManager.instance.tap();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const Expanded(
                      child: Text(
                        'JELLY SHOP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '${save.stars}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Catch ⭐ stars in game to unlock new looks!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: kThemes.length,
                  itemBuilder: (context, i) {
                    final theme = kThemes[i];
                    final isUnlocked = unlocked.contains(theme.id);
                    final isSelected = selected == theme.id;
                    final affordable = save.stars >= theme.cost;
                    return GestureDetector(
                      onTap: () => _selectOrBuy(theme),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.bgTop, theme.bgBottom],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFD700)
                                : Colors.white.withOpacity(0.5),
                            width: isSelected ? 4 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(theme.emoji,
                                style: const TextStyle(fontSize: 34)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme.name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: theme.jellies
                                        .take(6)
                                        .map((c) => Container(
                                              width: 18,
                                              height: 18,
                                              margin: const EdgeInsets.only(
                                                  right: 5),
                                              decoration: BoxDecoration(
                                                color: c,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const _Badge(
                                  label: 'USING',
                                  color: Color(0xFFFFD700),
                                  textColor: Color(0xFF7A5C00))
                            else if (isUnlocked)
                              const _Badge(
                                  label: 'USE',
                                  color: Colors.white,
                                  textColor: Color(0xFF5B4DFF))
                            else
                              _Badge(
                                label: '⭐ ${theme.cost}',
                                color: affordable
                                    ? const Color(0xFF6BCB77)
                                    : Colors.black.withOpacity(0.3),
                                textColor: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}
