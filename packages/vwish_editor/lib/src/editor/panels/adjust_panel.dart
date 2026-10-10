// OWNER: UX-24
//
// Placeholder (D-33) created by UX-01. UX-24 replaces this file:
// the adjust panel (ux.md §10.6).
// Keep the constructor contract `AdjustPanel({Key? key, required AdjustInspector route})`: InspectorHost (UX-16)
// builds panels with it.
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../contracts/inspector_routes.dart';
import '../wiring/not_available_yet.dart';

/// The adjust panel (ux.md §10.6).
class AdjustPanel extends StatelessWidget {
  /// Creates the placeholder.
  const AdjustPanel({super.key, required this.route});

  /// What the panel edits.
  final AdjustInspector route;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Adjust panel', owner: 'UX-24');
}
