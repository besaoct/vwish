import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

const double vwishLibraryMaxWidth = 760;

double vwishLibraryGutter(double width) =>
    VwishBreakpoints.isCompactWidth(width) ? VwishSpacing.lg : VwishSpacing.xl;

/// Side padding that keeps library content at most [vwishLibraryMaxWidth] wide and centered.
EdgeInsets vwishLibraryInsets(double width) {
  final gutter = vwishLibraryGutter(width);
  final extra = math.max(0.0, (width - 2 * gutter - vwishLibraryMaxWidth) / 2);
  return EdgeInsets.symmetric(horizontal: gutter + extra);
}

/// Thin rounded watched-progress bar.
class VwishProgressLine extends StatelessWidget {
  const VwishProgressLine({
    super.key,
    required this.progress,
    this.height = 3,
    this.color = VwishColors.primary,
  });

  final double progress;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height);
    return Semantics(
      label: '${(value * 100).round()}% watched',
      child: Container(
        height: height,
        decoration: BoxDecoration(color: VwishColors.trackBackground, borderRadius: radius),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value,
          heightFactor: 1,
          child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: radius)),
        ),
      ),
    );
  }
}

/// A list row for media, folders and playlists: leading tile, two text lines, an optional
/// episode badge and progress bar, and a compact trailing control.
class VwishLibraryRow extends StatelessWidget {
  const VwishLibraryRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.badge,
    this.progress,
    this.onTap,
    this.dimmed = false,
    this.highlighted = false,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 1,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? badge;
  final double? progress;
  final VoidCallback? onTap;

  /// Fades the leading tile and mutes the title (e.g. a missing file); the subtitle switches to the
  /// error color so the explanation stays readable, and [trailing] stays usable.
  final bool dimmed;
  final bool highlighted;
  final int titleMaxLines;

  /// Raise for subtitles that carry instructions rather than metadata.
  final int subtitleMaxLines;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final showProgress = (progress ?? 0) > 0;
    final content = Row(
      children: [
        if (leading != null) ...[
          dimmed ? Opacity(opacity: 0.45, child: leading) : leading!,
          const SizedBox(width: VwishSpacing.md),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  letterSpacing: -0.1,
                  color: dimmed ? VwishColors.textSecondary : VwishColors.textPrimary,
                ),
              ),
              if (subtitle != null || badge != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (badge != null) ...[
                      VwishBadge(badge!),
                      const SizedBox(width: 6),
                    ],
                    if (subtitle != null)
                      Flexible(
                        child: Text(
                          subtitle!,
                          maxLines: subtitleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: dimmed ? VwishColors.errorLight : VwishColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (showProgress) ...[
                const SizedBox(height: VwishSpacing.sm),
                VwishProgressLine(progress: progress!),
              ],
            ],
          ),
        ),
      ],
    );

    return VwishPressable.builder(
      onTap: onTap,
      pressedScale: 1,
      semanticLabel: semanticLabel,
      isButton: onTap != null,
      builder: (context, state) {
        final background = state.pressed
            ? VwishColors.hover
            : (state.hovered || state.focused)
                ? VwishColors.hairlineSubtle
                : highlighted
                    ? VwishColors.primarySoft
                    : const Color(0x00FFFFFF);
        return AnimatedContainer(
          duration: VwishMotion.fast,
          curve: VwishMotion.curve,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
          decoration: BoxDecoration(color: background, borderRadius: VwishRadius.mdAll),
          foregroundDecoration: BoxDecoration(
            borderRadius: VwishRadius.mdAll,
            border: Border.fromBorderSide(
              state.focused ? VwishBorders.focus : VwishBorders.focus.copyWith(color: const Color(0x00FFFFFF)),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: content),
              if (trailing != null) ...[
                const SizedBox(width: VwishSpacing.xs),
                trailing!,
              ] else
                const SizedBox(width: 6),
            ],
          ),
        );
      },
    );
  }
}

/// Hairline between rows, indented to line up with the row text after a 40pt leading tile.
class VwishRowDivider extends StatelessWidget {
  const VwishRowDivider({super.key, this.indent = 64});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: 12),
      child: const SizedBox(
        height: VwishBorders.width,
        child: ColoredBox(color: VwishColors.hairlineSubtle),
      ),
    );
  }
}

/// An opaque card that groups library rows, separated by hairlines.
class VwishLibraryGroup extends StatelessWidget {
  const VwishLibraryGroup({super.key, required this.children, this.dividers = true});

