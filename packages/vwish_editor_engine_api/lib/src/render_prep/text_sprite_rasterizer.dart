// OWNER: API-04
//
// Placeholder (D-33, created by API-01). API-04 implements the text sprite rasterizer
// (ARCH §10.3, D-06).

import 'dart:typed_data';

import 'package:vwish_editor_core/plan.dart';

/// Rasterizes text to premultiplied RGBA at the per-item raster scale (ARCH §10.3, API-04).
class TextSpriteRasterizer {
  /// Creates a rasterizer.
  const TextSpriteRasterizer();

  /// Premultiplied RGBA of [request] (API-04).
  Future<Uint8List> rasterize(SpriteRequest request, {required int maxTextureSize}) =>
      throw UnimplementedError('TextSpriteRasterizer is implemented by API-04');
}
