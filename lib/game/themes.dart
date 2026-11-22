import 'package:flutter/material.dart';

/// Unlockable color themes. Stars earned in-game buy new looks.
class JellyTheme {
  final String id;
  final String name;
  final String emoji;
  final int cost;
  final Color bgTop;
  final Color bgBottom;
  final List<Color> jellies;

  const JellyTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.bgTop,
    required this.bgBottom,
    required this.jellies,
  });
}

const List<JellyTheme> kThemes = [
  JellyTheme(
    id: 'party',
    name: 'Jelly Party',
    emoji: '🎉',
    cost: 0,
    bgTop: Color(0xFF5B4DFF),
    bgBottom: Color(0xFF9B5CFF),
    jellies: [
      Color(0xFFFF5D8F),
      Color(0xFFFFC93C),
      Color(0xFF6BCB77),
      Color(0xFF4D96FF),
      Color(0xFFFF9F45),
      Color(0xFFB983FF),
    ],
  ),
  JellyTheme(
    id: 'ocean',
    name: 'Deep Sea',
    emoji: '🐠',
    cost: 30,
    bgTop: Color(0xFF0077B6),
    bgBottom: Color(0xFF00B4D8),
    jellies: [
      Color(0xFF90E0EF),
      Color(0xFFFFD166),
      Color(0xFFEF476F),
      Color(0xFF06D6A0),
      Color(0xFFF78C6B),
      Color(0xFFCAF0F8),
    ],
  ),
  JellyTheme(
    id: 'candy',
    name: 'Candy Shop',
    emoji: '🍭',
    cost: 60,
    bgTop: Color(0xFFFF70A6),
    bgBottom: Color(0xFFFF9770),
    jellies: [
      Color(0xFFFF477E),
      Color(0xFFFFD670),
      Color(0xFF70E000),
      Color(0xFF00B4D8),
      Color(0xFFFF99C8),
      Color(0xFFE0AAFF),
    ],
  ),
  JellyTheme(
    id: 'galaxy',
    name: 'Space Jam',
    emoji: '🚀',
    cost: 100,
    bgTop: Color(0xFF10002B),
    bgBottom: Color(0xFF3C096C),
    jellies: [
      Color(0xFFC77DFF),
      Color(0xFF7BF1A8),
      Color(0xFFFFD60A),
      Color(0xFFFF6D00),
      Color(0xFF4CC9F0),
      Color(0xFFF72585),
    ],
  ),
  JellyTheme(
    id: 'sunset',
    name: 'Sunset Splash',
    emoji: '🌅',
    cost: 150,
    bgTop: Color(0xFFFF512F),
    bgBottom: Color(0xFFDD2476),
    jellies: [
      Color(0xFFFFE066),
      Color(0xFFFF7B54),
      Color(0xFF6FFFE9),
      Color(0xFFFFB4A2),
      Color(0xFFB5E48C),
      Color(0xFFF9C74F),
    ],
  ),
  JellyTheme(
    id: 'neon',
    name: 'Neon Nights',
    emoji: '⚡',
    cost: 200,
    bgTop: Color(0xFF0F0C29),
    bgBottom: Color(0xFF302B63),
    jellies: [
      Color(0xFF00F5D4),
      Color(0xFFFEE440),
      Color(0xFFF15BB5),
      Color(0xFF00BBF9),
      Color(0xFF9B5DE5),
      Color(0xFFFF6F61),
    ],
  ),
];

JellyTheme themeById(String id) =>
    kThemes.firstWhere((t) => t.id == id, orElse: () => kThemes.first);
