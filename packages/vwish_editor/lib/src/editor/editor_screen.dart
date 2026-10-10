// OWNER: UX-07
//
// Placeholder (D-33) created by UX-01. UX-07 replaces this file:
// the editor screen shell (ARCH §17.2, ux.md §6).
// Until then it declares only the public names other files compile against.

import 'package:flutter/material.dart' show Icons, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId, TimeUs;
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import 'editor_scope.dart';
import 'wiring/not_available_yet.dart';

/// The editor for one project (ARCH §17.1, §17.2). Navigation comes from the router (INT-02).
class EditorScreen extends StatelessWidget {
  /// Creates the placeholder.
  const EditorScreen({super.key, required this.projectId, this.initialPlayhead, required this.onClose, this.onOpenProjects});

  /// The project to open.
  final ProjectId projectId;

  /// Exact seek target on open (`/editor/:id?t=`), or null.
  final TimeUs? initialPlayhead;

  /// Leaves the editor (after the close flush).
  final VoidCallback onClose;

  /// Opens the Projects screen ('Go to Projects').
  final VoidCallback? onOpenProjects;

  @override
  Widget build(BuildContext context) => EditorScope(
        projectId: projectId,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VwishIconButton(icon: Icons.close_rounded, onPressed: onClose, semanticLabel: 'Close editor'),
                const Expanded(child: EditorNotAvailableYet(label: 'Editor', owner: 'UX-07')),
              ],
            ),
          ),
        ),
      );
}
