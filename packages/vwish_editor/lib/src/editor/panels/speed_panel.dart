// OWNER: UX-25
//
// Placeholder (D-33) created by UX-01. UX-25 replaces this file:
// the speed panel (ux.md §10.3).
// Keep the constructor contract `SpeedPanel({Key? key, required SpeedInspector route})`: InspectorHost (UX-16)
// builds panels with it.
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../contracts/inspector_routes.dart';
import '../wiring/not_available_yet.dart';

/// The speed panel (ux.md §10.3).
class SpeedPanel extends StatelessWidget {
  /// Creates the placeholder.
  const SpeedPanel({super.key, required this.route});

  /// What the panel edits.
  final SpeedInspector route;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Speed panel', owner: 'UX-25');
}
