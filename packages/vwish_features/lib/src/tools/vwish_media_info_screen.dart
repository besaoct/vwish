import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../controllers/providers.dart';
import '../library/library_format.dart';
import '../library/library_widgets.dart';
import 'media_tool_format.dart';
import 'media_tool_providers.dart';
import 'media_tool_widgets.dart';

export 'media_tool_providers.dart' show mediaInfoPickerProvider, mediaInspectorProvider;

/// Media info: pick a video, or use the one in the player, to see its format, codecs,
/// resolution, audio and subtitle tracks, with a summary to copy.
class VwishMediaInfoScreen extends ConsumerStatefulWidget {
  const VwishMediaInfoScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<VwishMediaInfoScreen> createState() => _VwishMediaInfoScreenState();
}

class _VwishMediaInfoScreenState extends ConsumerState<VwishMediaInfoScreen> {
  MediaFileInfo? _info;
  String? _error;
  String? _errorPath;

  /// The file being read, while it is.
  String? _loadingName;
  bool _picking = false;

  /// Bumped by every read so a slow, superseded one can't replace a newer result.
  int _token = 0;

  Future<void> _choose() async {
    if (_picking) return;
    _picking = true;
    try {
      final path = await ref.read(mediaInfoPickerProvider)();
      if (path != null && mounted) await _inspect(path);
    } catch (e) {
      debugPrint('[MediaInfo] picker failed: $e');
      if (mounted) {
        VwishToast.show(
          context,
          "Couldn't open the file picker. Please try again.",
          kind: VwishToastKind.error,
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      _picking = false;
    }
  }

  Future<void> _inspect(String path) async {
    final token = ++_token;
    setState(() {
      _loadingName = fileNameOf(path);
      _error = null;
    });
    try {
      final info = await ref.read(mediaInspectorProvider).inspect(path);
      if (!mounted || token != _token) return;
      setState(() {
        _info = info;
        _loadingName = null;
      });
    } catch (e) {
      if (!mounted || token != _token) return;
      if (e is! MediaInspectorException) debugPrint('[MediaInfo] $path: $e');
      setState(() {
        _info = null;
        _loadingName = null;
        _errorPath = path;
        _error = e is MediaInspectorException ? e.message : "Something went wrong while reading this file.";
      });
    }
  }

  Future<void> _copy(MediaFileInfo info) async {
    try {
      await Clipboard.setData(ClipboardData(text: mediaInfoSummary(info)));
      if (mounted) {
        VwishToast.show(context, 'Details copied', kind: VwishToastKind.success, icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      debugPrint('[MediaInfo] copy failed: $e');
      if (mounted) {
        VwishToast.show(
          context,
          "Couldn't copy the details.",
          kind: VwishToastKind.error,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(playerControllerProvider.select((s) => s.currentMediaRef));
    final info = _info;
    final loadingName = _loadingName;
    final error = _error;
    return MediaToolPage(
      title: 'Media info',
      onBack: widget.onBack,
      children: [
        _sources(current != null && !current.isRemote ? current : null, busy: loadingName != null),
        if (loadingName != null)
          _LoadingCard(fileName: loadingName)
        else if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: VwishSpacing.xl),
            child: VwishInlineEmpty(
              icon: Icons.error_outline_rounded,
              iconColor: VwishColors.errorLight,
              title: "Couldn't read this file",
              message: error,
              action: VwishButton.secondary(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                size: VwishButtonSize.sm,
                onPressed: () => _inspect(_errorPath!),
              ),
            ),
          )
        else if (info != null)
          ..._details(info)
        else
          const MediaToolFootnote(
            'Vwish reads the beginning of the file to show its format, codecs, resolution, '
            'audio and subtitle tracks. Nothing is changed or uploaded.',
          ),
      ],
    );
  }

  Widget _sources(MediaRef? current, {required bool busy}) {
    const chevron = Padding(
      padding: EdgeInsets.all(VwishSpacing.sm),
      child: Icon(Icons.chevron_right_rounded, size: 22, color: VwishColors.textMuted),
    );
    return VwishLibraryGroup(
      children: [
        VwishLibraryRow(
          leading: const VwishTileIcon(Icons.video_file_rounded, color: VwishColors.purple, size: 40),
          title: 'Choose a video',
          subtitle: _info == null ? 'Pick a file to inspect' : 'Inspect another file',
          onTap: busy ? null : _choose,
          trailing: chevron,
        ),
        if (current != null)
          VwishLibraryRow(
            leading: const VwishTileIcon(Icons.play_circle_rounded, size: 40),
            title: current.title,
            titleMaxLines: 2,
            subtitle: 'Now in the player',
            onTap: busy ? null : () => _inspect(current.pathOrUri),
            semanticLabel: 'Inspect the video in the player: ${current.title}',
            trailing: chevron,
          ),
      ],
    );
  }

  List<Widget> _details(MediaFileInfo info) {
    final videos = info.videoTracks;
    final audios = info.audioTracks;
    final subtitles = info.subtitleTracks;
    String heading(String label, int index, int count) => count > 1 ? '$label ${index + 1}' : label;
    final folder = info.path.length > info.fileName.length
        ? info.path.substring(0, info.path.length - info.fileName.length - 1)
        : null;
    final streaming = formatFastStart(info);

    return [
      const SizedBox(height: VwishSpacing.xl),
      _SummaryCard(info: info, onCopy: () => _copy(info)),
      if (info.warnings.isNotEmpty) ...[
        const SizedBox(height: VwishSpacing.md),
        _NotesCard(notes: info.warnings),
      ],
      const VwishLibrarySectionHeader('File'),
      MediaInfoGroup(
        rows: [
          MediaInfoRow('Name', info.fileName, valueMaxLines: 6),
          MediaInfoRow('Size', '${formatDataSize(info.sizeBytes)} (${formatThousands(info.sizeBytes)} bytes)'),
          if (info.modified != null) MediaInfoRow('Modified', formatDateTime(info.modified!)),
          // Picked files on phones are temporary copies whose folder means nothing to people.
          if (folder != null && folder.isNotEmpty && !context.isTouchPlatform) MediaInfoRow('Folder', folder),
        ],
      ),
      const VwishLibrarySectionHeader('Format'),
      MediaInfoGroup(
        rows: [
          MediaInfoRow('Container', formatContainer(info.container)),
          MediaInfoRow('Duration', info.duration == null ? 'Unknown' : formatClock(info.duration!)),
          if (info.overallBitrate != null) MediaInfoRow('Overall bitrate', formatBitRate(info.overallBitrate!)),
          if (streaming != null)
            MediaInfoRow(
              'Streaming',
              streaming,
              valueColor: info.fastStart == true ? VwishColors.success : VwishColors.warning,
            ),
          if (info.container.hasTrackDetails)
            MediaInfoRow(
              'Tracks',
              [
                formatCount(videos.length, 'video'),
                '${audios.length} audio',
                formatCount(subtitles.length, 'subtitle'),
              ].join(' · '),
            ),
          if (info.title != null) MediaInfoRow('Title', info.title!),
          if (info.encoder != null) MediaInfoRow('Written by', info.encoder!),
        ],
      ),
      for (var i = 0; i < videos.length; i++) ...[
        VwishLibrarySectionHeader(heading('Video', i, videos.length)),
        MediaInfoGroup(rows: _videoRows(videos[i])),
      ],
      for (var i = 0; i < audios.length; i++) ...[
        VwishLibrarySectionHeader(heading('Audio', i, audios.length)),
        MediaInfoGroup(rows: _audioRows(audios[i])),
      ],
      if (subtitles.isNotEmpty) ...[
        const VwishLibrarySectionHeader('Subtitles'),
        VwishLibraryGroup(children: [for (final track in subtitles) _subtitleRow(track)]),
      ],
    ];
  }

  List<Widget> _videoRows(MediaTrackInfo t) => [
        MediaInfoRow('Codec', t.codec),
        if (t.profile != null) MediaInfoRow('Profile', t.profile!),
        if (t.width != null && t.height != null) MediaInfoRow('Resolution', formatResolution(t.width!, t.height!)),
        if (t.frameRate != null) MediaInfoRow('Frame rate', formatFrameRate(t.frameRate!)),
        if (t.bitDepth != null) MediaInfoRow('Bit depth', '${t.bitDepth}-bit'),
        if (t.hdr != null) MediaInfoRow('HDR', t.hdr!),
        if (t.rotation != 0) MediaInfoRow('Rotation', '${formatRotation(t.rotation)} clockwise'),
        if (t.bitrate != null) MediaInfoRow('Bitrate', formatBitRate(t.bitrate!)),
        ..._commonRows(t),
      ];

  List<Widget> _audioRows(MediaTrackInfo t) => [
        MediaInfoRow('Codec', t.codec),
        if (t.profile != null) MediaInfoRow('Profile', t.profile!),
        if (t.channels != null) MediaInfoRow('Channels', formatChannels(t.channels!)),
        if (t.sampleRate != null) MediaInfoRow('Sample rate', formatSampleRate(t.sampleRate!)),
        if (t.bitDepth != null) MediaInfoRow('Bit depth', '${t.bitDepth}-bit'),
        if (t.bitrate != null) MediaInfoRow('Bitrate', formatBitRate(t.bitrate!)),
        ..._commonRows(t),
      ];

  List<Widget> _commonRows(MediaTrackInfo t) => [
        if (t.language != null) MediaInfoRow('Language', formatLanguage(t.language!)),
        if (t.name != null) MediaInfoRow('Name', t.name!),
        if (t.encrypted) const MediaInfoRow('Protection', 'Encrypted (DRM)', valueColor: VwishColors.warning),
      ];

  Widget _subtitleRow(MediaTrackInfo t) {
    final details = [
      t.codec,
      if (t.name != null) t.name!,
      if (t.isForced) 'Forced',
      if (t.encrypted) 'Encrypted',
    ];
    return VwishLibraryRow(
      leading: const VwishTileIcon(Icons.subtitles_rounded, color: VwishColors.cyan, size: 40),
      title: t.language == null ? 'Unknown language' : formatLanguage(t.language!),
      titleMaxLines: 2,
      subtitle: details.join(' · '),
      subtitleMaxLines: 3,
      badge: t.isDefault ? 'Default' : null,
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: VwishSpacing.xl),
      child: VwishSurface(
        color: VwishColors.surface,
        padding: const EdgeInsets.all(VwishSpacing.lg),
        child: Row(
          children: [
            const VwishSpinner(size: 24),
            const SizedBox(width: VwishSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reading the file…', style: VwishTextStyles.headline),
                  const SizedBox(height: 2),
                  Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis, style: VwishTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The file at a glance: its name, format, size and length, quality badges and Copy.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.info, required this.onCopy});

  final MediaFileInfo info;
  final VoidCallback onCopy;

  List<Widget> _badges() {
    final video = info.videoTracks.firstOrNull;
    final audioChannels = info.audioTracks.map((t) => t.channels ?? 0).fold(0, (a, b) => a > b ? a : b);
    final resolution =
        video?.width != null && video?.height != null ? resolutionName(video!.width!, video.height!) : null;
    final surround = surroundName(audioChannels);
    return [
      if (resolution != null) VwishBadge(resolution),
      if (video?.hdr != null) VwishBadge(video!.hdr!, color: VwishColors.warning),
      if ((video?.bitDepth ?? 0) > 8) VwishBadge('${video!.bitDepth}-bit', color: VwishColors.cyan),
      if (surround != null) VwishBadge(surround, color: VwishColors.purple),
      if (info.fastStart == true) const VwishBadge('Fast start', color: VwishColors.success),
      if (info.tracks.any((t) => t.encrypted)) const VwishBadge('Encrypted', color: VwishColors.errorLight),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final facts = [
      if (info.container.shortName.isNotEmpty) info.container.shortName,
      formatDataSize(info.sizeBytes),
      if (info.duration != null) formatClock(info.duration!),
    ];
    final badges = _badges();
    return VwishSurface(
      shadow: VwishShadow.subtle,
      padding: const EdgeInsets.all(VwishSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VwishTileIcon(Icons.movie_rounded, color: VwishColors.purple, size: 44),
              const SizedBox(width: VwishSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title ?? info.fileName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: VwishTextStyles.headline.copyWith(fontSize: 16, height: 1.3),
                    ),
                    if (info.title != null) ...[
                      const SizedBox(height: 2),
                      Text(info.fileName, maxLines: 2, overflow: TextOverflow.ellipsis, style: VwishTextStyles.caption),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      facts.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VwishTextStyles.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: VwishSpacing.md),
            Wrap(spacing: 6, runSpacing: 6, children: badges),
          ],
          const SizedBox(height: VwishSpacing.md),
          VwishButton.secondary(
            label: 'Copy details',
            icon: Icons.copy_rounded,
            size: VwishButtonSize.sm,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return VwishSurface(
      color: VwishColors.surface,
      padding: const EdgeInsets.all(VwishSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < notes.length; i++) ...[
            if (i > 0) const SizedBox(height: VwishSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline_rounded, size: 18, color: VwishColors.warning),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(notes[i], style: VwishTextStyles.bodySecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
