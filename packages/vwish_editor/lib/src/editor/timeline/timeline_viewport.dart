// OWNER: UX-09
//
// Placeholder (D-33) created by UX-01. UX-09 replaces this file:
// TimelineViewportController (ux.md §8.4).
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// Timeline zoom and scroll (ux.md §8.4).
class TimelineViewportController {}

/// Builds the value of `viewportProvider` for [id]. Implemented by UX-09; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
TimelineViewportController createViewportController(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createViewportController is implemented by UX-09');
