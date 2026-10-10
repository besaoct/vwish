// OWNER: UX-40
//
// Placeholder (D-33) created by UX-01. UX-40 replaces this file:
// the recovery banner on the Projects screen (ux.md §13.3).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../editor/wiring/not_available_yet.dart';

/// Offers to restore projects that closed unexpectedly (ux.md §13.3).
class RecoveryBanner extends StatelessWidget {
  /// Creates the placeholder.
  const RecoveryBanner({super.key});

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Recovery', owner: 'UX-40');
}
