import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/player_controller.dart';
import '../controllers/providers.dart';

enum TimeDisplayMode {
  currentAndTotal,
  remaining,
}

class VwishControlsOverlay extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenQueue;
  final VoidCallback onToggleDiagnostics;

  const VwishControlsOverlay({
    super.key,
    required this.onOpenSettings,
    required this.onOpenQueue,
    required this.onToggleDiagnostics,
  });

  @override
  ConsumerState<VwishControlsOverlay> createState() => _VwishControlsOverlayState();
}

class _VwishControlsOverlayState extends ConsumerState<VwishControlsOverlay> {
  bool _isVisible = true;
  Timer? _hideTimer;
  TimeDisplayMode _timeMode = TimeDisplayMode.currentAndTotal;
  String? _toastMessage;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      final state = ref.read(playerControllerProvider);
      if (mounted && state.isPlaying) {
        setState(() => _isVisible = false);
      }
    });
  }

  void _onUserActivity() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
    }
    _startHideTimer();
  }

  void showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    final queue = ref.watch(queueControllerProvider);
    final playerCtrl = ref.read(playerControllerProvider.notifier);
    final queueCtrl = ref.read(queueControllerProvider.notifier);

    return MouseRegion(
      onHover: (_) => _onUserActivity(),
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Stack(
          children: [
            // Top Bar Gradient & Info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC07080C), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    if (state.currentMediaRef != null) ...[
                      Expanded(
                        child: Text(
                          state.currentMediaRef!.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, size: 20, color: VwishColors.textSecondary),
                      splashRadius: 18,
                      onPressed: widget.onToggleDiagnostics,
                      tooltip: 'Stats for Nerds (I)',
                    ),
                    IconButton(
                      icon: Icon(
                        state.isAlwaysOnTop ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 20,
                        color: state.isAlwaysOnTop ? VwishColors.primary : VwishColors.textSecondary,
                      ),
                      splashRadius: 18,
                      onPressed: () => playerCtrl.toggleAlwaysOnTop(),
                      tooltip: 'Always on Top (T)',
                    ),
                  ],
                ),
              ),
            ),

            // Toast HUD
            if (_toastMessage != null)
              Positioned(
                top: 60,
                right: 20,
                child: VwishGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: VwishColors.surfaceElevatedHigher.withValues(alpha: 0.9),
                  child: Text(
                    _toastMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VwishColors.cyan,
                    ),
                  ),
                ),
              ),

            // Center Play/Pause / Buffering Indicator
            if (state.isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: VwishColors.primary,
                  strokeWidth: 3.5,
                ),
              )
            else if (!state.isPlaying && state.currentSource != null)
              Center(
                child: GestureDetector(
                  onTap: () => playerCtrl.play(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VwishColors.primary.withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: VwishColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Bottom Primary Control Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF007080C), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seek Bar
                    VwishSeekBar(
                      position: state.position,
                      duration: state.duration,
                      buffer: state.cacheEnd,
                      chapters: state.chapters,
                      abLoop: state.abLoop,
                      onSeek: (pos) => playerCtrl.seek(pos),
                    ),
                    const SizedBox(height: 4),

                    // Controls Row
                    Row(
                      children: [
                        // Play/Pause
                        IconButton(
                          icon: Icon(
                            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 26,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                          onPressed: () => playerCtrl.togglePlay(),
                          tooltip: state.isPlaying ? 'Pause (Space)' : 'Play (Space)',
                        ),

                        // Previous
                        if (queue.hasPrevious || state.position.inSeconds > 5)
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, size: 22, color: Colors.white),
                            splashRadius: 18,
                            onPressed: () => queueCtrl.previous(),
                            tooltip: 'Previous track',
                          ),

                        // Next
                        if (queue.hasNext)
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 22, color: Colors.white),
                            splashRadius: 18,
                            onPressed: () => queueCtrl.next(),
                            tooltip: 'Next track',
                          ),

                        // Volume Slider with Boost
                        VwishVolumeSlider(
                          volume: state.volume,
                          muted: state.muted,
                          onVolumeChanged: (v) => playerCtrl.setVolume(v),
                          onToggleMute: () => playerCtrl.toggleMute(),
                        ),

                        const SizedBox(width: 12),

                        // Time Display (toggleable)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _timeMode = _timeMode == TimeDisplayMode.currentAndTotal
                                  ? TimeDisplayMode.remaining
                                  : TimeDisplayMode.currentAndTotal;
                            });
                          },
                          child: Text(
                            _formatTime(state.position, state.duration, _timeMode),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: VwishColors.textSecondary,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Subtitle Track Button
                        _buildSubtitleTrackButton(state, playerCtrl),

                        // Audio Track Button
                        _buildAudioTrackButton(state, playerCtrl),

                        // Speed Selector
                        _buildSpeedSelector(state, playerCtrl),

                        // Queue Sheet Button
                        IconButton(
                          icon: const Icon(Icons.playlist_play_rounded, size: 22, color: VwishColors.textPrimary),
                          splashRadius: 18,
                          onPressed: widget.onOpenQueue,
                          tooltip: 'Queue / Playlist (P)',
                        ),

                        // Settings Button
                        IconButton(
                          icon: const Icon(Icons.settings_rounded, size: 20, color: VwishColors.textPrimary),
                          splashRadius: 18,
                          onPressed: widget.onOpenSettings,
                          tooltip: 'Settings (Ctrl+,)',
                        ),

                        // Fullscreen Toggle
                        IconButton(
                          icon: Icon(
                            state.viewMode == ViewMode.fullscreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            size: 22,
                            color: VwishColors.textPrimary,
                          ),
                          splashRadius: 18,
                          onPressed: () => playerCtrl.toggleFullscreen(),
                          tooltip: 'Fullscreen (F)',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleTrackButton(PlayerState state, PlayerController playerCtrl) {
    final isSelected = state.tracks.selectedSubtitleTrackId != null &&
        state.tracks.selectedSubtitleTrackId != 'no';

    return PopupMenuButton<String>(
      tooltip: 'Subtitles (C)',
      icon: Icon(
        Icons.subtitles_rounded,
        size: 20,
        color: isSelected ? VwishColors.primaryLight : VwishColors.textMuted,
      ),
      color: VwishColors.surfaceElevatedHigher,
      onSelected: (id) => playerCtrl.setSubtitleTrack(id),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem(
            value: 'no',
            child: Text('Subtitles Off', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const PopupMenuDivider(),
        ];
        for (final track in state.tracks.subtitleTracks) {
          items.add(PopupMenuItem(
            value: track.id,
            child: Row(
              children: [
                if (track.id == state.tracks.selectedSubtitleTrackId)
                  const Icon(Icons.check_rounded, size: 16, color: VwishColors.cyan)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    track.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ));
        }
        return items;
      },
    );
  }

  Widget _buildAudioTrackButton(PlayerState state, PlayerController playerCtrl) {
    if (state.tracks.audioTracks.length <= 1) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Audio Tracks (#)',
      icon: const Icon(
        Icons.audiotrack_rounded,
        size: 20,
        color: VwishColors.textSecondary,
      ),
      color: VwishColors.surfaceElevatedHigher,
      onSelected: (id) => playerCtrl.setAudioTrack(id),
      itemBuilder: (context) {
        return state.tracks.audioTracks.map((track) {
          return PopupMenuItem(
            value: track.id,
            child: Row(
              children: [
                if (track.id == state.tracks.selectedAudioTrackId)
                  const Icon(Icons.check_rounded, size: 16, color: VwishColors.cyan)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    track.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildSpeedSelector(PlayerState state, PlayerController playerCtrl) {
    return PopupMenuButton<double>(
      tooltip: 'Playback Speed ([/])',
      color: VwishColors.surfaceElevatedHigher,
      onSelected: (speed) => playerCtrl.setSpeed(speed),
      itemBuilder: (context) {
        const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0];
        return speeds.map((s) {
          return PopupMenuItem(
            value: s,
            child: Row(
              children: [
                if ((state.speed - s).abs() < 0.01)
                  const Icon(Icons.check_rounded, size: 16, color: VwishColors.cyan)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text('${s}x', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          '${state.speed}x',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: VwishColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration pos, Duration dur, TimeDisplayMode mode) {
    if (mode == TimeDisplayMode.remaining && dur > Duration.zero) {
      final rem = dur - pos;
      return '-${_formatDur(rem)}';
    }
    return '${_formatDur(pos)} / ${_formatDur(dur)}';
  }

  String _formatDur(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
