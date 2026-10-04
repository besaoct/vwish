import 'package:flutter/material.dart';

import '../foundation/vwish_internal.dart';
import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';
import 'vwish_glyph.dart';
import 'vwish_pressable.dart';

class VwishListTile extends StatelessWidget {
  const VwishListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.dense = false,
    this.enabled = true,
    this.destructive = false,
    this.showChevron = false,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 1,
    this.padding,
    this.semanticLabel,
    this.toggled,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Keep compact (icon, switch, short text); it is not width-constrained.
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool dense;
  final bool enabled;
  final bool destructive;
  final bool showChevron;
  final int titleMaxLines;
  final int subtitleMaxLines;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && (onTap != null || onLongPress != null);
    final titleColor = destructive ? VwishColors.errorLight : VwishColors.textPrimary;

    return VwishPressable.builder(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      enabled: enabled,
      isButton: interactive,
      selected: selected ? true : null,
      toggled: toggled,
      semanticLabel: semanticLabel,
      pressedScale: 1,
      builder: (context, state) {
        final background = selected
            ? VwishColors.primarySoft
            : state.pressed
                ? VwishColors.hover
                : (state.hovered || state.focused)
                    ? VwishColors.hairlineSubtle
                    : const Color(0x00FFFFFF);
        return vwishDimmed(
          enabled,
          AnimatedContainer(
            duration: VwishMotion.fast,
            curve: VwishMotion.curve,
            constraints: BoxConstraints(minHeight: dense ? 44 : 52),
            padding: padding ?? EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 6 : 8),
            decoration: BoxDecoration(color: background, borderRadius: VwishRadius.mdAll),
            foregroundDecoration: BoxDecoration(
              borderRadius: VwishRadius.mdAll,
              border: Border.fromBorderSide(
                state.focused ? VwishBorders.focus : VwishBorders.focus.copyWith(color: Colors.transparent),
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dense ? 14 : 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          height: 1.25,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: subtitleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: dense ? 12 : 13,
                            height: 1.3,
                            color: VwishColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
                if (showChevron) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: VwishColors.textMuted),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class VwishTileIcon extends StatelessWidget {
  const VwishTileIcon(
    IconData this.icon, {
    super.key,
    this.color = VwishColors.primaryLight,
    this.backgroundColor,
    this.size = 32,
  }) : glyph = null;

  const VwishTileIcon.glyph(
    VwishGlyphKind this.glyph, {
    super.key,
    this.color = VwishColors.primaryLight,
    this.backgroundColor,
    this.size = 32,
  }) : icon = null;

  final IconData? icon;
  final VwishGlyphKind? glyph;
  final Color color;

  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.16),
        borderRadius: VwishRadius.smAll,
      ),
      child: vwishIconOrGlyph(icon, glyph, size: size * 0.56, color: color),
    );
  }
}
