import 'dart:convert';
import 'dart:io';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../scanner/natural_sort.dart';

class LibraryRepository {
  final SharedPreferences _prefs;

  LibraryRepository(this._prefs);

  static Future<LibraryRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LibraryRepository(prefs);
  }

  // Playlists
  List<String> getSavedPlaylistNames() {
    return _prefs.getStringList('saved_playlists') ?? [];
  }

  Future<void> savePlaylist(String name, List<MediaRef> items) async {
    final names = getSavedPlaylistNames();
    if (!names.contains(name)) {
      names.add(name);
      await _prefs.setStringList('saved_playlists', names);
    }
    final raw = items
        .map((m) => jsonEncode({
              'id': m.id,
              'title': m.title,
              'pathOrUri': m.pathOrUri,
              'durationMs': m.duration.inMilliseconds,
              'isRemote': m.isRemote,
              'season': m.seasonNumber,
              'episode': m.episodeNumber,
            }))
        .toList();
    await _prefs.setStringList('playlist_$name', raw);
  }

  List<MediaRef> getPlaylist(String name) {
    final raw = _prefs.getStringList('playlist_$name');
    if (raw == null) return [];
    final items = <MediaRef>[];
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        items.add(MediaRef(
          id: map['id'] as String,
          title: map['title'] as String,
          pathOrUri: map['pathOrUri'] as String,
          duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
          isRemote: map['isRemote'] as bool? ?? false,
          seasonNumber: map['season'] as int? ?? 0,
          episodeNumber: map['episode'] as int? ?? 0,
        ));
      } catch (_) {}
    }
    return items;
  }

  Future<void> deletePlaylist(String name) async {
    final names = getSavedPlaylistNames();
    names.remove(name);
    await _prefs.setStringList('saved_playlists', names);
    await _prefs.remove('playlist_$name');
  }

  // History
  List<MediaRef> getRecentlyPlayed() {
    final raw = _prefs.getStringList('recent_history') ?? [];
    final items = <MediaRef>[];
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        items.add(MediaRef(
          id: map['id'] as String,
          title: map['title'] as String,
          pathOrUri: map['pathOrUri'] as String,
          duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
          isRemote: map['isRemote'] as bool? ?? false,
        ));
      } catch (_) {}
    }
    return items;
  }

  Future<void> recordPlayed(MediaRef media) async {
    final recents = getRecentlyPlayed();
    recents.removeWhere((r) => r.pathOrUri == media.pathOrUri);
    recents.insert(0, media);
    if (recents.length > 50) {
      recents.removeLast();
    }
    final raw = recents
        .map((m) => jsonEncode({
              'id': m.id,
              'title': m.title,
              'pathOrUri': m.pathOrUri,
              'durationMs': m.duration.inMilliseconds,
              'isRemote': m.isRemote,
            }))
        .toList();
    await _prefs.setStringList('recent_history', raw);
  }

  // Sidecar subtitle discovery (Read-only §7.3)
  static Future<List<String>> discoverSidecarSubtitles(String mediaPath) async {
    final list = <String>[];
    final file = File(mediaPath);
    if (!await file.exists()) return list;

    final dir = file.parent;
    final baseName = p.basenameWithoutExtension(mediaPath);

    final validExts = {'.srt', '.ass', '.ssa', '.vtt', '.sub'};

    // 1. Same directory: file.srt, file.en.srt, etc.
    try {
      final entries = await dir.list().toList();
      for (final entity in entries) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (validExts.contains(ext)) {
            final name = p.basenameWithoutExtension(entity.path);
            if (name.startsWith(baseName)) {
              list.add(entity.path);
            }
          }
        }
      }

      // 2. Subdirectories: Subs, subs, Subtitles
      for (final subDirName in ['Subs', 'subs', 'Subtitles', 'subtitles']) {
        final subDir = Directory(p.join(dir.path, subDirName));
        if (await subDir.exists()) {
          final subEntries = await subDir.list().toList();
          for (final subEntity in subEntries) {
            if (subEntity is File) {
              final ext = p.extension(subEntity.path).toLowerCase();
              if (validExts.contains(ext)) {
                list.add(subEntity.path);
              }
            }
          }
        }
      }
    } catch (_) {}

    return list;
  }

  /// Scan a folder for media files using natural & episode sort
  static Future<List<MediaRef>> scanDirectory(String directoryPath) async {
    final results = <MediaRef>[];
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return results;

    final videoExtensions = {
      '.mkv', '.mp4', '.mov', '.avi', '.webm', '.ts', '.m2ts',
      '.flv', '.wmv', '.ogv', '.m4v', '.3gp'
    };

    try {
      final entries = await dir.list(recursive: false).toList();
      final fileList = <File>[];

      for (final entry in entries) {
        if (entry is File) {
          final ext = p.extension(entry.path).toLowerCase();
          if (videoExtensions.contains(ext)) {
            fileList.add(entry);
          }
        }
      }

      // Sort files naturally
      fileList.sort((a, b) => NaturalSortComparator.compare(
            p.basename(a.path),
            p.basename(b.path),
          ));

      for (final file in fileList) {
        final name = p.basename(file.path);
        final epInfo = EpisodeParser.parse(name);
        results.add(MediaRef(
          id: file.path,
          title: name,
          pathOrUri: file.path,
          isRemote: false,
          seasonNumber: epInfo.season,
          episodeNumber: epInfo.episode,
        ));
      }
    } catch (_) {}

    return results;
  }
}
