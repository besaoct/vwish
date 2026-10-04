import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import 'library_actions.dart';
import 'library_format.dart';
import 'library_providers.dart';
import 'library_widgets.dart';
import 'media_picker.dart';
import 'open_link_dialog.dart';

/// A playlist: play/shuffle, add videos or links, reorder by dragging, rename and delete.
class VwishPlaylistScreen extends ConsumerStatefulWidget {
  const VwishPlaylistScreen({
    super.key,
    required this.name,
    required this.onBack,
    required this.onOpenPlayer,
    required this.onRenamed,
  });

  final String name;
  final VoidCallback onBack;
  final VoidCallback onOpenPlayer;

  /// Called with the new name after a rename so the route can be updated.
  final ValueChanged<String> onRenamed;

  @override
  ConsumerState<VwishPlaylistScreen> createState() => _VwishPlaylistScreenState();
}

class _VwishPlaylistScreenState extends ConsumerState<VwishPlaylistScreen> {
  late String _name = widget.name;
  List<MediaRef>? _lastItems;
  List<MediaRef>? _optimisticOrder;
  int _pendingMoves = 0;
  bool _closing = false;
  bool _busy = false;

  @override
  void didUpdateWidget(VwishPlaylistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) _name = widget.name;
  }

  void _playFrom(List<MediaRef> items, int index, {bool shuffle = false}) {
    if (!LibraryRepository.mediaExists(items[index])) {
      VwishToast.show(
        context,
        "This file isn't available anymore. It may have been moved or deleted.",
        kind: VwishToastKind.error,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    final playable = [
      for (var i = 0; i < items.length; i++)
        if (i == index || LibraryRepository.mediaExists(items[i])) items[i],
    ];
    vwishPlayItems(ref, playable, startIndex: playable.indexOf(items[index]), shuffle: shuffle);
    widget.onOpenPlayer();
  }

  void _playAll(List<MediaRef> items, {bool shuffle = false}) {
    final playable = items.where(LibraryRepository.mediaExists).toList();
    if (playable.isEmpty) {
      VwishToast.show(
        context,
        "None of these videos are available. They may have been moved or deleted.",
        kind: VwishToastKind.error,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    vwishPlayItems(ref, playable, shuffle: shuffle);
    widget.onOpenPlayer();
  }

  Future<void> _addVideos() async {
    if (_busy) return;
    _busy = true;
    try {
      final refs = await pickVideoRefs();
      if (refs.isNotEmpty && mounted) await addToPlaylistWithFeedback(context, ref, _name, refs);
    } catch (e) {
      if (mounted) showVwishError(context, e);
    } finally {
      _busy = false;
    }
  }

  Future<void> _addLink() async {
    final media = await showVwishOpenLinkDialog(
      context,
      title: 'Add link',
      confirmLabel: 'Add',
      confirmIcon: Icons.add_rounded,
    );
    if (media != null && mounted) await addToPlaylistWithFeedback(context, ref, _name, [media]);
  }

  Future<void> _rename() async {
    final renamed = await promptRenamePlaylist(context, ref, _name);
    if (renamed == null || !mounted) return;
    setState(() => _name = renamed);
    widget.onRenamed(renamed);
  }

  Future<void> _delete() async {
    final name = _name;
    if (!await confirmDeletePlaylist(context, name) || !mounted) return;
    setState(() => _closing = true);
    await ref.read(libraryControllerProvider.notifier).deletePlaylist(name);
    if (!mounted) return;
    showVwishSuccess(context, 'Deleted "$name"');
    widget.onBack();
  }

  Future<void> _move(List<MediaRef> items, int from, int to) async {
    if (to == from) return;
    final reordered = List.of(items);
    reordered.insert(to, reordered.removeAt(from));
    setState(() {
      _optimisticOrder = reordered;
      _pendingMoves++;
    });
    try {
      await ref.read(libraryControllerProvider.notifier).movePlaylistItem(_name, from, to);
    } finally {
      if (mounted) {
        setState(() {
          if (--_pendingMoves == 0) _optimisticOrder = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watched = ref.watch(playlistItemsProvider(_name));
    if (watched != null) _lastItems = watched;
    final items = _optimisticOrder ?? watched ?? (_closing ? _lastItems : null);

    return VwishRefreshOnReturn(
      onReturn: () => ref.read(libraryControllerProvider.notifier).refresh(),
      child: Scaffold(
        backgroundColor: VwishColors.background,
        body: VwishLibraryFrame(
          topBar: VwishLibraryTopBar(
            title: _name,
            subtitle: items == null ? null : 'Playlist · ${formatCount(items.length, 'video')}',
            onBack: widget.onBack,
            actions: [
              if (items != null)
                VwishMenuIconTrigger(
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'Playlist options',
                  entries: [
                    VwishMenuItem(label: 'Rename', icon: Icons.edit_rounded, onTap: _rename),
                    VwishMenuItem(
                      label: 'Delete playlist',
                      icon: Icons.delete_outline_rounded,
                      destructive: true,
                      onTap: _delete,
                    ),
                  ],
                ),
            ],
          ),
          body: _body(context, items),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<MediaRef>? items) {
    if (items == null) {
      return VwishEmptyState(
        icon: Icons.playlist_remove_rounded,
        title: 'Playlist not found',
        message: 'It may have been renamed or deleted.',
        actions: [VwishButton.secondary(label: 'Go back', icon: Icons.arrow_back_rounded, onPressed: widget.onBack)],
      );
    }
    if (items.isEmpty) {
      return VwishEmptyState(
        icon: Icons.queue_music_rounded,
        iconColor: VwishColors.purple,
        title: 'This playlist is empty',
        message: 'Add videos from your device or paste a link to a stream.',
        actions: [
          VwishButton.primary(label: 'Add videos', icon: Icons.video_library_rounded, onPressed: _addVideos),
          VwishButton.secondary(label: 'Add link', icon: Icons.link_rounded, onPressed: _addLink),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = vwishLibraryInsets(constraints.maxWidth);
        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding:
              insets.copyWith(top: VwishSpacing.lg, bottom: MediaQuery.paddingOf(context).bottom + VwishSpacing.xxl),
          header: _PlaylistHeader(
            count: items.length,
            onPlay: () => _playAll(items),
            onShuffle: () => _playAll(items, shuffle: true),
            onAddVideos: _addVideos,
            onAddLink: _addLink,
          ),
          itemCount: items.length,
          onReorderItem: (from, to) => _move(items, from, to),
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(animation.value);
              return Transform.scale(
                scale: 1 + 0.02 * t,
                child: Material(
                  type: MaterialType.transparency,
                  child: VwishSurface(
                    color: VwishColors.surfaceElevated,
                    borderRadius: VwishRadius.mdAll,
                    shadow: VwishShadow.soft,
                    child: _row(items, index, divider: false),
                  ),
                ),
              );
            },
          ),
          itemBuilder: (context, index) => KeyedSubtree(
            key: ValueKey(items[index].pathOrUri),
            child: _row(items, index, divider: index < items.length - 1),
          ),
        );
      },
    );
  }

  Widget _row(List<MediaRef> items, int index, {required bool divider}) {
    final media = items[index];
    final exists = LibraryRepository.mediaExists(media);
    final resume = ref.read(libraryControllerProvider.notifier).resumeInfoFor(media);
    final row = VwishLibraryRow(
      leading: VwishTileIcon(mediaIcon(media), color: mediaIconColor(media), size: 40),
      title: media.title,
      titleMaxLines: 2,
      badge: episodeLabel(media),
      subtitle: mediaSubtitle(media, resume, exists: exists, fallback: parentFolderName(media.pathOrUri)),
      progress: exists ? resume?.progress : null,
      dimmed: !exists,
      onTap: () => _playFrom(items, index),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VwishMenuIconTrigger(
            icon: Icons.more_horiz_rounded,
            tooltip: 'More',
            entries: [
              VwishMenuItem(
                label: 'Play from here',
                icon: Icons.play_arrow_rounded,
                enabled: exists,
                onTap: () => _playFrom(items, index),
              ),
              const VwishMenuDivider(),
              VwishMenuItem(
                label: 'Remove from playlist',
                icon: Icons.remove_circle_outline_rounded,
                destructive: true,
                onTap: () => ref.read(libraryControllerProvider.notifier).removeFromPlaylist(_name, index),
              ),
            ],
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Tooltip(
              message: 'Drag to reorder',
              child: SizedBox(
                width: 36,
                height: 44,
                child: Icon(Icons.drag_indicator_rounded, size: 20, color: VwishColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
    if (!divider) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [row, const VwishRowDivider()],
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({
    required this.count,
    required this.onPlay,
    required this.onShuffle,
    required this.onAddVideos,
    required this.onAddLink,
  });

  final int count;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback onAddVideos;
  final VoidCallback onAddLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VwishSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const VwishTileIcon(Icons.queue_music_rounded, color: VwishColors.purple, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCount(count, 'video'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VwishTextStyles.title,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count > 1 ? 'Drag the handle to change the order' : 'Add more videos or links anytime',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VwishTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VwishSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VwishButtonBar(
                    children: [
                      VwishButton.primary(label: 'Play', icon: Icons.play_arrow_rounded, onPressed: onPlay),
                      VwishButton.secondary(
                        label: 'Shuffle',
                        icon: Icons.shuffle_rounded,
                        onPressed: count > 1 ? onShuffle : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: VwishSpacing.sm),
                  VwishButtonBar(
                    reverseWhenStacked: false,
                    children: [
                      VwishButton.ghost(
                        label: 'Add videos',
                        icon: Icons.video_library_rounded,
                        size: VwishButtonSize.sm,
                        onPressed: onAddVideos,
                      ),
                      VwishButton.ghost(
                        label: 'Add link',
                        icon: Icons.add_link_rounded,
                        size: VwishButtonSize.sm,
                        onPressed: onAddLink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
