// OWNER: UX-10
//
// Placeholder (D-33) created by UX-01. UX-10 replaces this file:
// RenderTimelineCanvas (ARCH §17.4).
// Until then it declares only the public names other files compile against.

import 'package:flutter/rendering.dart';

/// Paints the visible window of the timeline (ARCH §17.4).
class RenderTimelineCanvas extends RenderBox {
  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(Size.zero);
}
