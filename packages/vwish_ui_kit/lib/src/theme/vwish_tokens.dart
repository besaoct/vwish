import 'package:flutter/material.dart';

import 'vwish_theme.dart';

abstract final class VwishRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double dialog = 16;
  static const double xl = 20;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius dialogAll = BorderRadius.all(Radius.circular(dialog));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class VwishShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: Color(0x2E000000),
      blurRadius: 16,
      spreadRadius: -4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 8),
    ),
  ];
}

enum VwishShadow {
  none(VwishShadows.none),
  subtle(VwishShadows.subtle),
  soft(VwishShadows.soft);

  const VwishShadow(this.boxShadows);

  final List<BoxShadow> boxShadows;
}

abstract final class VwishBorders {
  static const double width = 0.8;
  static const BorderSide hairline = BorderSide(color: VwishColors.hairline, width: width);
  static const BorderSide subtle = BorderSide(color: VwishColors.hairlineSubtle, width: width);
  static const BorderSide focus = BorderSide(color: VwishColors.focusRing, width: 1);
  static const Border all = Border.fromBorderSide(hairline);
}

abstract final class VwishSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double minTapTarget = 44;
}

abstract final class VwishBreakpoints {
  static const double compact = 560;
  static const double medium = 900;

  static bool isCompactWidth(double width) => width < compact;
  static bool isMediumWidth(double width) => width >= compact && width < medium;
  static bool isExpandedWidth(double width) => width >= medium;
}

abstract final class VwishMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
}

extension VwishContextX on BuildContext {
  double get vwishWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => VwishBreakpoints.isCompactWidth(vwishWidth);
  bool get isMedium => VwishBreakpoints.isMediumWidth(vwishWidth);
  bool get isExpanded => VwishBreakpoints.isExpandedWidth(vwishWidth);

  bool get isTouchPlatform {
    switch (Theme.of(this).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return false;
    }
  }
}
