// OWNER: UX-08
//
// Placeholder (D-33) created by UX-01. UX-08 replaces this file:
// EditorController (ARCH §17.3, ux.md §16.3).
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

import 'editor_state.dart';

/// The editor's mutation and lifecycle API (ARCH §17.3).
class EditorController extends StateNotifier<EditorState> {
  /// Creates the placeholder controller.
  EditorController([super.state = const EditorState.opening()]);
}

/// Builds the value of `editorControllerProvider` for [id]. Implemented by UX-08; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
EditorController createEditorController(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createEditorController is implemented by UX-08');
