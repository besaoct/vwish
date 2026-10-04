import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_features/vwish_features.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import 'router/app_router.dart';

class VwishApp extends ConsumerStatefulWidget {
  const VwishApp({super.key});

  @override
  ConsumerState<VwishApp> createState() => _VwishAppState();
}

class _VwishAppState extends ConsumerState<VwishApp> {
  late final GoRouter _router = createAppRouter();
  StreamSubscription<String>? _mediaSub;
  String? _lastOpenedMedia;
  DateTime? _lastOpenedAt;

  @override
  void initState() {
    super.initState();
    _mediaSub = IncomingMediaBridge.onMediaOpened.listen(_handleIncomingMedia);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialMedia());
  }

  @override
  void dispose() {
    _mediaSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  Future<void> _checkInitialMedia() async {
    final media = await IncomingMediaBridge.getInitialMedia();
    if (media != null && mounted) {
      await _handleIncomingMedia(media);
    }
  }

  Future<void> _handleIncomingMedia(String raw) async {
    final now = DateTime.now();
    if (_lastOpenedMedia == raw &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOpenedMedia = raw;
    _lastOpenedAt = now;

    try {
      final mediaRef = await _resolveMedia(raw);
      if (mediaRef == null || !mounted) return;

      final queue = ref.read(queueControllerProvider.notifier);
      await queue.playFrom([mediaRef]);

      if (!mounted) return;
      final uri = _router.routerDelegate.currentConfiguration.uri.toString();
      if (uri != '/player') {
        _router.push('/player');
      }
    } catch (e) {
      debugPrint('[VwishApp] Failed to play incoming media: $e');
    }
  }

  Future<MediaRef?> _resolveMedia(String raw) async {
    var pathOrUrl = raw.trim();
    if (pathOrUrl.isEmpty) return null;

    // Custom scheme: vwish://
    if (pathOrUrl.startsWith('vwish://')) {
      final uri = Uri.tryParse(pathOrUrl);
      if (uri != null) {
        final queryUrl = uri.queryParameters['url'];
        if (queryUrl != null && queryUrl.isNotEmpty) {
          pathOrUrl = queryUrl;
        } else {
          final stripped = pathOrUrl.substring('vwish://'.length);
          if (stripped.startsWith('http://') ||
              stripped.startsWith('https://') ||
              stripped.startsWith('/')) {
            pathOrUrl = stripped;
          }
        }
      }
    }

    // file:// URI
    if (pathOrUrl.startsWith('file://')) {
      final fileUri = Uri.tryParse(pathOrUrl);
      if (fileUri != null) {
        pathOrUrl = fileUri.toFilePath();
      }
    }

    // Remote network URLs
    final parsedRemote = MediaUrl.tryParse(pathOrUrl);
    if (parsedRemote != null && parsedRemote.isRemote) {
      return parsedRemote;
    }

    // Local file path
    String localPath = pathOrUrl;
    if (PlatformBridge.isMobile) {
      try {
        final imported = await LibraryStorage().importPickedFiles([localPath]);
        if (imported.isNotEmpty) {
          localPath = imported.first;
        }
      } catch (e) {
        debugPrint('[VwishApp] LibraryStorage import error: $e');
      }
    }

    return LibraryRepository.mediaRefForFile(localPath);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vwish',
      debugShowCheckedModeBanner: false,
      theme: VwishTheme.darkTheme,
      routerConfig: _router,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.35,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
