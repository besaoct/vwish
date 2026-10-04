import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../controllers/providers.dart';
import 'add_to_playlist_sheet.dart';
import 'library_actions.dart';
import 'library_controller.dart';
import 'library_format.dart';
import 'library_providers.dart';
import 'library_widgets.dart';
import 'media_picker.dart';
import 'open_link_dialog.dart';

/// Start screen: now playing, quick open actions, continue watching, playlists and folders.
class VwishHomeScreen extends ConsumerStatefulWidget {
  const VwishHomeScreen({
    super.key,
    required this.onOpenPlayer,
    required this.onOpenFolder,
    required this.onOpenPlaylist,
    this.onOpenSettings,
  });

  final VoidCallback onOpenPlayer;
  final ValueChanged<String> onOpenFolder;
  final ValueChanged<String> onOpenPlaylist;

  /// Shows a settings button at the end of the header when set.
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<VwishHomeScreen> createState() => _VwishHomeScreenState();
}

class _VwishHomeScreenState extends ConsumerState<VwishHomeScreen> {
  static const _recentPreviewCount = 6;

  bool _showAllRecent = false;
  bool _busy = false;

  LibraryController get _library => ref.read(libraryControllerProvider.notifier);

  void _play(List<MediaRef> items, {int startIndex = 0, bool shuffle = false}) {
    if (items.isEmpty) return;
    vwishPlayItems(ref, items, startIndex: startIndex, shuffle: shuffle);
    widget.onOpenPlayer();
  }

