import 'package:flutter/material.dart';

import '../foundation/vwish_internal.dart';
import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';
import 'vwish_list_tile.dart';
import 'vwish_pressable.dart';

class VwishSwitch extends StatelessWidget {
  const VwishSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = VwishColors.primary,
    this.semanticLabel,
  });

  static const double _trackWidth = 50;
  static const double _trackHeight = 30;
  static const double _thumb = 26;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final touch = context.isTouchPlatform;
    return VwishPressable.builder(
      onTap: enabled ? () => onChanged!(!value) : null,
      isButton: false,
      toggled: value,
      semanticLabel: semanticLabel,
      pressedScale: 1,
      builder: (context, state) {
        const radius = BorderRadius.all(Radius.circular(_trackHeight / 2));
        final track = AnimatedContainer(
          duration: VwishMotion.normal,
          curve: VwishMotion.curve,
          width: _trackWidth,
          height: _trackHeight,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? activeColor : VwishColors.surfaceElevatedHigher,
            borderRadius: radius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.fromBorderSide(
              state.focused
                  ? VwishBorders.focus
                  : value
                      ? VwishBorders.hairline.copyWith(color: Colors.transparent)
                      : VwishBorders.hairline,
            ),
          ),
          child: AnimatedAlign(
            duration: VwishMotion.normal,
            curve: VwishMotion.curve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: VwishMotion.fast,
              curve: VwishMotion.curve,
              width: state.pressed ? _thumb + 5 : _thumb,
              height: _thumb,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(_thumb / 2)),
                boxShadow: VwishShadows.subtle,
              ),
            ),
          ),
        );
        return vwishDimmed(
          enabled,
          SizedBox(
            width: _trackWidth,
            height: touch ? VwishSpacing.minTapTarget : _trackHeight,
            child: Center(child: track),
          ),
        );
      },
    );
  }
}

class VwishSwitchRow extends StatelessWidget {
  const VwishSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return VwishListTile(
      title: title,
      subtitle: subtitle,
      subtitleMaxLines: 2,
      leading: leading,
      dense: dense,
      enabled: onChanged != null,
      toggled: value,
      onTap: onChanged == null ? null : () => onChanged(!value),
      // The row owns semantics, focus and dimming; the switch is only the visual.
      trailing: ExcludeSemantics(
        child: ExcludeFocus(
          child: IgnorePointer(
            ignoring: onChanged == null,
            child: VwishSwitch(value: value, onChanged: onChanged ?? (_) {}),
          ),
        ),
      ),
    );
  }
}
