import 'package:flutter/material.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../library/library_widgets.dart';

/// A round avatar on the logo gradient: the profile's initials, or a person icon without them.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initials, this.size = 52});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        padding: EdgeInsets.all(size * 0.18),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [VwishLogoPainter.gradientStart, VwishLogoPainter.gradientEnd],
          ),
          boxShadow: VwishShadows.subtle,
        ),
        child: initials.isEmpty
            ? Icon(Icons.person_rounded, size: size * 0.52, color: VwishColors.onPrimary)
            // Initials keep their size at large text scales; the circle is fixed.
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  initials,
                  maxLines: 1,
                  softWrap: false,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    height: 1.1,
                    color: VwishColors.onPrimary,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Chevron for rows that open another page.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(VwishSpacing.sm),
      child: Icon(Icons.chevron_right_rounded, size: 22, color: VwishColors.textMuted),
    );
  }
}

/// A library row with a tinted icon tile that opens another page.
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.color = VwishColors.primaryLight,
    this.trailing,
    this.semanticLabel,
    this.subtitleMaxLines = 2,
    required this.onTap,
  }) : assert(icon != null || leading != null, 'Pass an icon or a leading widget');

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Drawn instead of the [icon] tile when set; 40pt square to line up with the dividers.
  final Widget? leading;
  final Color color;

  /// Replaces the chevron.
  final Widget? trailing;
  final String? semanticLabel;

  /// 1 for an address or number, which has nowhere to wrap and would break mid-word.
  final int subtitleMaxLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return VwishLibraryRow(
      leading: leading ?? VwishTileIcon(icon!, color: color, size: 40),
      title: title,
      titleMaxLines: 2,
      subtitle: subtitle,
      subtitleMaxLines: subtitleMaxLines,
      onTap: onTap,
      semanticLabel: semanticLabel,
      trailing: trailing ?? (onTap == null ? null : const SettingsChevron()),
    );
  }
}
