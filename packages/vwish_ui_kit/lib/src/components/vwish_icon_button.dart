import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/vwish_internal.dart';
import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';
import 'vwish_pressable.dart';

enum VwishIconButtonVariant { plain, filled, tonal, primary }

class VwishIconButton extends StatelessWidget {
  const VwishIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = VwishIconButtonVariant.plain,
    this.size = 40,
    this.iconSize,
    this.color,
    this.tooltip,
    this.semanticLabel,
    this.selected = false,
    this.onLongPress,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final VwishIconButtonVariant variant;

  /// Visual circle diameter; the hit area is at least 44 on touch platforms.
  final double size;
  final double? iconSize;

  final Color? color;
  final String? tooltip;
  final String? semanticLabel;
  final bool selected;
  final VoidCallback? onLongPress;

  Color get _background {
    if (selected && variant == VwishIconButtonVariant.plain) return VwishColors.primaryTonal;
    return switch (variant) {
      VwishIconButtonVariant.plain => const Color(0x00FFFFFF),
      VwishIconButtonVariant.filled => VwishColors.surfaceElevatedHigher,
      VwishIconButtonVariant.tonal => VwishColors.primaryTonal,
      VwishIconButtonVariant.primary => VwishColors.primary,
    };
  }

  Color get _foreground {
    if (color != null) return color!;
    return switch (variant) {
      VwishIconButtonVariant.plain => selected ? VwishColors.primaryLight : VwishColors.textPrimary,
      VwishIconButtonVariant.tonal => VwishColors.primaryLight,
      VwishIconButtonVariant.filled || VwishIconButtonVariant.primary => VwishColors.foregroundOn(_background),
    };
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || onLongPress != null;
    final hit = context.isTouchPlatform ? math.max(size, VwishSpacing.minTapTarget) : size;
    final background = _background;
    final foreground = _foreground;

    return VwishPressable.builder(
      onTap: onPressed,
      onLongPress: onLongPress,
      tooltip: tooltip,
      semanticLabel: semanticLabel ?? tooltip,
      selected: selected ? true : null,
      pressedScale: 0.96,
      builder: (context, state) {
        final circle = AnimatedContainer(
          duration: VwishMotion.fast,
          curve: VwishMotion.curve,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: vwishInteractiveFill(background, state),
          ),
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              state.focused ? VwishBorders.focus : VwishBorders.focus.copyWith(color: Colors.transparent),
            ),
          ),
          child: Icon(icon, size: iconSize ?? size * 0.5, color: foreground),
        );
        return vwishDimmed(
          enabled,
          SizedBox(width: hit, height: hit, child: Center(child: circle)),
        );
      },
    );
  }
}
