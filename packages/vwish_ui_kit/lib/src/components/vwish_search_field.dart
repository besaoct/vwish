import 'dart:async';

import 'package:flutter/material.dart';

import 'vwish_text_field.dart';

/// [VwishTextField] preset for searching: search icon, clear button, search keyboard action and a
/// debounced [onChanged].
///
/// [onChanged] fires [debounce] after the last keystroke, immediately when the text is cleared,
/// and immediately (before [onSubmitted]) when the user submits, so a pending query is never lost.
/// Pending callbacks are dropped when the field is disposed.
class VwishSearchField extends StatefulWidget {
  const VwishSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Search',
    this.debounce = const Duration(milliseconds: 250),
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel = 'Search',
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;

  /// [Duration.zero] reports every change right away.
  final Duration debounce;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String semanticLabel;

  @override
  State<VwishSearchField> createState() => _VwishSearchFieldState();
}

class _VwishSearchFieldState extends State<VwishSearchField> {
  Timer? _timer;
  String? _pending;

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = null;
    if (text.isEmpty || widget.debounce <= Duration.zero) {
      _pending = null;
      widget.onChanged?.call(text);
      return;
    }
    _pending = text;
    _timer = Timer(widget.debounce, _flush);
  }

  void _flush() {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    _pending = null;
    if (pending != null) widget.onChanged?.call(pending);
  }

  void _onSubmitted(String text) {
    if (_pending != null) {
      _pending = text;
      _flush();
    }
    widget.onSubmitted?.call(text);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VwishTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      hint: widget.hint,
      prefixIcon: Icons.search_rounded,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      onSubmitted: _onSubmitted,
      semanticLabel: widget.semanticLabel,
    );
  }
}
