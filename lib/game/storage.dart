import 'package:shared_preferences/shared_preferences.dart';

/// All persistence: high score, star bank, unlocked themes, settings.
class SaveData {
  SaveData._(this._prefs);
  final SharedPreferences _prefs;

  static late SaveData instance;

  static Future<void> init() async {
    instance = SaveData._(await SharedPreferences.getInstance());
  }

  int get highScore => _prefs.getInt('highScore') ?? 0;
  Future<void> setHighScore(int v) => _prefs.setInt('highScore', v);

  int get stars => _prefs.getInt('stars') ?? 0;
  Future<void> setStars(int v) => _prefs.setInt('stars', v);
  Future<void> addStars(int v) => setStars(stars + v);

  int get totalPops => _prefs.getInt('totalPops') ?? 0;
  Future<void> addPops(int v) => _prefs.setInt('totalPops', totalPops + v);

  int get gamesPlayed => _prefs.getInt('gamesPlayed') ?? 0;
  Future<void> incGames() => _prefs.setInt('gamesPlayed', gamesPlayed + 1);

  int get bestComboEver => _prefs.getInt('bestComboEver') ?? 0;
  Future<void> setBestComboEver(int v) =>
      _prefs.setInt('bestComboEver', v > bestComboEver ? v : bestComboEver);

  List<String> get unlockedThemes =>
      _prefs.getStringList('unlockedThemes') ?? ['party'];
  Future<void> unlockTheme(String id) async {
    final list = unlockedThemes;
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList('unlockedThemes', list);
    }
  }

  String get selectedTheme => _prefs.getString('selectedTheme') ?? 'party';
  Future<void> selectTheme(String id) => _prefs.setString('selectedTheme', id);

  bool get muted => _prefs.getBool('muted') ?? false;
  Future<void> setMuted(bool v) => _prefs.setBool('muted', v);

  bool get haptics => _prefs.getBool('haptics') ?? true;
  Future<void> setHaptics(bool v) => _prefs.setBool('haptics', v);
}
