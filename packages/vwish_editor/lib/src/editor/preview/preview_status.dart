// OWNER: UX-18
//
// Placeholder (D-33) created by UX-01. UX-18 replaces this file:
// starting, failed, offline and degraded overlays (ARCH §17.5).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';

import '../wiring/not_available_yet.dart';

/// Starting, failed, offline and degraded overlays (ARCH §17.5).
class PreviewStatusOverlay extends StatelessWidget {
  /// Creates the placeholder.
  const PreviewStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Preview status', owner: 'UX-18');
}
