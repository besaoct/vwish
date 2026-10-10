// OWNER: UX-26
//
// Placeholder (D-33) created by UX-01. UX-26 replaces this file:
// the keyframes panel (ux.md §10.11).
// Keep the constructor contract `KeyframesPanel({Key? key, required KeyframesInspector route})`: InspectorHost (UX-16)
// builds panels with it.
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../contracts/inspector_routes.dart';
import '../wiring/not_available_yet.dart';

/// The keyframes panel (ux.md §10.11).
class KeyframesPanel extends StatelessWidget {
  /// Creates the placeholder.
  const KeyframesPanel({super.key, required this.route});

  /// What the panel edits.
  final KeyframesInspector route;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Keyframes panel', owner: 'UX-26');
}