  /// Runs a picker flow once at a time and turns failures into an error toast.
  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } catch (e) {
      if (mounted) showVwishError(context, e);
    } finally {
      _busy = false;
    }
  }

  Future<void> _openFile() => _guarded(() async {
        final refs = await pickVideoRefs();
        if (refs.isNotEmpty && mounted) _play(refs);
      });

  Future<void> _openFolder() => _guarded(() async {
        if (canPickFolders) {
          final path = await pickFolderPath();
          if (path == null || !mounted) return;
          final folder = await _library.addFolder(path);
          if (mounted) widget.onOpenFolder(folder.path);
          return;
        }
        final device =
            ref.read(libraryControllerProvider).deviceFolder ?? await ref.read(libraryRepositoryProvider).getDeviceFolder();
        if (device != null && mounted) widget.onOpenFolder(device.path);
      });

  Future<void> _addFolder() => _guarded(() async {
        final path = await pickFolderPath();
        if (path == null || !mounted) return;
        final folder = await _library.addFolder(path);
        if (mounted) showVwishSuccess(context, 'Added "${folder.label}" to your library');
      });

  Future<void> _openLink() async {
    final media = await showVwishOpenLinkDialog(context);
    if (media != null && mounted) _play([media]);
  }

  void _playRecent(LibraryRecentItem item) {
    if (!item.exists) {
      VwishToast.show(
        context,
        "This file isn't available anymore. It may have been moved or deleted.",
        kind: VwishToastKind.error,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    _play([item.media]);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showVwishConfirm(
      context,
      title: 'Clear Continue watching',
      message: 'Your watch history and resume points will be cleared. Your files stay on disk.',
      confirmLabel: 'Clear',
      destructive: true,
      icon: Icons.history_rounded,
    );
    if (!confirmed) return;
    await _library.clearHistory();
    if (mounted) setState(() => _showAllRecent = false);
  }

  Future<void> _newPlaylist() async {
    final name = await promptNewPlaylist(context, ref);
    if (name != null && mounted) widget.onOpenPlaylist(name);
  }

  void _playPlaylist(String name, {bool shuffle = false}) {
    final items = _library.playlistItems(name);
    if (items.isEmpty) {
      VwishToast.show(context, '"$name" is empty. Add videos to play it.', icon: Icons.info_outline_rounded);
      return;
    }
    _play(items, shuffle: shuffle);
  }

  Future<void> _renamePlaylist(String name) async {
    final renamed = await promptRenamePlaylist(context, ref, name);
    if (renamed != null && mounted) showVwishSuccess(context, 'Renamed to "$renamed"');
  }

  Future<void> _deletePlaylist(String name) async {
    if (!await confirmDeletePlaylist(context, name)) return;
    await _library.deletePlaylist(name);
    if (mounted) showVwishSuccess(context, 'Deleted "$name"');
  }

  Future<void> _playFolder(LibraryFolder folder) async {
    final listing = await LibraryRepository.browseDirectory(folder.path);
    if (!mounted) return;
    if (listing.hasError) {
      VwishToast.show(context, listing.error!, kind: VwishToastKind.error, icon: Icons.error_outline_rounded);
    } else if (listing.media.isEmpty) {
      VwishToast.show(
        context,
        'No videos directly in "${folder.label}". Open it to browse its folders.',
        icon: Icons.info_outline_rounded,
      );
    } else {
      _play(listing.media);
    }
  }

  Future<void> _removeFolder(LibraryFolder folder) async {
    final confirmed = await showVwishConfirm(
      context,
      title: 'Remove from library',
      message: '"${folder.label}" will be removed from Vwish. Your files stay on disk.',
      confirmLabel: 'Remove',
      destructive: true,
      icon: Icons.remove_circle_outline_rounded,
    );
    if (confirmed) await _library.removeFolder(folder.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryControllerProvider);
    return VwishRefreshOnReturn(
      onReturn: () => _library.refresh(),
      child: Scaffold(
        backgroundColor: VwishColors.background,
        body: VwishLibraryFrame(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final insets = vwishLibraryInsets(constraints.maxWidth);
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: insets.copyWith(
                      top: VwishSpacing.xl,
                      bottom: MediaQuery.paddingOf(context).bottom + VwishSpacing.xxl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _HomeHeader(onOpenSettings: widget.onOpenSettings),
                        const SizedBox(height: VwishSpacing.xl),
                        _NowPlayingCard(onOpen: widget.onOpenPlayer),
                        _QuickActions(
                          actions: [
                            _QuickAction(
                              'Open file',
                              'Pick videos to play',
                              VwishColors.primaryLight,
                              _openFile,
                              icon: Icons.video_file_rounded,
                            ),
                            _QuickAction(
                              'Open folder',
                              canPickFolders ? 'Browse a folder' : 'Videos on this device',
                              VwishColors.purple,
                              _openFolder,
                              glyph: VwishGlyphKind.folderOpen,
                            ),
                            _QuickAction(
                              'Open link',
                              'Stream from a URL',
                              VwishColors.cyan,
                              _openLink,
                              icon: Icons.link_rounded,
                            ),
                          ],
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: VwishSpacing.xl),
                          VwishInlineEmpty(
                            icon: Icons.error_outline_rounded,
                            iconColor: VwishColors.errorLight,
                            title: state.error!,
                            message: 'Your files are safe. Try loading the library again.',
                            action: VwishButton.secondary(
                              label: 'Try again',
                              icon: Icons.refresh_rounded,
                              size: VwishButtonSize.sm,
                              onPressed: () => _library.refresh(),
                            ),
                          ),
                        ],
                        if (state.hasLoaded) ...[
                          ..._recentSection(state.recent),
                          ..._playlistSection(state.playlists),
                          ..._folderSection(state.roots),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _recentSection(List<LibraryRecentItem> recent) {
    if (recent.isEmpty) return const [];
    final visible = _showAllRecent ? recent : recent.take(_recentPreviewCount);
    return [
      VwishLibrarySectionHeader(
        'Continue watching',
        prominent: true,
        action: VwishButton.ghost(label: 'Clear', size: VwishButtonSize.sm, onPressed: _clearHistory),
      ),
      VwishLibraryGroup(children: [for (final item in visible) _recentRow(item)]),
      if (recent.length > _recentPreviewCount)
        Padding(
          padding: const EdgeInsets.only(top: VwishSpacing.sm),
          child: Center(
            child: VwishButton.ghost(
              label: _showAllRecent ? 'Show less' : 'Show all ${recent.length}',
              trailingIcon: _showAllRecent ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: VwishButtonSize.sm,
              onPressed: () => setState(() => _showAllRecent = !_showAllRecent),
            ),
          ),
        ),
    ];
  }

  Widget _recentRow(LibraryRecentItem item) {
    final media = item.media;
    return VwishLibraryRow(
      leading: VwishTileIcon(mediaIcon(media), color: mediaIconColor(media), size: 40),
      title: media.title,
      badge: episodeLabel(media),
      subtitle: mediaSubtitle(media, item.resume, exists: item.exists, fallback: parentFolderName(media.pathOrUri)),
      progress: item.exists ? item.progress : null,
      dimmed: !item.exists,
      onTap: () => _playRecent(item),
      trailing: VwishMenuIconTrigger(
        icon: Icons.more_horiz_rounded,
        tooltip: 'More',
        entries: [
          VwishMenuItem(
            label: 'Play',
            icon: Icons.play_arrow_rounded,
            enabled: item.exists,
            onTap: () => _playRecent(item),
          ),
          VwishMenuItem(
            label: 'Add to playlist…',
            icon: Icons.playlist_add_rounded,
            onTap: () => showVwishAddToPlaylistSheet(context, [media]),
          ),
          const VwishMenuDivider(),
          VwishMenuItem(
            label: 'Remove from history',
            icon: Icons.remove_circle_outline_rounded,
            destructive: true,
            onTap: () => _library.removeFromHistory(media),
          ),
        ],
      ),
    );
  }

  List<Widget> _playlistSection(List<PlaylistSummary> playlists) {
    return [
      VwishLibrarySectionHeader(
        'Playlists',
        prominent: true,
        action: playlists.isEmpty
            ? null
            : VwishButton.ghost(
                label: 'New',
                icon: Icons.add_rounded,
                size: VwishButtonSize.sm,
                onPressed: _newPlaylist,
              ),
      ),
      if (playlists.isEmpty)
        VwishInlineEmpty(
          icon: Icons.queue_music_rounded,
          iconColor: VwishColors.purple,
          title: 'No playlists yet',
          message: 'Collect videos and links to play them in order.',
          action: VwishButton.tonal(
            label: 'New playlist',
            icon: Icons.add_rounded,
            size: VwishButtonSize.sm,
            onPressed: _newPlaylist,
          ),
        )
      else
        VwishLibraryGroup(
          children: [
            for (final playlist in playlists)
              VwishLibraryRow(
                leading: const VwishTileIcon(Icons.queue_music_rounded, color: VwishColors.purple, size: 40),
                title: playlist.name,
                subtitle: playlist.itemCount == 0 ? 'No videos yet' : formatCount(playlist.itemCount, 'video'),
                onTap: () => widget.onOpenPlaylist(playlist.name),
                trailing: VwishMenuIconTrigger(
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'More',
                  entries: [
                    VwishMenuItem(
                      label: 'Play',
                      icon: Icons.play_arrow_rounded,
                      enabled: playlist.itemCount > 0,
                      onTap: () => _playPlaylist(playlist.name),
                    ),
                    VwishMenuItem(
                      label: 'Shuffle',
                      icon: Icons.shuffle_rounded,
                      enabled: playlist.itemCount > 1,
                      onTap: () => _playPlaylist(playlist.name, shuffle: true),
                    ),
                    const VwishMenuDivider(),
                    VwishMenuItem(
                      label: 'Rename',
                      icon: Icons.edit_rounded,
                      onTap: () => _renamePlaylist(playlist.name),
                    ),
                    VwishMenuItem(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      destructive: true,
                      onTap: () => _deletePlaylist(playlist.name),
                    ),
                  ],
                ),
              ),
          ],
        ),
    ];
  }

  List<Widget> _folderSection(List<LibraryFolder> roots) {
    return [
      VwishLibrarySectionHeader(
        'Folders',
        prominent: true,
        action: canPickFolders && roots.isNotEmpty
            ? VwishButton.ghost(
                label: 'Add',
                icon: Icons.add_rounded,
                size: VwishButtonSize.sm,
                onPressed: _addFolder,
              )
            : null,
      ),
      if (roots.isEmpty)
        VwishInlineEmpty(
          glyph: VwishGlyphKind.folderVideo,
          iconColor: VwishColors.primaryLight,
          title: 'No folders yet',
          message: canPickFolders
              ? 'Add a folder to browse its videos here. Nothing is copied or moved.'
              : 'Use Open file to add videos from your device.',
          action: canPickFolders
              ? VwishButton.tonal(
                  label: 'Add folder',
                  glyph: VwishGlyphKind.folderAdd,
                  size: VwishButtonSize.sm,
                  onPressed: _addFolder,
                )
              : null,
        )
      else
        VwishLibraryGroup(children: [for (final folder in roots) _folderRow(folder)]),
    ];
  }

  Widget _folderRow(LibraryFolder folder) {
    if (folder.isDevice) {
      return VwishLibraryRow(
        leading: const VwishTileIcon.glyph(VwishGlyphKind.device, color: VwishColors.cyan, size: 40),
        title: folder.label,
        subtitle: Theme.of(context).platform == TargetPlatform.iOS
            ? 'Files app › On My iPhone › Vwish'
            : 'Device storage',
        subtitleMaxLines: 2,
        onTap: () => widget.onOpenFolder(folder.path),
        trailing: const Padding(
          padding: EdgeInsets.all(VwishSpacing.sm),
          child: Icon(Icons.chevron_right_rounded, size: 22, color: VwishColors.textMuted),
        ),
      );
    }
    return VwishLibraryRow(
      leading: const VwishTileIcon.glyph(VwishGlyphKind.folderVideo, size: 40),
      title: folder.label,
      subtitle: folder.path,
      onTap: () => widget.onOpenFolder(folder.path),
      trailing: VwishMenuIconTrigger(
        icon: Icons.more_horiz_rounded,
        tooltip: 'More',
        entries: [
          VwishMenuItem(
            label: 'Open',
            glyph: VwishGlyphKind.folderOpen,
            onTap: () => widget.onOpenFolder(folder.path),
          ),
          VwishMenuItem(
            label: 'Play all',
            icon: Icons.play_arrow_rounded,
            onTap: () => _playFolder(folder),
          ),
          const VwishMenuDivider(),
          VwishMenuItem(
            label: 'Remove from library',
            icon: Icons.remove_circle_outline_rounded,
            destructive: true,
            onTap: () => _removeFolder(folder),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const VwishLogo(size: 36),
        const SizedBox(width: VwishSpacing.md),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Vwish',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VwishTextStyles.largeTitle.copyWith(fontSize: 26, height: 1.15),
            ),
          ),
        ),
        if (onOpenSettings != null) ...[
          const SizedBox(width: VwishSpacing.sm),
          VwishIconButton(
            icon: Icons.settings_rounded,
            variant: VwishIconButtonVariant.tonal,
            size: 44,
            iconSize: 22,
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ],
    );
  }
}

class _NowPlayingCard extends ConsumerWidget {
  const _NowPlayingCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(queueControllerProvider.select((q) => q.currentItem));
    if (media == null) return const SizedBox.shrink();
    final (status, position, duration) = ref.watch(
      playerControllerProvider.select((s) => (s.status, s.position.inSeconds, s.duration.inSeconds)),
    );
    final playing = status == PlaybackStatus.playing || status == PlaybackStatus.buffering;
    final progress = duration > 0 ? position / duration : 0.0;
    final subtitle = switch (status) {
      PlaybackStatus.loading => 'Loading…',
      PlaybackStatus.error => "Couldn't play this video",
      _ when duration > 0 =>
        '${formatClock(Duration(seconds: position))} / ${formatClock(Duration(seconds: duration))}',
      _ => mediaHost(media) ?? 'Ready to play',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: VwishSpacing.md),
      child: VwishPressable(
        onTap: onOpen,
        borderRadius: VwishRadius.lgAll,
        semanticLabel: 'Now playing: ${media.title}. Open player',
        child: VwishSurface(
          shadow: VwishShadow.subtle,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  VwishTileIcon(
                    playing ? Icons.graphic_eq_rounded : mediaIcon(media),
                    color: VwishColors.primaryLight,
                    size: 44,
                  ),
                  const SizedBox(width: VwishSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOW PLAYING',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VwishTextStyles.micro.copyWith(
                            color: VwishColors.primaryLight,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          media.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VwishTextStyles.headline,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VwishTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VwishSpacing.sm),
                  VwishIconButton(
                    icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    variant: VwishIconButtonVariant.primary,
                    size: 44,
                    tooltip: playing ? 'Pause' : 'Play',
                    onPressed: () => ref.read(playerControllerProvider.notifier).togglePlay(),
                  ),
                ],
              ),
              if (progress > 0) ...[
                const SizedBox(height: VwishSpacing.md),
                VwishProgressLine(progress: progress),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.caption, this.color, this.onTap, {this.icon, this.glyph})
      : assert(icon != null || glyph != null);

  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final VwishGlyphKind? glyph;

  Widget tile(double size) => glyph != null
      ? VwishTileIcon.glyph(glyph!, color: color, size: size)
      : VwishTileIcon(icon!, color: color, size: size);
}

/// Three equal tiles in a row: icon beside the text when tiles are wide, icon above the
/// label when narrow, and two columns (last tile full width) when labels would not fit.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions});

  final List<_QuickAction> actions;

  static const _gap = 10.0;
  static const _minTileWidth = 96.0;
  static const _wideTileWidth = 190.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final width = constraints.maxWidth;
        final tileWidth = (width - _gap * (actions.length - 1)) / actions.length;
        if (width >= actions.length * _minTileWidth * scale + (actions.length - 1) * _gap) {
          final horizontal = tileWidth >= _wideTileWidth * scale;
          return _row([for (final action in actions) _QuickActionTile(action: action, horizontal: horizontal)]);
        }
        final tiles = [for (final action in actions) _QuickActionTile(action: action, horizontal: false)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i += 2) ...[
              if (i > 0) const SizedBox(height: _gap),
              _row(tiles.sublist(i, i + 2 > tiles.length ? tiles.length : i + 2)),
            ],
          ],
        );
      },
    );
  }

  Widget _row(List<Widget> tiles) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.horizontal});

  final _QuickAction action;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      action.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: VwishTextStyles.headline.copyWith(fontSize: horizontal ? 15 : 14),
    );
    return VwishPressable(
      onTap: action.onTap,
      borderRadius: VwishRadius.lgAll,
      semanticLabel: action.label,
      child: VwishSurface(
        padding: horizontal ? const EdgeInsets.all(14) : const EdgeInsets.fromLTRB(10, 16, 10, 14),
        child: horizontal
            ? Row(
                children: [
                  action.tile(40),
                  const SizedBox(width: VwishSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        const SizedBox(height: 2),
                        Text(
                          action.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VwishTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  action.tile(44),
                  const SizedBox(height: 10),
                  label,
                ],
              ),
      ),
    );
  }
}
