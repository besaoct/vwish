// OWNER: UX-10
//
// Placeholder (D-33) created by UX-01. UX-10 replaces this file:
// TimelineSnapshot and its builder (ux.md §8.2).
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// The timeline view model of the committed project (ux.md §8.2).
class TimelineSnapshot {}

/// Builds snapshots, reusing models of identical domain objects (ux.md §8.2).
class TimelineSnapshotBuilder {}

/// One lane of a snapshot (ux.md §8.2).
class LaneModel {}

/// One item of a lane (ux.md §8.2).
class ItemModel {}

/// Builds the value of `timelineSnapshotProvider` for [id]. Implemented by UX-10; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
TimelineSnapshot buildTimelineSnapshot(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('buildTimelineSnapshot is implemented by UX-10');
