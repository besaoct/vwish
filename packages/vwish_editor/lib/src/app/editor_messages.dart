// OWNER: UX-08
//
// Placeholder (D-33) created by UX-01. UX-08 replaces this file:
// maps every EditorFailure and EditRejection to plain copy with a next step (ARCH §19).
// Until then it declares only the public names other files compile against.

import 'package:flutter/foundation.dart';
import 'package:vwish_editor_core/ops.dart' show EditRejection;

/// A user-facing message: what happened and what to do next (ARCH §19).
@immutable
class EditorMessage {
  /// Creates a message.
  const EditorMessage(this.title, {this.detail});

  /// One line.
  final String title;

  /// The next step, or null.
  final String? detail;
}

/// Copy for failures and rejections (ARCH §19).
abstract final class EditorMessages {
  /// The message for a rejected command.
  static EditorMessage forRejection(EditRejection rejection) =>
      throw UnimplementedError('EditorMessages.forRejection is implemented by UX-08');
}
