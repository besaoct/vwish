import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_engine/vwish_engine.dart';
import 'package:vwish_features/vwish_features.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Desktop Window & Platform features
  await PlatformBridge.initializeWindow();

  // 2. Initialize Persistent Storage & Repositories
  final prefs = await SharedPreferences.getInstance();
  final sessionRepo = SessionRepository(prefs);
  final libraryRepo = LibraryRepository(prefs);

  // 3. Initialize libmpv engine
  final engine = MpvPlaybackEngine();
  await engine.initialize();

  runApp(
    ProviderScope(
      overrides: [
        playbackEngineProvider.overrideWithValue(engine),
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
        libraryRepositoryProvider.overrideWithValue(libraryRepo),
      ],
      child: const VwishApp(),
    ),
  );
}
