import 'package:flutter/material.dart';

import '../foundation/vwish_internal.dart';
import '../theme/vwish_theme.dart';
import '../theme/vwish_tokens.dart';
import 'vwish_button.dart';
import 'vwish_button_bar.dart';
import 'vwish_glyph.dart';
import 'vwish_surface.dart';
import 'vwish_text_field.dart';

/// The dialog is its own route: read providers inside [builder] with Consumer/ref.watch so it stays live.
Future<T?> showVwishDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    _VwishDialogRoute<T>(
      builder: builder,
      dismissible: barrierDismissible,
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    ),
  );
}

class _VwishDialogRoute<T> extends PopupRoute<T> {
  _VwishDialogRoute({
    required this.builder,
    required this.dismissible,
    required this.capturedThemes,
  });

  final WidgetBuilder builder;
  final bool dismissible;
  final CapturedThemes capturedThemes;

  CurvedAnimation? _curved;

  @override
  Color? get barrierColor => VwishColors.scrim;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => VwishMotion.normal;

  @override
  Duration get reverseTransitionDuration => VwishMotion.fast;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return capturedThemes.wrap(_VwishDialogFrame(child: Builder(builder: builder)));
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = _curved ??= CurvedAnimation(
      parent: animation,
      curve: VwishMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _curved?.dispose();
    super.dispose();
  }
}

class _VwishDialogFrame extends StatelessWidget {
  const _VwishDialogFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return vwishOverlayScope(
      context,
      SafeArea(
        child: AnimatedPadding(
          duration: VwishMotion.fast,
          curve: VwishMotion.curve,
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom) +
              const EdgeInsets.all(VwishSpacing.xl),
          child: MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class VwishDialog extends StatelessWidget {
  const VwishDialog({
    super.key,
    this.icon,
    this.glyph,
    this.iconColor = VwishColors.primaryLight,
    this.title,
    this.message,
    this.content,
    this.actions = const [],
    this.maxWidth = 420,
  });

  final IconData? icon;

  /// Drawn instead of [icon] when set.
  final VwishGlyphKind? glyph;
  final Color iconColor;
  final String? title;
  final String? message;
  final Widget? content;

  /// Cancel first, primary last; laid out by [VwishButtonBar].
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final body = <Widget>[
      if (icon != null || glyph != null) ...[
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.16),
            borderRadius: VwishRadius.mdAll,
          ),
          child: vwishIconOrGlyph(icon, glyph, size: 22, color: iconColor),
        ),
        const SizedBox(height: 14),
      ],
      if (title != null)
        Semantics(
          header: true,
          child: Text(title!, style: VwishTextStyles.title),
        ),
      if (message != null) ...[
        if (title != null) const SizedBox(height: 6),
        Text(message!, style: VwishTextStyles.bodySecondary),
      ],
      if (content != null) ...[
        if (title != null || message != null) const SizedBox(height: 16),
        content!,
      ],
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: VwishSurface(
        borderRadius: VwishRadius.dialogAll,
        shadow: VwishShadow.soft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, actions.isEmpty ? 20 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: body,
                ),
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: VwishButtonBar(children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showVwishConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
  VwishGlyphKind? glyph,
}) async {
  final result = await showVwishDialog<bool>(
    context,
    builder: (context) => VwishDialog(
      icon: icon,
      glyph: glyph,
      iconColor: destructive ? VwishColors.errorLight : VwishColors.primaryLight,
      title: title,
      message: message,
      actions: [
        VwishButton.secondary(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        VwishButton(
          label: confirmLabel,
          variant: destructive ? VwishButtonVariant.destructive : VwishButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Resolves to the trimmed (and [validator]-approved) text, or null when cancelled.
Future<String?> showVwishPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String? hint,
  String? initialValue,
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
  String? Function(String value)? validator,
  TextInputType keyboardType = TextInputType.text,
  IconData? prefixIcon,
}) {
  return showVwishDialog<String>(
    context,
    builder: (context) => _VwishPromptDialog(
      title: title,
      message: message,
      hint: hint,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      validator: validator,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
    ),
  );
}

class _VwishPromptDialog extends StatefulWidget {
  const _VwishPromptDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.validator,
    required this.keyboardType,
    required this.prefixIcon,
  });

  final String title;
  final String? message;
  final String? hint;
  final String? initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final String? Function(String value)? validator;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  @override
  State<_VwishPromptDialog> createState() => _VwishPromptDialogState();
}

class _VwishPromptDialogState extends State<_VwishPromptDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initialValue?.length ?? 0);
  String? _error;
  bool _attempted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    if (!_attempted) return;
    setState(() => _error = widget.validator?.call(_controller.text.trim()));
  }

  void _submit() {
    final value = _controller.text.trim();
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() {
        _attempted = true;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return VwishDialog(
      title: widget.title,
      message: widget.message,
      content: VwishTextField(
        controller: _controller,
        hint: widget.hint,
        prefixIcon: widget.prefixIcon,
        errorText: _error,
        autofocus: true,
        keyboardType: widget.keyboardType,
        textInputAction: TextInputAction.done,
        onChanged: _onChanged,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        VwishButton.secondary(
          label: widget.cancelLabel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        VwishButton.primary(label: widget.confirmLabel, onPressed: _submit),
      ],
    );
  }
}
