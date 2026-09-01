import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/vwish_theme.dart';

class VwishGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const VwishGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor ?? VwishColors.cardGlass,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? VwishColors.border,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
