import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../controllers/providers.dart';
import 'add_to_playlist_sheet.dart';
import 'library_actions.dart';
import 'library_format.dart';
import 'library_providers.dart';
import 'library_widgets.dart';

/// One level of a folder: subfolders first, then videos, with play-all and shuffle.
class VwishFolderScreen extends ConsumerStatefulWidget {
  const VwishFolderScreen({
    super.key,
    required this.path,
    required this.onBack,
    required this.onOpenFolder,
    required this.onOpenPlayer,
    this.onJumpToFolder,
  });

  final String path;
  final VoidCallback onBack;

  /// Opens a subfolder on top of this screen.
  final ValueChanged<String> onOpenFolder;
  final VoidCallback onOpenPlayer;

  /// Opens an ancestor picked from the breadcrumb; defaults to [onOpenFolder].
  final ValueChanged<String>? onJumpToFolder;

  @override
  ConsumerState<VwishFolderScreen> createState() => _VwishFolderScreenState();
}

typedef _Crumb = ({String label, String path});

class _VwishFolderScreenState extends ConsumerState<VwishFolderScreen> {
  void _reload() => ref.invalidate(folderListingProvider(widget.path));

  void _play(List<MediaRef> items, {int startIndex = 0, bool shuffle = false}) {
    if (items.isEmpty) return;
    vwishPlayItems(ref, items, startIndex: startIndex, shuffle: shuffle);
    widget.onOpenPlayer();
  }

  /// With nothing queued there is nothing to play after or append to, so it just plays.
  bool _playIfIdle(MediaRef media) {
    if (ref.read(queueControllerProvider).hasCurrent) return false;
    _play([media]);
    return true;
  }

  Future<void> _playNext(MediaRef media) async {
    if (_playIfIdle(media)) return;
    await ref.read(queueControllerProvider.notifier).playNext(media);
    if (mounted) showVwishSuccess(context, 'Playing next');
  }

  Future<void> _addToQueue(MediaRef media) async {
    if (_playIfIdle(media)) return;
    await ref.read(queueControllerProvider.notifier).addToQueue([media]);
    if (mounted) showVwishSuccess(context, 'Added to queue');
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(folderListingProvider(widget.path));
    final roots = ref.watch(libraryControllerProvider.select((s) => s.roots));
    final root = _rootFor(widget.path, roots);
    final isRoot = root != null && _samePath(root.path, widget.path);
    final listing = listingAsync.valueOrNull;

    return VwishRefreshOnReturn(
      onReturn: _reload,
      child: Scaffold(
        backgroundColor: VwishColors.background,
        body: VwishLibraryFrame(
          topBar: VwishLibraryTopBar(
            title: isRoot ? root.label : listing?.name ?? _basename(widget.path),
            subtitle: listing == null || listing.hasError || listing.isEmpty ? null : _summary(listing),
            onBack: widget.onBack,
            actions: [
              VwishIconButton(icon: Icons.refresh_rounded, tooltip: 'Refresh', onPressed: _reload),
            ],
          ),
          body: listingAsync.when(
            loading: () => const Center(child: VwishSpinner(size: 28)),
            error: (error, _) => VwishEmptyState(
              icon: Icons.error_outline_rounded,
              iconColor: VwishColors.errorLight,
              title: "Couldn't open this folder",
              message: vwishErrorMessage(error),
              actions: [_tryAgainButton()],
            ),
            data: (listing) => _body(context, listing, root, isDevice: isRoot && root.isDevice),
          ),
        ),
      ),
    );
  }

  Widget _tryAgainButton() =>
      VwishButton.secondary(label: 'Try again', icon: Icons.refresh_rounded, onPressed: _reload);

