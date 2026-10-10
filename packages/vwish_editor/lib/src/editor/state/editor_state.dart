// OWNER: UX-08
//
// Placeholder (D-33) created by UX-01. UX-08 replaces this file:
// EditorState and its value types (ARCH §17.3, ux.md §16.2).
// Until then it declares only the public names other files compile against.

import 'package:flutter/foundation.dart';

/// Lifecycle phase of an editor session (ux.md §16.2).
enum EditorPhase {
  /// Opening.
  opening,

  /// Ready.
  ready,

  /// Failed (see EditorState.failure).
  failed,

  /// Closing.
  closing,
}

/// Why the editor failed (ARCH §19).
sealed class EditorFailure {
  /// Creates a failure.
  const EditorFailure();
}

/// Undo/redo availability and labels (ux.md §16.2).
class HistoryStatus {}

/// Save status (ux.md §14.3).
sealed class SaveStatus {
  /// Creates a status.
  const SaveStatus();
}

/// The selection (ux.md §16.2).
class EditorSelection {}

/// Ripple, snapping, multi-select, centre playhead, safe guides, lane height (ux.md §16.2).
class EditModes {}

/// Preview status (ux.md §16.2).
sealed class PreviewStatus {
  /// Creates a status.
  const PreviewStatus();
}

/// Missing media and relink state (ux.md §16.2).
class MediaHealth {}

/// A background task shown in the tasks sheet (ux.md §16.2).
class EditorTaskInfo {}

/// State of one open editor (ARCH §17.3). Nothing in it changes per playback frame.
@immutable
class EditorState {
  /// The opening state.
  const EditorState.opening();
}
