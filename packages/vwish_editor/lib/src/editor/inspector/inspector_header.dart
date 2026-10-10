// OWNER: UX-16
//
// Placeholder (D-33) created by UX-01. UX-16 replaces this file:
// the inspector header (ux.md §9.3).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../wiring/not_available_yet.dart';

/// Back, title, reset, keyframe-all and done (ux.md §9.3).
class InspectorHeader extends StatelessWidget {
  /// Creates the placeholder.
  const InspectorHeader({super.key, required this.title});

  /// Panel title.
  final String title;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Inspector header', owner: 'UX-16');
}