  final List<Widget> children;
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    return VwishSurface(
      color: VwishColors.surface,
      padding: const EdgeInsets.all(VwishSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (dividers && i > 0) const VwishRowDivider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A compact explanatory state that sits inside a section instead of a list.
class VwishInlineEmpty extends StatelessWidget {
  const VwishInlineEmpty({
    super.key,
    this.icon,
    this.glyph,
    required this.title,
    this.message,
    this.action,
    this.iconColor = VwishColors.primaryLight,
  }) : assert(icon != null || glyph != null, 'Pass an icon or a glyph');

  final IconData? icon;

  /// Drawn instead of [icon] when set.
  final VwishGlyphKind? glyph;
  final String title;
  final String? message;
  final Widget? action;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return VwishSurface(
      color: VwishColors.surface,
      padding: const EdgeInsets.all(VwishSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (glyph != null)
            VwishTileIcon.glyph(glyph!, color: iconColor, size: 40)
          else
            VwishTileIcon(icon!, color: iconColor, size: 40),
          const SizedBox(width: VwishSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(title, style: VwishTextStyles.headline),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(message!, style: VwishTextStyles.caption.copyWith(fontSize: 13, height: 1.35)),
                ],
                if (action != null) ...[
                  const SizedBox(height: VwishSpacing.md),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opaque top bar for pushed library screens: back, title with an optional subtitle, actions.
/// Library page chrome: an opaque area behind the status bar (and the pinned [topBar]) that [body]
/// scrolls under, so content never looks cut off at the clock; a hairline marks the edge once scrolled.
class VwishLibraryFrame extends StatefulWidget {
  const VwishLibraryFrame({super.key, this.topBar, required this.body});

  final Widget? topBar;
  final Widget body;

  @override
  State<VwishLibraryFrame> createState() => _VwishLibraryFrameState();
}

class _VwishLibraryFrameState extends State<VwishLibraryFrame> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final scrolled = notification.metrics.pixels > notification.metrics.minScrollExtent;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final edge = _scrolled
        ? VwishColors.hairline
        : widget.topBar != null
            ? VwishColors.hairlineSubtle
            : VwishColors.hairline.withValues(alpha: 0);
    return Column(
      children: [
        // The window has no native title bar on desktop; this one drags it and holds its buttons.
        if (PlatformBridge.isDesktop && !context.isTouchPlatform) const VwishTitleBar(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: VwishColors.background,
            border: Border(bottom: BorderSide(color: edge, width: VwishBorders.width)),
          ),
          child: SafeArea(bottom: false, child: widget.topBar ?? const SizedBox(width: double.infinity)),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: SafeArea(
              top: false,
              bottom: false,
              child: NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.body),
            ),
          ),
        ),
      ],
    );
  }
}

class VwishLibraryTopBar extends StatelessWidget {
  const VwishLibraryTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = vwishLibraryInsets(constraints.maxWidth);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            math.max(4.0, insets.left - 12),
            6,
            math.max(4.0, insets.right - 8),
            6,
          ),
          child: Row(
            children: [
              if (onBack != null)
                VwishIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 18,
                  tooltip: 'Back',
                  onPressed: onBack,
                )
              else
                const SizedBox(width: 12),
              const SizedBox(width: VwishSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VwishTextStyles.title,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VwishTextStyles.caption,
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: VwishSpacing.xs),
                ...actions,
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Section title with an optional compact action (capped at half the width). [prominent]
/// gives the large white Home style; otherwise it is the quiet list-header style.
class VwishLibrarySectionHeader extends StatelessWidget {
  const VwishLibrarySectionHeader(
    this.title, {
    super.key,
    this.action,
    this.topSpacing = 28,
    this.prominent = false,
  });

  final String title;
  final Widget? action;
  final double topSpacing;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    if (!prominent) {
      return VwishSectionHeader(
        title,
        action: action,
        padding: EdgeInsets.fromLTRB(4, topSpacing, 0, VwishSpacing.sm),
      );
    }
    final text = Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: VwishTextStyles.title.copyWith(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topSpacing, 0, 10),
      child: action == null
          ? Align(alignment: AlignmentDirectional.centerStart, child: text)
          : LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: VwishSpacing.md),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                    child: action,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Calls [onReturn] when the route becomes visible again after a page on top of it was
/// popped, and when the app comes back to the foreground.
class VwishRefreshOnReturn extends StatefulWidget {
  const VwishRefreshOnReturn({super.key, required this.onReturn, required this.child});

  final VoidCallback onReturn;
  final Widget child;

  @override
  State<VwishRefreshOnReturn> createState() => _VwishRefreshOnReturnState();
}

class _VwishRefreshOnReturnState extends State<VwishRefreshOnReturn> with WidgetsBindingObserver {
  Animation<double>? _secondary;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context)?.secondaryAnimation;
    if (next == _secondary) return;
    _secondary?.removeStatusListener(_onSecondaryStatus);
    _secondary = next?..addStatusListener(_onSecondaryStatus);
  }

  void _onSecondaryStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward || status == AnimationStatus.completed) {
      _covered = true;
    } else if (status == AnimationStatus.dismissed && _covered) {
      _covered = false;
      widget.onReturn();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onReturn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _secondary?.removeStatusListener(_onSecondaryStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
