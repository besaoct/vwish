// OWNER: UX-11
//
// Placeholder (D-33) created by UX-01. UX-11 replaces this file:
// the track menu sheet (ux.md §8.10).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';
import 'package:vwish_editor_core/model.dart' show TrackId;

import '../wiring/not_available_yet.dart';

/// Actions of one track (ux.md §8.10).
class TrackMenuSheet extends StatelessWidget {
  /// Creates the placeholder.
  const TrackMenuSheet({super.key, required this.track});

  /// The track.
  final TrackId track;

  @override
  Widget build(BuildContext context) => const EditorNotAvailableYet(label: 'Track menu', owner: 'UX-11');
}
