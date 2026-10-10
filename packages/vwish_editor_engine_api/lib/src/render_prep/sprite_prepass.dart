// OWNER: API-04
//
// Placeholder (D-33, created by API-01). API-04 implements the export sprite pre-pass
// (ARCH §10.3, §14.1 step 4).

import 'package:vwish_editor_core/plan.dart';

/// Rasterizes missing text sprites before an export (ARCH §14.1, API-04).
class SpritePrepass {
  /// Creates the pre-pass.
  const SpritePrepass();

  /// Rasterizes [requests] into [cacheDir] (`<cache>/vwish/editor/sprites`) and returns the
  /// manifest (API-04).
  Future<SpriteManifest> run(List<SpriteRequest> requests, {required String cacheDir, void Function(double fraction)? onProgress}) =>
      throw UnimplementedError('SpritePrepass is implemented by API-04');
}
