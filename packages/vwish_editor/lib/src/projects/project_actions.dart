// OWNER: UX-05
//
// Placeholder (D-33) created by UX-01. UX-05 replaces this file:
// rename, duplicate and delete actions of a project (ux.md §5.2).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

import '../editor/wiring/not_available_yet.dart';

/// Rename, duplicate and delete for one project (ux.md §5.2).
class ProjectActions extends StatelessWidget {
  /// Creates the placeholder.
  const ProjectActions({super.key, required this.projectId});

  /// The project.
  final ProjectId projectId;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Project actions', owner: 'UX-05');
}
