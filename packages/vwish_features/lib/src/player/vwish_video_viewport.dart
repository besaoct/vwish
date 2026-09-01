import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/providers.dart';

class VwishVideoViewport extends ConsumerWidget {
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;

  const VwishVideoViewport({
    super.key,
    this.onDoubleTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(playbackEngineProvider);
    final state = ref.watch(playerControllerProvider);

    final videoCtrl = engine.videoController;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black,
        child: Center(
          child: videoCtrl is mkv.VideoController
              ? mkv.Video(
                  controller: videoCtrl,
                  controls: mkv.NoVideoControls,
                  fit: _getBoxFit(state.transform.aspectOverride),
                )
              : _buildFallback(state),
        ),
      ),
    );
  }

  BoxFit _getBoxFit(String? aspect) {
    if (aspect == 'fill') return BoxFit.fill;
    if (aspect == 'cover') return BoxFit.cover;
    return BoxFit.contain;
  }

  Widget _buildFallback(PlayerState state) {
    if (state.currentSource == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VwishColors.surfaceElevated.withValues(alpha: 0.8),
                border: Border.all(color: VwishColors.border, width: 1.5),
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                size: 48,
                color: VwishColors.primaryLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Media Loaded',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Drag & drop video files or folders here, or press "O" to open',
              style: TextStyle(
                fontSize: 13,
                color: VwishColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(
        color: VwishColors.primary,
        strokeWidth: 3,
      ),
    );
  }
}
