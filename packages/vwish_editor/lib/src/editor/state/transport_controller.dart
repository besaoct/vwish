// OWNER: UX-14
//
// Placeholder (D-33) created by UX-01. UX-14 replaces this file:
// TransportController (ux.md §7.6).
// Until then it declares only the public names other files compile against.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// Play state, rate, loop range and stepping (ux.md §7.6).
class TransportController {}

/// Builds the value of `transportProvider` for [id]. Implemented by UX-14; it may call
/// `ref.keepAlive()` and close the link when the editor has closed.
TransportController createTransportController(Ref<Object?> ref, ProjectId id) =>
    throw UnimplementedError('createTransportController is implemented by UX-14');
