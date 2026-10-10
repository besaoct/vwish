// OWNER: ENG-03
//
// Placeholder (D-33, created by ENG-01). ENG-03 replaces the bodies: MobileMediaAccess implements
// MediaAccess (core MediaAccessPort) over PlatformHostApi (ARCH §9.2, §12.4): resolve (bookmark
// refresh), stat, quickHash, persist, release, excludeFromBackup refusing paths outside the
// editor / speech roots (D-44), remainingGrantBudget, requestNotificationPermission. Only the
// declared public names exist here; every member throws `UnimplementedError`.

import 'package:vwish_editor_core/model.dart' show MediaLocator, MediaStat, PickedMediaHandle, ResolvedMedia;
import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

import 'pigeon/engine_channels.dart';

Never _todo() => throw UnimplementedError('MobileMediaAccess is implemented by ENG-03');

/// Media access over `PlatformHostApi` (ARCH §9.2, §12.4, D-44, ENG-03).
final class MobileMediaAccess implements MediaAccess {
  /// Creates the access service.
  MobileMediaAccess(EngineChannels channels);

  @override
  Future<ResolvedMedia> resolve(MediaLocator locator) => _todo();

  @override
  Future<MediaStat?> stat(MediaLocator locator) => _todo();

  @override
  Future<String> quickHash(MediaLocator locator) => _todo();

  @override
  Future<MediaLocator> persist(PickedMediaHandle handle) => _todo();

  @override
  Future<void> release(MediaLocator locator) => _todo();

  @override
  Future<void> excludeFromBackup(String dirPath) => _todo();

  @override
  Future<int> remainingGrantBudget() => _todo();

  @override
  Future<bool> requestNotificationPermission() => _todo();
}
