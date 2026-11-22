# Jelly Pop! 🫧

A juicy tap-and-pop arcade game for kids, built with Flutter. No ads, no
network calls, no accounts — everything runs and saves on-device.

## Gameplay

- Jellies float up from the bottom — **tap to pop** them for points.
- Chain pops within 1.6s to build a **combo** (points scale with combo).
- Fill the golden meter to trigger **FEVER MODE**: 8 seconds of double
  points, faster spawns, zero bombs.
- **Golden jellies** = big points. **⭐ Stars** = currency. **💣 Bombs** = lose
  a heart, never tap them.
- 60-second rounds, 3 hearts. Difficulty ramps every 15 seconds.
- Spend stars in the **Jelly Shop** to unlock 6 color themes.
- High score, star bank, best combo and unlocks persist locally.

## Project layout

```
lib/
  main.dart               app entry, orientation + immersive mode
  game/
    engine.dart           pure-Dart simulation (unit tested)
    entities.dart         jelly / particle / event types
    painter.dart          CustomPainter renderer (jellies, faces, FX)
    themes.dart           6 unlockable color themes
    sound.dart            pooled low-latency SFX (audioplayers)
    storage.dart          shared_preferences persistence
  screens/
    home_screen.dart      animated title, play/shop, stats
    game_screen.dart      ticker loop, HUD, countdown, pause
    result_screen.dart    score count-up, stats, replay
    shop_screen.dart      theme shop with star economy
test/engine_test.dart     10 simulation tests
tool/gen_audio.py         synthesizes all 15 SFX as WAV (stdlib only)
tool/gen_icons.py         generates launcher icons (Pillow)
tool/patch_android.py     sets app label + portrait lock
.github/workflows/build.yml  CI: analyze → test → APK artifacts
```

## Build locally

```bash
python3 tool/gen_audio.py
flutter create --platforms=android --org com.jellypop --project-name jelly_pop .
python3 tool/patch_android.py
pip install pillow && python3 tool/gen_icons.py
flutter pub get
flutter test
flutter build apk --release --split-per-abi
```

APKs land in `build/app/outputs/flutter-apk/`. Install the `arm64-v8a` one on
any modern phone: `adb install app-arm64-v8a-release.apk`.

## CI builds

Every push to `main` runs analyze + tests and uploads three release APKs
(arm64, armv7, x64) as workflow artifacts. Tag a commit `v*` to also attach
them to a GitHub Release.
