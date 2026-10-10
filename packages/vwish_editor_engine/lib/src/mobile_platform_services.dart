// OWNER: ENG-03
//
// Placeholder (D-33, created by ENG-01). ENG-03 replaces the bodies (ARCH §12.4, §15):
// MobileMediaPicker, MobileFileHandoff, MobileBackgroundWorkGuard (acquire / update / release
// leases, progress forwarding, `leaseExpiring` from `channels.router.job(leaseId)`) and
// MobileExternalDropTarget (drops from `channels.router.drops`) over PlatformHostApi. Only the
// declared public names exist here; every member throws `UnimplementedError`.

import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

import 'pigeon/engine_channels.dart';

Never _todo(String type) => throw UnimplementedError('$type is implemented by ENG-03');

/// System pickers over `PlatformHostApi.pick` (ARCH §12.4, ENG-03).
final class MobileMediaPicker implements MediaPicker {
  /// Creates the picker.
  MobileMediaPicker(EngineChannels channels);

  @override
  Future<List<PickedMedia>> pick(MediaPickRequest request) => _todo('MobileMediaPicker');
}

/// Photos / Files / share handoff over `PlatformHostApi` (ARCH §12.4, ENG-03).
final class MobileFileHandoff implements FileHandoff {
  /// Creates the handoff.
  MobileFileHandoff(EngineChannels channels);

  @override
  Future<FileHandoffResult> saveToPhotos(String path) => _todo('MobileFileHandoff');

  @override
  Future<FileHandoffResult> saveToFiles(String path, String suggestedName) => _todo('MobileFileHandoff');

  @override
  Future<FileHandoffResult> share(String path) => _todo('MobileFileHandoff');
}

/// Background leases over `PlatformHostApi.acquireBackground` (ARCH §12.4, ENG-03).
final class MobileBackgroundWorkGuard implements BackgroundWorkGuard {
  /// Creates the guard.
  MobileBackgroundWorkGuard(EngineChannels channels);

  @override
  Future<BackgroundLease?> acquire({required String title, required Stream<double> progress}) => _todo('MobileBackgroundWorkGuard');
}

/// External drag and drop over `PlatformHostApi.setDropTargetEnabled` (ARCH §12.4, D-18, ENG-03).
final class MobileExternalDropTarget implements ExternalDropTarget {
  /// Creates the drop target.
  MobileExternalDropTarget(EngineChannels channels);

  @override
  Future<void> setEnabled(bool on) => _todo('MobileExternalDropTarget');

  @override
  Stream<ExternalDrop> get drops => _todo('MobileExternalDropTarget');
}
