import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/vwish_internal.dart';
import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';
import 'vwish_menu.dart';
import 'vwish_pressable.dart';

class VwishChoiceChip extends StatelessWidget {
  const VwishChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    final fill = selected ? VwishColors.primary : VwishColors.surfaceElevatedHigher;
    final fg = selected ? VwishColors.foregroundOn(VwishColors.primary) : VwishColors.textSecondary;
    return VwishPressable.builder(
      onTap: active ? onTap : null,
      selected: selected,
      pressedScale: 0.97,
      builder: (context, state) {
        final visual = AnimatedContainer(
          duration: VwishMotion.fast,
          curve: VwishMotion.curve,
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: vwishInteractiveFill(fill, state), borderRadius: VwishRadius.smAll),
          foregroundDecoration: BoxDecoration(
            borderRadius: VwishRadius.smAll,
            border: Border.fromBorderSide(
              state.focused
                  ? VwishBorders.focus
                  : selected
                      ? VwishBorders.hairline.copyWith(color: Colors.transparent)
                      : VwishBorders.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.2,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        );
        return vwishDimmed(active, vwishTapTarget(context, visual));
      },
    );
  }
}

class VwishChipGroup extends StatelessWidget {
  const VwishChipGroup({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> children;
  final double spacing;

  /// Defaults to 8 on desktop and 0 on touch, where chips already carry a 44pt hit area.
  final double? runSpacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing ?? (context.isTouchPlatform ? 0 : 8),
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// Equal-width segments. When the option icons would not fit the segments drop them, and when even
/// a bare label would not fit it falls back to wrapping [VwishChoiceChip]s.
class VwishSegmentedControl<T> extends StatelessWidget {
  const VwishSegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final T value;
  final List<VwishOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  static const double _inset = 3;
  static const double _hPad = 10;
  static const double _iconWidth = 15 + 6;
  static const TextStyle _labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2);

  double _neededSegmentWidth(BuildContext context, {required bool icons}) {
    final scaler = MediaQuery.textScalerOf(context);
    final base = DefaultTextStyle.of(context).style.merge(_labelStyle);
    var widest = 0.0;
    for (final option in options) {
      final painter = TextPainter(
        text: TextSpan(text: option.label, style: base),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width + (icons && option.icon != null ? _iconWidth : 0));
      painter.dispose();
    }
    return widest + _hPad * 2;
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final needed = _neededSegmentWidth(context, icons: true);
    final bare = options.any((o) => o.icon != null) ? _neededSegmentWidth(context, icons: false) : needed;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final segment = width.isFinite ? (width - _inset * 2) / options.length : 0.0;
        if (!width.isFinite || segment < bare) return _buildChips();
        return _buildSegments(context, width, segment, icons: segment >= needed);
      },
    );
  }

  Widget _buildChips() {
    return VwishChipGroup(
      children: [
        for (final option in options)
          VwishChoiceChip(
            label: option.label,
            icon: option.icon,
            selected: option.value == value,
            enabled: enabled && option.enabled,
            onTap: () => onChanged(option.value),
          ),
      ],
    );
  }

  Widget _buildSegments(BuildContext context, double width, double segment, {required bool icons}) {
    final index = options.indexWhere((o) => o.value == value);
    final height = context.isTouchPlatform ? VwishSpacing.minTapTarget : 36.0;
    final selectedFg = VwishColors.foregroundOn(VwishColors.primary);
    return vwishDimmed(
      enabled,
      Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(_inset),
        decoration: const BoxDecoration(
          color: VwishColors.surfaceElevatedHigher,
          borderRadius: VwishRadius.mdAll,
        ),
        foregroundDecoration: const BoxDecoration(borderRadius: VwishRadius.mdAll, border: VwishBorders.all),
        child: Stack(
          children: [
            if (index >= 0)
              AnimatedPositioned(
                duration: VwishMotion.normal,
                curve: VwishMotion.curve,
                left: segment * index,
                top: 0,
                bottom: 0,
                width: segment,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: VwishColors.primary,
                    borderRadius: BorderRadius.all(Radius.circular(VwishRadius.md - _inset)),
                  ),
                ),
              ),
            Row(
              children: [
                for (var i = 0; i < options.length; i++)
                  Expanded(
                    child: _Segment(
                      option: options[i],
                      showIcon: icons,
                      selected: i == index,
                      foreground: i == index ? selectedFg : VwishColors.textSecondary,
                      onTap: enabled && options[i].enabled ? () => onChanged(options[i].value) : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.showIcon,
    required this.selected,
    required this.foreground,
    required this.onTap,
  });

  final VwishOption<T> option;
  final bool showIcon;
  final bool selected;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return VwishPressable.builder(
      onTap: onTap,
      selected: selected,
      semanticLabel: option.label,
      pressedScale: 0.97,
      builder: (context, state) {
        final tint = !selected && (state.hovered || state.pressed || state.focused);
        return AnimatedContainer(
          duration: VwishMotion.fast,
          curve: VwishMotion.curve,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: VwishSegmentedControl._hPad),
          decoration: BoxDecoration(
            color: tint ? VwishColors.hover : const Color(0x00FFFFFF),
            borderRadius: const BorderRadius.all(Radius.circular(VwishRadius.md - VwishSegmentedControl._inset)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon && option.icon != null) ...[
                Icon(option.icon, size: 15, color: foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: VwishMotion.fast,
                  style: DefaultTextStyle.of(context)
                      .style
                      .merge(VwishSegmentedControl._labelStyle.copyWith(color: foreground)),
                  child: Text(
                    option.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
