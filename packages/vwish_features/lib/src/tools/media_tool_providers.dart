import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_platform/vwish_platform.dart';

/// Reads container and track details of a video file; override with a fake in tests.
final mediaInspectorProvider = Provider<MediaInspector>((ref) => const MediaInspector());

/// Shows the system picker for one video and resolves to its path, or null when cancelled.
///
/// The picked file is only read: on iOS/Android it stays a temporary copy and is not imported
/// into the library.
final mediaInfoPickerProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    final paths = await PlatformBridge.pickVideoFiles();
    return paths.isEmpty ? null : paths.first;
  };
});
