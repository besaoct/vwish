// OWNER: UX-05
//
// Placeholder (D-33) created by UX-01. UX-05 replaces this file:
// the Projects screen (ux.md §5).
// Until then it declares only the public names other files compile against.

import 'package:flutter/material.dart' show Icons, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId, TimeUs;
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../editor/wiring/not_available_yet.dart';

/// Opens a project in the editor (the router pushes `/editor/:id?t=`).
typedef OpenProjectCallback = void Function(ProjectId id, {TimeUs? initialPlayhead});

/// The Projects screen (ARCH §17.1, ux.md §5). Navigation comes from the router (INT-02).
class ProjectsScreen extends StatelessWidget {
  /// Creates the placeholder.
  const ProjectsScreen({super.key, required this.onBack, required this.onOpenProject});

  /// Leaves the screen.
  final VoidCallback onBack;

  /// Opens a project.
  final OpenProjectCallback onOpenProject;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VwishIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack, semanticLabel: 'Back'),
              const Expanded(child: EditorNotAvailableYet(label: 'Projects', owner: 'UX-05')),
            ],
          ),
        ),
      );
}
