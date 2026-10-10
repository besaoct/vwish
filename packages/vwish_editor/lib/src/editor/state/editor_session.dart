// OWNER: UX-08
//
// Placeholder (D-33) created by UX-01. UX-08 replaces this file:
// EditorSession wrapping core EditSession for providers.
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// The open editing session of one project (ARCH §17.3).
class EditorSession {}

/// Builds the value of `editorSessionProvider` for [id]. Implemented by UX-08; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
EditorSession createEditorSession(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createEditorSession is implemented by UX-08');