  Widget _body(BuildContext context, DirectoryListing listing, LibraryFolder? root, {required bool isDevice}) {
    if (listing.hasError) {
      return VwishEmptyState(
        glyph: VwishGlyphKind.folderOff,
        iconColor: VwishColors.errorLight,
        title: "Can't open this folder",
        message: listing.error,
        actions: [_tryAgainButton()],
      );
    }
    if (listing.isEmpty) {
      return VwishEmptyState(
        glyph: isDevice ? VwishGlyphKind.device : VwishGlyphKind.folderOpen,
        iconColor: isDevice ? VwishColors.cyan : VwishColors.primaryLight,
        title: isDevice ? 'No videos on this device yet' : 'No videos here',
        message: _emptyMessage(context, isDevice: isDevice),
        actions: [
          VwishButton.secondary(label: 'Refresh', icon: Icons.refresh_rounded, onPressed: _reload),
        ],
      );
    }

    final media = listing.media;
    final folders = listing.folders;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = vwishLibraryInsets(constraints.maxWidth);
        final crumbs =
            VwishBreakpoints.isCompactWidth(constraints.maxWidth) ? const <_Crumb>[] : _crumbs(widget.path, root);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: insets.copyWith(top: VwishSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (crumbs.length > 1) ...[
                      _Breadcrumbs(
                        crumbs: crumbs,
                        rootGlyph: root?.isDevice == true ? VwishGlyphKind.device : VwishGlyphKind.folderVideo,
                        onTap: widget.onJumpToFolder ?? widget.onOpenFolder,
                      ),
                      const SizedBox(height: VwishSpacing.md),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: VwishButtonBar(
                          children: [
                            VwishButton.primary(
                              label: 'Play all',
                              icon: Icons.play_arrow_rounded,
                              onPressed: media.isEmpty ? null : () => _play(media),
                            ),
                            VwishButton.secondary(
                              label: 'Shuffle',
                              icon: Icons.shuffle_rounded,
                              onPressed: media.isEmpty ? null : () => _play(media, shuffle: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (folders.isNotEmpty) ...[
              SliverPadding(
                padding: insets,
                sliver: const SliverToBoxAdapter(child: VwishLibrarySectionHeader('Folders', topSpacing: 20)),
              ),
              SliverPadding(
                padding: insets,
                sliver: SliverList.separated(
                  itemCount: folders.length,
                  separatorBuilder: (context, _) => const VwishRowDivider(),
                  itemBuilder: (context, index) => _folderRow(folders[index]),
                ),
              ),
            ],
            if (media.isNotEmpty) ...[
              SliverPadding(
                padding: insets,
                sliver: const SliverToBoxAdapter(child: VwishLibrarySectionHeader('Videos', topSpacing: 20)),
              ),
              SliverPadding(
                padding: insets,
                sliver: SliverList.separated(
                  itemCount: media.length,
                  separatorBuilder: (context, _) => const VwishRowDivider(),
                  itemBuilder: (context, index) => _mediaRow(media, index),
                ),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: bottomInset + VwishSpacing.xxl)),
          ],
        );
      },
    );
  }

  Widget _folderRow(LibraryFolderEntry folder) {
    final count = folder.mediaCount;
    return VwishLibraryRow(
      leading: const VwishTileIcon.glyph(VwishGlyphKind.folder, color: VwishColors.purple, size: 40),
      title: folder.name,
      titleMaxLines: 2,
      subtitle: count == null ? null : (count == 0 ? 'No videos' : formatCount(count, 'video')),
      onTap: () => widget.onOpenFolder(folder.path),
      trailing: const Padding(
        padding: EdgeInsets.all(VwishSpacing.sm),
        child: Icon(Icons.chevron_right_rounded, size: 22, color: VwishColors.textMuted),
      ),
    );
  }

  Widget _mediaRow(List<MediaRef> media, int index) {
    final item = media[index];
    final resume = ref.read(libraryControllerProvider.notifier).resumeInfoFor(item);
    return VwishLibraryRow(
      leading: const VwishTileIcon(Icons.movie_rounded, size: 40),
      title: item.title,
      titleMaxLines: 2,
      badge: episodeLabel(item),
      subtitle: mediaSubtitle(item, resume, exists: true, fallback: fileExtensionLabel(item.pathOrUri)),
      progress: resume?.progress,
      onTap: () => _play(media, startIndex: index),
      trailing: VwishMenuIconTrigger(
        icon: Icons.more_horiz_rounded,
        tooltip: 'More',
        entries: [
          VwishMenuItem(
            label: 'Play',
            icon: Icons.play_arrow_rounded,
            onTap: () => _play(media, startIndex: index),
          ),
          VwishMenuItem(
            label: 'Play next',
            icon: Icons.queue_play_next_rounded,
            onTap: () => _playNext(item),
          ),
          VwishMenuItem(
            label: 'Add to queue',
            icon: Icons.add_to_queue_rounded,
            onTap: () => _addToQueue(item),
          ),
          const VwishMenuDivider(),
          VwishMenuItem(
            label: 'Add to playlist…',
            icon: Icons.playlist_add_rounded,
            onTap: () => showVwishAddToPlaylistSheet(context, [item]),
          ),
        ],
      ),
    );
  }

  String _emptyMessage(BuildContext context, {required bool isDevice}) {
    if (!isDevice) return 'This folder has no videos or subfolders.';
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return 'In the Files app, copy videos to On My iPhone › Vwish. '
          'On a Mac, you can also drag them into Vwish with Finder file sharing.';
    }
    return 'Videos you open with Open file are kept here, ready to play again.';
  }
}

String _summary(DirectoryListing listing) {
  final parts = [
    if (listing.folders.isNotEmpty) formatCount(listing.folders.length, 'folder'),
    if (listing.media.isNotEmpty) formatCount(listing.media.length, 'video'),
  ];
  return parts.join(' · ');
}

String _trimSeparators(String path) {
  final trimmed = path.replaceFirst(RegExp(r'[/\\]+$'), '');
  return trimmed.isEmpty || trimmed.endsWith(':') ? path : trimmed;
}

bool _samePath(String a, String b) => _trimSeparators(a) == _trimSeparators(b);

String _basename(String path) {
  final parts = path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}

bool _isWithin(String path, String root) {
  final base = _trimSeparators(root);
  if (_samePath(path, base)) return true;
  if (base.endsWith('/') || base.endsWith('\\')) return path.startsWith(base);
  return path.startsWith('$base/') || path.startsWith('$base\\');
}

/// The innermost library root that contains [path].
LibraryFolder? _rootFor(String path, List<LibraryFolder> roots) {
  LibraryFolder? best;
  for (final root in roots) {
    if (!_isWithin(path, root.path)) continue;
    if (best == null || _trimSeparators(root.path).length > _trimSeparators(best.path).length) best = root;
  }
  return best;
}

/// Root label first, then each folder below it down to [path].
List<_Crumb> _crumbs(String path, LibraryFolder? root) {
  if (root == null) return const [];
  final base = _trimSeparators(root.path);
  final rest = path.length > base.length ? path.substring(base.length) : '';
  final separator = rest.contains('\\') && !rest.contains('/') ? '\\' : '/';
  final crumbs = <_Crumb>[(label: root.label, path: base)];
  var current = base;
  for (final segment in rest.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty)) {
    current = current.endsWith(separator) ? '$current$segment' : '$current$separator$segment';
    crumbs.add((label: segment, path: current));
  }
  return crumbs;
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.crumbs, required this.rootGlyph, required this.onTap});

  final List<_Crumb> crumbs;
  final VwishGlyphKind rootGlyph;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    // Reversed so a long trail starts scrolled to the current folder; the min width keeps a short one start-aligned.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            children: [
              for (var i = 0; i < crumbs.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: VwishColors.textMuted),
                  ),
                if (i == crumbs.length - 1)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        crumbs[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VwishTextStyles.label,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: VwishButton.ghost(
                      label: crumbs[i].label,
                      glyph: i == 0 ? rootGlyph : null,
                      size: VwishButtonSize.sm,
                      onPressed: () => onTap(crumbs[i].path),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
