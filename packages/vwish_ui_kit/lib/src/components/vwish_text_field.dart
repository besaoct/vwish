import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';
import 'vwish_icon_button.dart';

class VwishTextField extends StatefulWidget {
  const VwishTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.prefixIcon,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
    this.showClearButton = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final IconData? prefixIcon;

  /// Shown below the field (max 2 lines) and tints the border.
  final String? errorText;
  final bool autofocus;
  final bool enabled;
  final bool showClearButton;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;

  @override
  State<VwishTextField> createState() => _VwishTextFieldState();
}

class _VwishTextFieldState extends State<VwishTextField> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  TextEditingController get _controller => widget.controller ?? (_ownedController ??= TextEditingController());
  FocusNode get _focusNode => widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(VwishTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController)?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final hasError = widget.errorText != null;
    final showClear = widget.showClearButton && widget.enabled && _controller.text.isNotEmpty;
    final border = hasError
        ? const BorderSide(color: Color(0x61EF4444), width: 1)
        : focused
            ? VwishBorders.focus
            : VwishBorders.hairline;
    final fill = focused ? VwishColors.fieldActive : VwishColors.surfaceElevatedHigher;

    final field = AnimatedContainer(
      duration: VwishMotion.fast,
      curve: VwishMotion.curve,
      constraints: const BoxConstraints(minHeight: VwishSpacing.minTapTarget),
      padding: EdgeInsets.only(left: widget.prefixIcon != null ? 10 : 12, right: showClear ? 2 : 12),
      decoration: BoxDecoration(color: fill, borderRadius: VwishRadius.mdAll),
      foregroundDecoration: BoxDecoration(borderRadius: VwishRadius.mdAll, border: Border.fromBorderSide(border)),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            Icon(
              widget.prefixIcon,
              size: 18,
              color: focused ? VwishColors.primaryLight : VwishColors.textMuted,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Material(
                type: MaterialType.transparency,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  inputFormatters: widget.inputFormatters,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  minLines: widget.minLines,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: VwishColors.primary,
                  cursorRadius: const Radius.circular(2),
                  style: const TextStyle(fontSize: 15, height: 1.3, color: VwishColors.textPrimary),
                  // Every border is explicit so the theme's input borders never leak inside the custom frame.
                  decoration: InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(fontSize: 15, height: 1.3, color: VwishColors.textMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          if (showClear)
            VwishIconButton(
              icon: Icons.cancel_rounded,
              size: 30,
              iconSize: 18,
              color: VwishColors.textMuted,
              semanticLabel: 'Clear',
              onPressed: _clear,
            ),
        ],
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      child: Opacity(
        opacity: widget.enabled ? 1 : VwishColors.disabledOpacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field,
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                // Room for a full sentence at large text sizes; dialogs scroll their body.
                child: Text(
                  widget.errorText!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: VwishColors.errorLight),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
