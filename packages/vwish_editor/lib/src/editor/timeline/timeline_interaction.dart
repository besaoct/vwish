// OWNER: UX-13
//
// Placeholder (D-33) created by UX-01. UX-13 replaces this file:
// TimelineInteractionController (ux.md §8.9).
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// Drag ghosts, guides, marquee and trim pills (ux.md §8.9).
class TimelineInteractionController {}

/// Builds the value of `interactionProvider` for [id]. Implemented by UX-13; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
TimelineInteractionController createInteractionController(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createInteractionController is implemented by UX-13');
