import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import '../controllers/providers.dart';
import '../library/library_widgets.dart';
import 'media_tool_format.dart' show formatDataSize;
import 'media_tool_widgets.dart';
import 'network_format.dart';
import 'network_tool_providers.dart';

export 'network_tool_providers.dart' show streamProbeProvider;

/// Checks a video or stream link before playing it: whether it answers, what it is, whether it can
/// seek, its quality levels, and what would stop it from playing.
class VwishStreamCheckScreen extends ConsumerStatefulWidget {
  const VwishStreamCheckScreen({super.key, required this.onBack, required this.onOpenPlayer});

  final VoidCallback onBack;
  final VoidCallback onOpenPlayer;

  @override
  ConsumerState<VwishStreamCheckScreen> createState() => _VwishStreamCheckScreenState();
}

class _VwishStreamCheckScreenState extends ConsumerState<VwishStreamCheckScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String? _inputError;
  bool _attempted = false;
  bool _checking = false;
  NetworkCancelToken? _cancel;

  /// The link the shown result (or notice) is about.
  MediaRef? _checked;
  StreamProbeResult? _result;

  /// Why a valid link couldn't be checked (not http, or a local file).
  String? _unsupported;
  String? _failure;

  @override
  void dispose() {
    _cancel?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    if (!_attempted) return;
    setState(() => _inputError = MediaUrl.validationError(_controller.text));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      VwishToast.show(context, 'Nothing to paste. Copy a link first.', icon: Icons.content_paste_off_rounded);
      return;
    }
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _onChanged(text);
  }

  Future<void> _check() async {
    if (_checking) return;
    final error = MediaUrl.validationError(_controller.text);
    final media = error == null ? MediaUrl.tryParse(_controller.text) : null;
    if (media == null) {
      setState(() {
        _attempted = true;
        _inputError = error ?? 'Enter a valid link.';
        // The previous link's result would read as the answer for what was just typed.
        _checked = null;
        _result = null;
        _failure = null;
        _unsupported = null;
      });
      return;
    }
    _focusNode.unfocus();
    final uri = Uri.parse(media.pathOrUri);
    final scheme = uri.scheme.toLowerCase();
    setState(() {
      _attempted = false;
      _inputError = null;
      _checked = media;
      _result = null;
      _failure = null;
      _unsupported = !media.isRemote
          ? "Links to files on this device can't be checked here, but Vwish can play them."
          : scheme != 'http' && scheme != 'https'
              ? "${scheme.toUpperCase()} links can't be checked here, but Vwish can still try to play them."
              : null;
    });
    if (_unsupported != null) return;

    final token = _cancel = NetworkCancelToken();
    setState(() => _checking = true);
    try {
      final result = await ref.read(streamProbeProvider).check(uri, cancel: token);
      if (!mounted || token.isCancelled) return;
      setState(() => _result = result);
    } on StreamProbeException catch (e) {
      if (!mounted || token.isCancelled) return;
      setState(() => _failure = e.message);
    } catch (e) {
      debugPrint('[StreamCheck] $e');
      if (!mounted || token.isCancelled) return;
      setState(() => _failure = "Couldn't check this link. Try again.");
    } finally {
      if (mounted && identical(_cancel, token)) setState(() => _checking = false);
    }
  }

  void _cancelCheck() {
    _cancel?.cancel();
    setState(() {
      _checking = false;
      _checked = null;
    });
  }

  void _play() {
    final media = _checked;
    if (media == null) return;
    ref.read(queueControllerProvider.notifier).playFrom([media]).catchError((Object e) {
      debugPrint('[StreamCheck] playFrom failed: $e');
    });
    widget.onOpenPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VwishColors.background,
      body: VwishLibraryFrame(
        topBar: VwishLibraryTopBar(
          title: 'Stream check',
          subtitle: 'Will this link play?',
          onBack: widget.onBack,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final insets = vwishLibraryInsets(constraints.maxWidth);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: insets.copyWith(
                top: VwishSpacing.lg,
                bottom: MediaQuery.paddingOf(context).bottom + VwishSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _form(),
                  const SizedBox(height: VwishSpacing.xl),
                  ..._outcome(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Paste the address of a video or live stream to see whether it will play, and why not if it '
            "won't.",
            style: VwishTextStyles.bodySecondary,
          ),
        ),
        const SizedBox(height: VwishSpacing.md),
        VwishTextField(
          controller: _controller,
          focusNode: _focusNode,
          hint: 'https://example.com/video.m3u8',
          prefixIcon: Icons.link_rounded,
          errorText: _inputError,
          enabled: !_checking,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onChanged: _onChanged,
          onSubmitted: (_) => _check(),
          semanticLabel: 'Link to check',
        ),
        const SizedBox(height: VwishSpacing.md),
        VwishButtonBar(
          children: [
            VwishButton.secondary(
              label: 'Paste',
              icon: Icons.content_paste_rounded,
              onPressed: _checking ? null : _paste,
            ),
            VwishButton.primary(
              label: _checking ? 'Checking…' : 'Check link',
              icon: Icons.fact_check_rounded,
              onPressed: _checking ? null : _check,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _outcome() {
    final media = _checked;
    if (_checking && media != null) return [_CheckingCard(host: _hostOf(media), onCancel: _cancelCheck)];
    if (_unsupported != null) {
      return [
        VwishInlineEmpty(
          icon: Icons.podcasts_rounded,
          iconColor: VwishColors.cyan,
          title: "This kind of link can't be checked",
          message: _unsupported,
          action: VwishButton.tonal(
            label: 'Play in Vwish',
            icon: Icons.play_arrow_rounded,
            size: VwishButtonSize.sm,
            onPressed: _play,
          ),
        ),
      ];
    }
    if (_failure != null) {
      return [
        VwishInlineEmpty(
          icon: Icons.error_outline_rounded,
          iconColor: VwishColors.errorLight,
          title: "Couldn't check this link",
          message: _failure,
          action: VwishButton.secondary(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            size: VwishButtonSize.sm,
            onPressed: _check,
          ),
        ),
      ];
    }
    final result = _result;
    if (result == null || media == null) {
      return const [
        VwishInlineEmpty(
          icon: Icons.fact_check_rounded,
          iconColor: VwishColors.cyan,
          title: 'Check before you play',
          message: 'Works with direct video and audio files, HLS (.m3u8) and DASH (.mpd) links. '
              'Only a small part of the file is downloaded.',
        ),
      ];
    }
    return _resultSections(result, media);
  }

  List<Widget> _resultSections(StreamProbeResult result, MediaRef media) {
    final manifest = result.manifest;
    final variants = [...?manifest?.variants]..sort((a, b) => (b.bandwidth ?? 0).compareTo(a.bandwidth ?? 0));
    return [
      _SummaryCard(result: result, title: _resultTitle(result, media), onPlay: _play),
      if (result.issues.isNotEmpty) ...[
        const VwishLibrarySectionHeader('What we found', topSpacing: 24),
        VwishLibraryGroup(
          dividers: false,
          children: [for (final issue in _sortedIssues(result.issues)) _IssueRow(issue: issue)],
        ),
      ],
      const VwishLibrarySectionHeader('Details', topSpacing: 24),
      MediaInfoGroup(rows: [for (final (label, value) in _details(result)) MediaInfoRow(label, value)]),
      if (variants.isNotEmpty) ...[
        VwishLibrarySectionHeader('Quality levels (${variants.length})', topSpacing: 24),
        VwishLibraryGroup(children: [for (final variant in variants) _variantRow(variant)]),
      ],
      if (result.redirects.isNotEmpty) ...[
        VwishLibrarySectionHeader(
          result.redirects.length == 1 ? 'Redirect' : 'Redirects (${result.redirects.length})',
          topSpacing: 24,
        ),
        VwishLibraryGroup(children: [for (final redirect in result.redirects) _redirectRow(redirect)]),
      ],
    ];
  }

  /// The file name, or the host for a page or a link without one (`watch` says nothing).
  static String _resultTitle(StreamProbeResult result, MediaRef media) {
    final url = result.requestedUrl;
    final last = url.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    final named = last != null && RegExp(r'\.[A-Za-z0-9]{2,5}$').hasMatch(last);
    if ((result.kind == StreamKind.webPage || !named) && url.host.isNotEmpty) return url.host;
    return media.title;
  }

  static List<StreamIssue> _sortedIssues(List<StreamIssue> issues) =>
      [...issues]..sort((a, b) => a.level.index.compareTo(b.level.index));

  static List<(String, String)> _details(StreamProbeResult result) {
    final manifest = result.manifest;
    final ttfb = result.timeToFirstByte;
    final status = result.statusCode;
    final answered = status != null && status >= 200 && status < 300;
    return [
      ('Status', status == null ? 'No response' : '$status ${result.reasonPhrase ?? ''}'.trim()),
      ('Format', _formatLabel(result)),
      if (manifest != null) ('Stream', _streamLabel(manifest)),
      if (manifest != null && manifest.isMaster && (manifest.audioTracks > 0 || manifest.subtitleTracks > 0))
        ('Tracks', _tracksLabel(manifest)),
      if (manifest?.encryption != null) ('Encryption', manifest!.drm ? '${manifest.encryption} (DRM)' : manifest.encryption!),
      if (status != null) ('Content type', result.contentType ?? 'Not sent'),
      if (result.contentLength != null) ('Size', formatDataSize(result.contentLength!)),
      // Seeking means nothing for a web page or a server that answered with an error.
      if (answered && result.kind != StreamKind.webPage) ('Seeking', _seekLabel(result)),
      if (ttfb != null) ('Response time', _responseTime(ttfb)),
      if (result.server != null) ('Server', result.server!),
      ('Address', _readableUrl(result.finalUrl)),
    ];
  }

  static String _responseTime(Duration ttfb) => ttfb.inMilliseconds < 1000
      ? '${ttfb.inMilliseconds}\u00A0ms'
      : '${(ttfb.inMilliseconds / 1000).toStringAsFixed(1)}\u00A0s';

  static String _streamLabel(StreamManifestInfo manifest) {
    final duration = manifest.duration;
    return switch (manifest.isLive) {
      true => 'Live',
      false when duration != null && duration > Duration.zero => 'On demand · ${formatStreamDuration(duration)}',
      false => 'On demand',
      null when duration != null && duration > Duration.zero => 'At least ${formatStreamDuration(duration)}',
      null => 'Unknown',
    };
  }

  static String _tracksLabel(StreamManifestInfo manifest) {
    String count(int n, String noun) => n == 1 ? '1 $noun' : '$n ${noun}s';
    return [
      if (manifest.audioTracks > 0) count(manifest.audioTracks, 'audio track'),
      if (manifest.subtitleTracks > 0) count(manifest.subtitleTracks, 'subtitle track'),
    ].join(' · ');
  }

  static String _seekLabel(StreamProbeResult result) {
    if (result.kind == StreamKind.hls || result.kind == StreamKind.dash) {
      return result.manifest?.isLive == true ? 'Within the live window' : 'Supported';
    }
    return switch (result.seekable) {
      true => 'Supported',
      false => 'Not supported',
      null => result.acceptsRanges == true ? 'Advertised, not confirmed' : 'Unknown',
    };
  }

  Widget _variantRow(StreamVariant variant) {
    final height = variant.height;
    final title = height == null
        ? 'Audio only'
        : '${height}p${variant.width == null ? '' : ' · ${variant.width}×$height'}';
    final details = [
      if (variant.bandwidth != null) formatBitrate(variant.bandwidth!),
      if (variant.frameRate != null) '${_fps(variant.frameRate!)} fps',
      if (variant.codecs != null) variant.codecs!.replaceAll(',', ', '),
    ];
    return VwishLibraryRow(
      leading: VwishTileIcon(
        height != null && height >= 2160
            ? Icons.four_k_rounded
            : height != null && height >= 720
                ? Icons.hd_rounded
                : height == null
                    ? Icons.audiotrack_rounded
                    : Icons.sd_rounded,
        color: VwishColors.cyan,
        size: 40,
      ),
      title: title,
      subtitle: details.isEmpty ? null : details.join(' · '),
      subtitleMaxLines: 2,
    );
  }

  static String _fps(double fps) => fps == fps.roundToDouble() ? fps.toStringAsFixed(0) : fps.toStringAsFixed(2);

  Widget _redirectRow(StreamRedirect redirect) {
    return VwishLibraryRow(
      leading: const VwishTileIcon(Icons.route_rounded, color: VwishColors.purple, size: 40),
      title: '${redirect.statusCode} ${_redirectName(redirect.statusCode)}',
      subtitle: _readableUrl(redirect.to),
      subtitleMaxLines: 3,
    );
  }

  static String _redirectName(int status) => switch (status) {
        301 => 'Moved permanently',
        302 => 'Found',
        303 => 'See other',
        307 => 'Temporary redirect',
        308 => 'Permanent redirect',
        _ => 'Redirect',
      };
}

/// The address with `%20` and friends decoded, as people type it.
String _readableUrl(Uri url) {
  final text = url.toString();
  try {
    return Uri.decodeFull(text);
  } on ArgumentError {
    return text;
  } on FormatException {
    // Percent-encoded bytes that aren't UTF-8.
    return text;
  }
}

String? _hostOf(MediaRef media) {
  final host = Uri.tryParse(media.pathOrUri)?.host ?? '';
  return host.isEmpty ? null : host;
}

/// `HLS master playlist`, `MP4 video`, `Web page`, …
String _formatLabel(StreamProbeResult result) {
  final container = result.container;
  return switch (result.kind) {
    StreamKind.hls => result.manifest?.isMaster == true ? 'HLS master playlist' : 'HLS playlist',
    StreamKind.dash => 'DASH manifest',
    StreamKind.video => container == null ? 'Video file' : '$container video',
    StreamKind.audio => container == null ? 'Audio file' : 'Audio ($container)',
    StreamKind.webPage => 'Web page',
    StreamKind.unknown => result.statusCode == null ? 'Unknown (no response)' : 'Unknown',
  };
}

typedef _VerdictStyle = ({String label, String message, IconData icon, Color color});

_VerdictStyle _verdictStyle(StreamVerdict verdict) => switch (verdict) {
      StreamVerdict.playable => (
          label: 'Playable',
          message: 'This link should play in Vwish.',
          icon: Icons.check_circle_rounded,
          color: VwishColors.success,
        ),
      StreamVerdict.mightNotPlay => (
          label: 'Might not play',
          message: 'It may play, but check the warnings below.',
          icon: Icons.warning_rounded,
          color: VwishColors.warning,
        ),
      StreamVerdict.notPlayable => (
          label: 'Not playable',
          message: "This link won't play as it is. See what we found below.",
          icon: Icons.error_rounded,
          color: VwishColors.errorLight,
        ),
    };

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.title, required this.onPlay});

  final StreamProbeResult result;
  final String title;
  final VoidCallback onPlay;

  String get _summary {
    final manifest = result.manifest;
    final parts = <String>[_formatLabel(result)];
    if (manifest != null) {
      if (manifest.isLive == true) parts.add('Live');
      if (manifest.isLive == false && manifest.duration != null && manifest.duration! > Duration.zero) {
        parts.add(formatStreamDuration(manifest.duration!));
      }
      final heights = manifest.variants.map((v) => v.height).whereType<int>();
      if (manifest.variants.isNotEmpty) {
        parts.add(manifest.variants.length == 1 ? '1 quality level' : '${manifest.variants.length} quality levels');
      }
      if (heights.isNotEmpty) parts.add('up to ${heights.reduce((a, b) => a > b ? a : b)}p');
    } else if (result.kind == StreamKind.video || result.kind == StreamKind.audio) {
      if (result.contentLength != null) parts.add(formatDataSize(result.contentLength!));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final verdict = result.verdict;
    final style = _verdictStyle(verdict);
    return VwishSurface(
      color: VwishColors.surface,
      shadow: VwishShadow.subtle,
      padding: const EdgeInsets.all(VwishSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VwishTileIcon(style.icon, color: style.color, size: 44),
              const SizedBox(width: VwishSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Verdict: ${style.label}',
                      excludeSemantics: true,
                      child: VwishBadge(style.label, color: style.color),
                    ),
                    const SizedBox(height: 6),
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: VwishTextStyles.headline),
                    const SizedBox(height: 2),
                    Text(_summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: VwishTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VwishSpacing.md),
          Text(style.message, style: VwishTextStyles.bodySecondary),
          if (verdict != StreamVerdict.notPlayable) ...[
            const SizedBox(height: VwishSpacing.lg),
            // Full width on phones; a capped, start-aligned button on wide layouts.
            LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth < 400 ? double.infinity : 320),
                  child: verdict == StreamVerdict.playable
                      ? VwishButton.primary(
                          label: 'Play in Vwish',
                          icon: Icons.play_arrow_rounded,
                          expand: true,
                          onPressed: onPlay,
                        )
                      : VwishButton.secondary(
                          label: 'Play anyway',
                          icon: Icons.play_arrow_rounded,
                          expand: true,
                          onPressed: onPlay,
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckingCard extends StatelessWidget {
  const _CheckingCard({required this.host, required this.onCancel});

  final String? host;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return VwishSurface(
      color: VwishColors.surface,
      padding: const EdgeInsetsDirectional.fromSTEB(VwishSpacing.lg, VwishSpacing.md, VwishSpacing.sm, VwishSpacing.md),
      child: Row(
        children: [
          const VwishSpinner(size: 22, semanticLabel: 'Checking link'),
          const SizedBox(width: VwishSpacing.md),
          // The host on a line of its own: a domain has nowhere to wrap and would break mid-word.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contacting the server…',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: VwishTextStyles.body,
                ),
                if (host != null)
                  Text(
                    host!,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: VwishTextStyles.caption,
                  ),
              ],
            ),
          ),
          const SizedBox(width: VwishSpacing.sm),
          VwishButton.ghost(label: 'Cancel', size: VwishButtonSize.sm, onPressed: onCancel),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue});

  final StreamIssue issue;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (issue.level) {
      StreamIssueLevel.error => (Icons.error_rounded, VwishColors.errorLight, 'Problem'),
      StreamIssueLevel.warning => (Icons.warning_rounded, VwishColors.warning, 'Warning'),
      StreamIssueLevel.info => (Icons.info_rounded, VwishColors.primaryLight, 'Note'),
    };
    return Semantics(
      label: '$label: ${issue.message}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Text(issue.message, style: VwishTextStyles.body)),
          ],
        ),
      ),
    );
  }
}
