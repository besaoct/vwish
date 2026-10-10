// OWNER: UX-36
//
// Placeholder (D-33) created by UX-01. UX-36 replaces this file:
// the media panel (ux.md §10.1).
// Keep the constructor contract `MediaPanel({Key? key, required MediaInspector route})`: InspectorHost (UX-16)
// builds panels with it.
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../contracts/inspector_routes.dart';
import '../wiring/not_available_yet.dart';

/// The media panel (ux.md §10.1).
class MediaPanel extends StatelessWidget {
  /// Creates the placeholder.
  const MediaPanel({super.key, required this.route});

  /// What the panel edits.
  final MediaInspector route;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Media panel', owner: 'UX-36');
}
