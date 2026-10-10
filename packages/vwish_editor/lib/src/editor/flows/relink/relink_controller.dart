// OWNER: UX-40
//
// Placeholder (D-33) created by UX-01. UX-40 replaces this file:
// the relink controller (ux.md §13.2).
// Until then it declares only the public names other files compile against.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// State of the relink flow (ux.md §13.2).
@immutable
class RelinkState {
  /// Creates the placeholder state.
  const RelinkState();
}

/// Relinks missing media (ux.md §13.2).
class RelinkController extends StateNotifier<RelinkState> {
  /// Creates the placeholder controller.
  RelinkController([super.state = const RelinkState()]);
}

/// Builds the value of `relinkControllerProvider` for [id]. Implemented by UX-40; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
RelinkController createRelinkController(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createRelinkController is implemented by UX-40');
