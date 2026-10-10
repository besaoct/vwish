// OWNER: UX-05
//
// Placeholder (D-33) created by UX-01. UX-05 replaces this file:
// the project card (ux.md §5.1).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';
import 'package:vwish_editor_core/store.dart' show ProjectSummary;

import '../editor/wiring/not_available_yet.dart';

/// One project in the grid or list (ux.md §5.1).
class ProjectCard extends StatelessWidget {
  /// Creates the placeholder.
  const ProjectCard({super.key, required this.summary});

  /// The project.
  final ProjectSummary summary;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Project card', owner: 'UX-05');
}
