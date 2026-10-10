// OWNER: UX-04
//
// Placeholder (D-33) created by UX-01. UX-04 replaces this file:
// the Editor settings screen (ARCH §17.10).
// Until then it declares only the public names other files compile against.

import 'package:flutter/material.dart' show Icons, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../editor/wiring/not_available_yet.dart';

/// Editor preferences (ARCH §17.10). Navigation comes from the router (INT-02).
class EditorSettingsScreen extends StatelessWidget {
  /// Creates the placeholder.
  const EditorSettingsScreen({super.key, required this.onBack});

  /// Leaves the screen.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VwishIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack, semanticLabel: 'Back'),
              const Expanded(child: EditorNotAvailableYet(label: 'Editor settings', owner: 'UX-04')),
            ],
          ),
        ),
      );
}
