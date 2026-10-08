// OWNER: CORE-19
//
// Placeholder (D-33). CORE-19 replaces this sub-barrel with the snapshot-history editing session
// of ARCH §7.3: `EditSession` (apply, dryRun, begin/commit/cancel transactions, undo/redo/jump,
// applyPoolChange, applyPoolEdit, updateView, retainedMedia), `HistoryStatus`, `HistoryStep`,
// `SessionTransaction`. Declared here only so the repository and pool-service contracts compile.

import '../model/project.dart';

/// The editing session of one open project (ARCH §7.3). Placeholder: CORE-19 implements it.
final class EditSession {
  EditSession._();

  /// The current project (timeline snapshot + pool + view).
  EditProject get project => throw UnimplementedError('EditSession is implemented by CORE-19');
}
