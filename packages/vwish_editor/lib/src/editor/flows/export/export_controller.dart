// OWNER: UX-39
//
// Placeholder (D-33) created by UX-01. UX-39 replaces this file:
// the export controller (ARCH §14.1, ux.md §11).
// Until then it declares only the public names other files compile against.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// State of the export flow (ux.md §11).
@immutable
class ExportUiState {
  /// Creates the placeholder state.
  const ExportUiState();
}

/// Pre-checks, settings, progress and handoff of an export (ARCH §14.1).
class ExportController extends StateNotifier<ExportUiState> {
  /// Creates the placeholder controller.
  ExportController([super.state = const ExportUiState()]);
}

/// Builds the value of `exportControllerProvider` for [id]. Implemented by UX-39; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
ExportController createExportController(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createExportController is implemented by UX-39');
