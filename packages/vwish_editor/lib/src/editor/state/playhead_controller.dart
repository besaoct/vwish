// OWNER: UX-14
//
// Placeholder (D-33) created by UX-01. UX-14 replaces this file:
// PlayheadController (ARCH §17.3, ux.md §7.8).
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// The playhead: a ValueListenable outside Riverpod state (ARCH §17.3).
class PlayheadController {}

/// Builds the value of `playheadProvider` for [id]. Implemented by UX-14; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
PlayheadController createPlayheadController(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createPlayheadController is implemented by UX-14');
