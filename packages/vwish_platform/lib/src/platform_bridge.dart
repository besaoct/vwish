import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

class PlatformBridge {
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initialize window manager on desktop platforms
  static Future<void> initializeWindow() async {
    if (isDesktop) {
      try {
        await windowManager.ensureInitialized();
        const windowOptions = WindowOptions(
          size: Size(1120, 700),
          minimumSize: Size(480, 320),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
          title: 'Vwish Player',
        );
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      } catch (e) {
        debugPrint('[PlatformBridge] Window manager setup: $e');
      }
    }
  }

  /// Toggle Fullscreen
  static Future<void> setFullscreen(bool fullscreen) async {
    if (isDesktop) {
      try {
        await windowManager.setFullScreen(fullscreen);
      } catch (_) {}
    }
  }

  /// Toggle Always on Top
  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (isDesktop) {
      try {
        await windowManager.setAlwaysOnTop(alwaysOnTop);
      } catch (_) {}
    }
  }

  /// Prevent OS from sleeping while video is playing
  static Future<void> setSleepInhibited(bool inhibit) async {
    try {
      if (inhibit) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
  }

  /// Open single or multiple video files using native file picker
  static Future<List<String>> pickVideoFiles() async {
    const typeGroup = XTypeGroup(
      label: 'Videos',
      extensions: <String>[
        'mkv', 'mp4', 'mov', 'avi', 'webm', 'ts', 'm2ts', 'flv', 'wmv', 'ogv'
      ],
    );
    final files = await openFiles(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    return files.map((f) => f.path).toList();
  }

  /// Pick single directory for folder playback / library scanning
  static Future<String?> pickDirectory() async {
    final path = await getDirectoryPath();
    return path;
  }

  /// Pick subtitle file
  static Future<String?> pickSubtitleFile() async {
    const typeGroup = XTypeGroup(
      label: 'Subtitles',
      extensions: <String>['srt', 'ass', 'ssa', 'vtt', 'sub'],
    );
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    return file?.path;
  }
}
