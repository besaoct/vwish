import 'package:flutter/material.dart';

import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';

class VwishSurface extends StatelessWidget {
  const VwishSurface({
    super.key,
    required this.child,
    this.color = VwishColors.surfaceElevated,
    this.borderRadius = VwishRadius.lgAll,
    this.border = true,
    this.borderColor = VwishColors.hairline,
    this.shadow = VwishShadow.none,
    this.padding,
    this.margin,
    this.clip = true,
    this.width,
    this.height,
    this.constraints,
  });

  final Widget child;

  /// Must be opaque; the default text/icon color is derived from it.
  final Color color;
  final BorderRadius borderRadius;
  final bool border;
  final Color borderColor;
  final VwishShadow shadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool clip;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final foreground = VwishColors.foregroundOn(color);
    return Container(
      width: width,
      height: height,
      margin: margin,
      constraints: constraints,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: shadow.boxShadows,
      ),
      foregroundDecoration: border
          ? BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: VwishBorders.width),
            )
          : null,
      padding: padding,
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: child,
        ),
      ),
    );
  }
}
