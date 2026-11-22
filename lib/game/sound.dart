import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

/// Low-latency SFX. Pop sounds use a small pool of players so rapid taps
/// never cut each other off.
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  final List<AudioPlayer> _popPool = [];
  final Map<String, AudioPlayer> _oneShots = {};
  int _popIdx = 0;
  bool muted = false;
  bool _ready = false;
  final Random _rng = Random();

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    for (var i = 0; i < 4; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
      _popPool.add(p);
    }
  }

  void setMuted(bool m) => muted = m;

  Future<void> _oneShot(String name, {double volume = 1.0}) async {
    if (muted) return;
    try {
      final p = _oneShots.putIfAbsent(name, () {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.stop);
        return player;
      });
      await p.stop();
      await p.play(AssetSource('audio/$name.wav'), volume: volume);
    } catch (_) {
      // Audio failures must never break gameplay.
    }
  }

  Future<void> pop(int combo) async {
    if (muted || _popPool.isEmpty) return;
    try {
      final idx = (combo ~/ 4).clamp(0, 5);
      final p = _popPool[_popIdx++ % _popPool.length];
      await p.stop();
      await p.play(
        AssetSource('audio/pop$idx.wav'),
        volume: 0.8 + _rng.nextDouble() * 0.2,
      );
    } catch (_) {}
  }

  void golden() => _oneShot('golden');
  void star() => _oneShot('star');
  void bomb() => _oneShot('bomb', volume: 0.9);
  void fever() => _oneShot('fever');
  void over() => _oneShot('over');
  void record() => _oneShot('record');
  void tap() => _oneShot('tap', volume: 0.6);
  void tick() => _oneShot('tick', volume: 0.7);
  void go() => _oneShot('go');
}
