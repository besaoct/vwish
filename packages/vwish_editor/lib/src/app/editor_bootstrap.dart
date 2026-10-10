// OWNER: INT-02
//
// Placeholder (D-33) created by UX-01. INT-02 replaces this file:
// EditorBootstrap.create returns the provider overrides that wire the editor (ARCH §4.1, §17.3).
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

/// Builds the provider overrides that wire the editor into the app (ARCH §4.1, §17.3).
abstract final class EditorBootstrap {
  /// The overrides for the app's `ProviderScope`; without an [engine] (desktop) the editor stays
  /// unavailable. Implemented by INT-02.
  static Future<List<Override>> create({EditorEngine? engine}) =>
      throw UnimplementedError('EditorBootstrap.create is implemented by INT-02');
}
