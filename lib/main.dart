import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_engine/vwish_engine.dart';
import 'package:vwish_features/vwish_features.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import 'app.dart';

Future<void> main([List<String> args = const []]) async {
  WidgetsFlutterBinding.ensureInitialized();

  IncomingMediaBridge.setLaunchArgs(args);
  await PlatformBridge.initializeWindow();
  if (PlatformBridge.isMobile) await PlayerOrientation.applyAppDefault();

  // The app is dark everywhere; without an AppBar nothing else sets light status bar icons.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: VwishColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  final sessionRepo = SessionRepository(prefs);
  final libraryRepo = LibraryRepository(prefs);
  await sessionRepo.migrateMediaIds(libraryRepo.resolveStoredPath);

  final engine = MpvPlaybackEngine(subtitleFontAssets: VwishFonts.files);
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
