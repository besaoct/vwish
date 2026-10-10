// OWNER: UX-07
//
// Placeholder (D-33) created by UX-01. UX-07 replaces this file:
// EditorLayoutSpec.resolve, the pure layout planner (ARCH §17.2).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

/// Layout kinds of the editor (ARCH §17.2).
enum EditorLayoutKind {
  /// Usable height < 520 in landscape.
  compactLandscape,

  /// Width < 600.
  compactPortrait,

  /// Width < 1000.
  medium,

  /// Wider.
  expanded,
}

/// The resolved regions of the editor (ARCH §17.2).
class EditorLayoutSpec {
  /// Plans the layout. Implemented by UX-07.
  static EditorLayoutSpec resolve({
    required Size size,
    required EdgeInsets padding,
    required EdgeInsets viewInsets,
    required TextScaler textScaler,
    required bool touch,
    double? splitRatio,
    bool inspectorOpen = false,
  }) =>
      throw UnimplementedError('EditorLayoutSpec.resolve is implemented by UX-07');
}
