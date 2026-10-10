// OWNER: UX-16
//
// Placeholder (D-33) created by UX-01. UX-16 replaces this file:
// InspectorHost mapping InspectorRoute -> panels (ux.md §9.3).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../wiring/not_available_yet.dart';

/// Hosts the panel of the current InspectorRoute (ux.md §9.3).
class InspectorHost extends StatelessWidget {
  /// Creates the placeholder.
  const InspectorHost({super.key});

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Inspector', owner: 'UX-16');
}
