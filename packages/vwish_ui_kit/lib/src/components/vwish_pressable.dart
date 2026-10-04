import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';

@immutable
class VwishPressState {
  const VwishPressState({
    required this.pressed,
    required this.hovered,
    required this.focused,
    required this.enabled,
  });

  final bool pressed;
  final bool hovered;
  final bool focused;
  final bool enabled;
}

typedef VwishPressableBuilder = Widget Function(BuildContext context, VwishPressState state);

class VwishPressable extends StatefulWidget {
  const VwishPressable({
    super.key,
    required Widget this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
    this.pressedScale = 0.97,
    this.pressedOpacity = 0.85,
    this.hoverColor = VwishColors.hover,
    this.borderRadius,
    this.circle = false,
    this.focusNode,
    this.autofocus = false,
    this.isButton = true,
    this.selected,
    this.toggled,
    this.behavior = HitTestBehavior.opaque,
  }) : builder = null;

  const VwishPressable.builder({
    super.key,
    required VwishPressableBuilder this.builder,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
    this.pressedScale = 0.97,
    this.pressedOpacity = 1.0,
    this.focusNode,
    this.autofocus = false,
    this.isButton = true,
    this.selected,
    this.toggled,
    this.behavior = HitTestBehavior.opaque,
  })  : child = null,
        hoverColor = VwishColors.hover,
        borderRadius = null,
        circle = false;

  final Widget? child;
  final VwishPressableBuilder? builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final String? semanticLabel;
  final String? tooltip;
  final double pressedScale;
  final double pressedOpacity;
  final Color hoverColor;
  final BorderRadius? borderRadius;
  final bool circle;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool isButton;
  final bool? selected;
  final bool? toggled;
  final HitTestBehavior behavior;

  @override
  State<VwishPressable> createState() => _VwishPressableState();
}

class _VwishPressableState extends State<VwishPressable> {
  static const Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _active => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(VwishPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active) _pressed = false;
  }

  Widget _decorate(Widget child, VwishPressState state) {
    final overlay = state.focused
        ? VwishColors.primarySoft
        : state.hovered
            ? widget.hoverColor
            : widget.hoverColor.withValues(alpha: 0);
    return AnimatedContainer(
      duration: VwishMotion.fast,
      curve: VwishMotion.curve,
      foregroundDecoration: BoxDecoration(
        color: overlay,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle ? null : widget.borderRadius,
        border: Border.fromBorderSide(
          state.focused ? VwishBorders.focus : VwishBorders.focus.copyWith(color: Colors.transparent),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final state = VwishPressState(
      pressed: _pressed && active,
      hovered: _hovered && active,
      focused: _focused && active,
      enabled: active,
    );

    Widget content = widget.builder?.call(context, state) ?? _decorate(widget.child!, state);

    content = AnimatedOpacity(
      opacity: state.pressed ? widget.pressedOpacity : 1.0,
      duration: VwishMotion.press,
      curve: VwishMotion.curve,
      child: content,
    );
    content = AnimatedScale(
      scale: state.pressed ? widget.pressedScale : 1.0,
      duration: VwishMotion.press,
      curve: VwishMotion.curve,
      child: content,
    );

    content = GestureDetector(
      behavior: widget.behavior,
      onTapDown: active ? (_) => _setPressed(true) : null,
      onTapUp: active ? (_) => _setPressed(false) : null,
      onTapCancel: active ? () => _setPressed(false) : null,
      onTap: active ? widget.onTap : null,
      onLongPress: active ? widget.onLongPress : null,
      child: content,
    );

    content = FocusableActionDetector(
      enabled: active,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: active ? SystemMouseCursors.click : MouseCursor.defer,
      shortcuts: _shortcuts,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            (widget.onTap ?? widget.onLongPress)?.call();
            return null;
          },
        ),
      },
      onShowHoverHighlight: (value) {
        if (_hovered != value) setState(() => _hovered = value);
      },
      onShowFocusHighlight: (value) {
        if (_focused != value) setState(() => _focused = value);
      },
      child: content,
    );

    content = Semantics(
      container: true,
      button: widget.isButton ? true : null,
      enabled: widget.isButton || !widget.enabled ? active : null,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      child: content,
    );

    final tooltip = widget.tooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      content = Tooltip(
        message: tooltip,
        excludeFromSemantics: widget.semanticLabel != null,
        child: content,
      );
    }
    return content;
  }
}
