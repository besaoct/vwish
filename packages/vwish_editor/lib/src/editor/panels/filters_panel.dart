// OWNER: UX-24
//
// Placeholder (D-33) created by UX-01. UX-24 replaces this file:
// the filters panel (ux.md §10.7).
// Keep the constructor contract `FiltersPanel({Key? key, required FiltersInspector route})`: InspectorHost (UX-16)
// builds panels with it.
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../contracts/inspector_routes.dart';
import '../wiring/not_available_yet.dart';

/// The filters panel (ux.md §10.7).
class FiltersPanel extends StatelessWidget {
  /// Creates the placeholder.
  const FiltersPanel({super.key, required this.route});

  /// What the panel edits.
  final FiltersInspector route;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Filters panel', owner: 'UX-24');
}
