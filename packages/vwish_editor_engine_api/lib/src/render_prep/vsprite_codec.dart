// OWNER: API-04
//
// Placeholder (D-33, created by API-01). API-04 implements the `.vsprite` v1 codec ('VSPR',
// zlib in `Isolate.run`; ARCH §10.3).

import 'dart:typed_data';

/// Encodes and decodes `.vsprite` v1 files (ARCH §10.3, API-04).
abstract final class VspriteCodec {
  /// Encodes premultiplied RGBA [rgba] of [width] x [height] (API-04).
  static Future<Uint8List> encode(Uint8List rgba, {required int width, required int height}) =>
      throw UnimplementedError('VspriteCodec is implemented by API-04');

  /// Decodes a `.vsprite` file (API-04).
  static Future<Uint8List> decode(Uint8List bytes) => throw UnimplementedError('VspriteCodec is implemented by API-04');
}
