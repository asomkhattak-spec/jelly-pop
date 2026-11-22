import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/sound.dart';
import 'game/storage.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SaveData.init();
  try {
    await SoundManager.instance.init();
  } catch (_) {
    // Emulators / test environments without the audio plugin still play fine.
  }
  SoundManager.instance.setMuted(SaveData.instance.muted);
  runApp(const JellyPopApp());
}

class JellyPopApp extends StatelessWidget {
  const JellyPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jelly Pop!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5D8F)),
        scaffoldBackgroundColor: const Color(0xFF5B4DFF),
      ),
      home: const HomeScreen(),
    );
  }
}
