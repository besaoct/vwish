import 'package:flutter/material.dart';

import '../foundation/vwish_internal.dart';
import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';
import 'vwish_glyph.dart';
import 'vwish_pressable.dart';

enum VwishButtonVariant { primary, secondary, tonal, ghost, destructive }

enum VwishButtonSize { sm, md, lg }

class VwishButton extends StatelessWidget {
  const VwishButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VwishButtonVariant.secondary,
    this.size = VwishButtonSize.md,
    this.icon,
    this.glyph,
    this.trailingIcon,
    this.expand = false,
    this.tooltip,
    this.semanticLabel,
  });

  const VwishButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = VwishButtonSize.md,
    this.icon,
    this.glyph,
    this.trailingIcon,
    this.expand = false,
    this.tooltip,
    this.semanticLabel,
  }) : variant = VwishButtonVariant.primary;

  const VwishButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = VwishButtonSize.md,
    this.icon,
    this.glyph,
    this.trailingIcon,
    this.expand = false,
    this.tooltip,
    this.semanticLabel,
  }) : variant = VwishButtonVariant.secondary;

  const VwishButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = VwishButtonSize.md,
    this.icon,
    this.glyph,
    this.trailingIcon,
    this.expand = false,
    this.tooltip,
    this.semanticLabel,
  }) : variant = VwishButtonVariant.tonal;

  const VwishButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = VwishButtonSize.md,
    this.icon,
    this.glyph,
    this.trailingIcon,
    this.expand = false,
    this.tooltip,
    this.semanticLabel,
  }) : variant = VwishButtonVariant.ghost;

  const VwishButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = VwishButtonSize.md,
    this.icon,
    this.glyph,
    this.trailingIcon,
    this.expand = false,
    this.tooltip,
    this.semanticLabel,
  }) : variant = VwishButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final VwishButtonVariant variant;
  final VwishButtonSize size;
  final IconData? icon;

  /// Drawn instead of [icon] when set.
  final VwishGlyphKind? glyph;
  final IconData? trailingIcon;

  /// Fills the available width; requires bounded width constraints.
  final bool expand;
  final String? tooltip;
  final String? semanticLabel;

  static ({Color fill, Color foreground}) _colorsFor(VwishButtonVariant variant) {
    return switch (variant) {
      VwishButtonVariant.primary => (
          fill: VwishColors.primary,
          foreground: VwishColors.foregroundOn(VwishColors.primary),
        ),
      VwishButtonVariant.secondary => (
          fill: VwishColors.surfaceElevatedHigher,
          foreground: VwishColors.foregroundOn(VwishColors.surfaceElevatedHigher),
        ),
      VwishButtonVariant.tonal => (fill: VwishColors.primaryTonal, foreground: VwishColors.primaryLight),
      VwishButtonVariant.ghost => (fill: const Color(0x00FFFFFF), foreground: VwishColors.textPrimary),
      VwishButtonVariant.destructive => (fill: const Color(0x29EF4444), foreground: VwishColors.errorLight),
    };
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = _colorsFor(variant);
    final (height, hPad, fontSize, iconSize, gap, radius) = switch (size) {
      VwishButtonSize.sm => (32.0, 12.0, 13.0, 16.0, 6.0, VwishRadius.smAll),
      VwishButtonSize.md => (40.0, 16.0, 14.0, 18.0, 8.0, VwishRadius.mdAll),
      VwishButtonSize.lg => (48.0, 20.0, 15.0, 20.0, 8.0, VwishRadius.mdAll),
    };
    final fg = colors.foreground;

    return VwishPressable.builder(
      onTap: onPressed,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      pressedScale: 0.97,
      builder: (context, state) {
        Widget visual = AnimatedContainer(
          duration: VwishMotion.fast,
          curve: VwishMotion.curve,
          constraints: BoxConstraints(minHeight: height, minWidth: height),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
          decoration: BoxDecoration(color: vwishInteractiveFill(colors.fill, state), borderRadius: radius),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.fromBorderSide(
              state.focused ? VwishBorders.focus : VwishBorders.focus.copyWith(color: Colors.transparent),
            ),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null || glyph != null) ...[
                vwishIconOrGlyph(icon, glyph, size: iconSize, color: fg),
                SizedBox(width: gap),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.1,
                    color: fg,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: gap),
                Icon(trailingIcon, size: iconSize, color: fg),
              ],
            ],
          ),
        );
        visual = expand
            ? SizedBox(width: double.infinity, child: visual)
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
                child: visual,
              );
        return vwishDimmed(enabled, vwishTapTarget(context, visual));
      },
    );
  }
}
