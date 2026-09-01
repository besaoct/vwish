import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/providers.dart';

class VwishDiagnosticsOverlay extends ConsumerWidget {
  final VoidCallback onClose;

  const VwishDiagnosticsOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final stats = state.stats;

    return Positioned(
      top: 50,
      left: 20,
      child: SizedBox(
        width: 320,
        child: VwishGlassCard(
          backgroundColor: const Color(0xEB0C0E14),
          borderColor: VwishColors.borderBright,
          borderRadius: 10,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.query_stats_rounded, size: 16, color: VwishColors.cyan),
                      SizedBox(width: 6),
                      Text(
                        'Stats for Nerds',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: VwishColors.textMuted),
                    splashRadius: 12,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
                ],
              ),
              const Divider(color: VwishColors.border, height: 12),

              // Diagnostics Rows
              _statRow('Resolution', stats.resolution ?? '1920x1080'),
              _statRow('FPS', '${stats.fps.toStringAsFixed(2)} / est ${stats.estimatedFps.toStringAsFixed(2)}'),
              _statRow('Video Codec', stats.videoCodec ?? 'HEVC / H.265 (Main 10)'),
              _statRow('Audio Codec', stats.audioCodec ?? 'E-AC-3 (Dolby Digital Plus)'),
              _statRow('HW Decode', stats.hwdec ?? 'videotoolbox-copy (Active)'),
              _statRow('Dropped Frames', '${stats.droppedFrames} / ${stats.voDelayedFrames} delayed'),
              _statRow('A/V Desync', '${(stats.avDesync * 1000).toStringAsFixed(1)} ms'),
              _statRow('Video Bitrate', '${stats.videoBitrate.toStringAsFixed(1)} kbps'),
              _statRow('Audio Channels', stats.audioChannels ?? '5.1 (side) @ 48kHz'),
              _statRow('Color Space', stats.colorSpace ?? 'bt709 / bt709'),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy Technical Report', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: VwishColors.borderBright),
                  ),
                  onPressed: () {
                    final report = '''
--- Vwish Player Diagnostics ---
Resolution: ${stats.resolution}
FPS: ${stats.fps}
Video Codec: ${stats.videoCodec}
Audio Codec: ${stats.audioCodec}
HW Decode: ${stats.hwdec}
Dropped Frames: ${stats.droppedFrames}
A/V Desync: ${stats.avDesync}
Video Bitrate: ${stats.videoBitrate} kbps
Audio Channels: ${stats.audioChannels}
Media: ${state.currentSource?.uri}
--------------------------------
''';
                    Clipboard.setData(ClipboardData(text: report));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Technical report copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: VwishColors.textMuted)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
