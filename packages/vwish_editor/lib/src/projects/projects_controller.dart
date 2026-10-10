// OWNER: UX-05
//
// Placeholder (D-33) created by UX-01. UX-05 replaces this file:
// ProjectsController and ProjectsState (ux.md §5.4).
// Until then it declares only the public names other files compile against.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the Projects screen (ux.md §5.4).
@immutable
class ProjectsState {
  /// Creates the placeholder state.
  const ProjectsState();
}

/// Projects list, sort, search and actions (ux.md §5.4).
class ProjectsController extends StateNotifier<ProjectsState> {
  /// Creates the placeholder controller.
  ProjectsController([super.state = const ProjectsState()]);
}
