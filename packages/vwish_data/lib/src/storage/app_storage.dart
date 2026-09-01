import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Structured AppStorage service.
/// Enforces §7.0 Non-destructive Invariant:
/// "The player has exactly one writable location: its own app-data directory.
/// It never writes to, moves, renames, reorganises, or deletes anything inside
/// the user's media folders."
class AppStorage {
  static Directory? _appDataDir;
  static Directory? _cacheDir;

  static Future<void> initialize() async {
    try {
      _appDataDir = await getApplicationSupportDirectory();
    } catch (_) {
      _appDataDir = Directory('${Directory.systemTemp.path}/vwish_app_data');
    }

    try {
      _cacheDir = await getTemporaryDirectory();
    } catch (_) {
      _cacheDir = Directory('${Directory.systemTemp.path}/vwish_cache');
    }

    if (!await _appDataDir!.exists()) {
      await _appDataDir!.create(recursive: true);
    }
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  static Directory get appDataDirectory {
    return _appDataDir ?? Directory('${Directory.systemTemp.path}/vwish_app_data');
  }

  static Directory get cacheDirectory {
    return _cacheDir ?? Directory('${Directory.systemTemp.path}/vwish_cache');
  }

  static Future<File> getCacheFile(String filename) async {
    final path = p.join(cacheDirectory.path, filename);
    return File(path);
  }

  static Future<File> getAppDataFile(String filename) async {
    final path = p.join(appDataDirectory.path, filename);
    return File(path);
  }
}
