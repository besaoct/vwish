import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_engine/vwish_engine.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'providers.dart';

class PlayerController extends StateNotifier<PlayerState> {
  final PlaybackEngine _engine;
  final SessionRepository _sessionRepo;
  final LibraryRepository _libraryRepo;
  final Ref _ref;

  StreamSubscription<PlayerSnapshot>? _snapshotSub;
  StreamSubscription<PlayerError>? _errorSub;
  Timer? _resumeSaveTimer;

  PlayerController(this._engine, this._sessionRepo, this._libraryRepo, this._ref)
      : super(const PlayerState()) {
    _init();
  }

  void _init() {
    _snapshotSub = _engine.snapshots.listen(_handleSnapshot);
    _errorSub = _engine.errors.listen(_handleError);

    // Initial global settings
    final vol = _sessionRepo.getGlobalVolume();
    final speed = _sessionRepo.getGlobalSpeed();
    _engine.setVolume(vol);
    _engine.setSpeed(speed);

    // Periodic resume save every 5s
    _resumeSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveCurrentResume();
    });
  }

  void _handleSnapshot(PlayerSnapshot s) {
    // Handle sleep inhibitor
    if (s.status == PlaybackStatus.playing && state.status != PlaybackStatus.playing) {
      PlatformBridge.setSleepInhibited(true);
    } else if (s.status != PlaybackStatus.playing && state.status == PlaybackStatus.playing) {
      PlatformBridge.setSleepInhibited(false);
    }

    state = state.copyWith(
      status: s.status,
      position: s.position,
      duration: s.duration,
      cacheEnd: s.cacheEnd,
      speed: s.speed,
      volume: s.volume,
      muted: s.muted,
      tracks: s.tracks,
      chapters: s.chapters,
      adjust: s.adjust,
      transform: s.transform,
      subtitleStyle: s.subtitleStyle,
      audioFilter: s.audioFilter,
      subtitleDelay: s.subtitleDelay,
      audioDelay: s.audioDelay,
      abLoop: s.abLoop,
      stats: s.stats,
    );

    // If EOF/ended, check for auto-advance in Queue
    if (s.status == PlaybackStatus.ended) {
      _saveCurrentResume();
      _ref.read(queueControllerProvider.notifier).onPlaybackEnded();
    }
  }

  void _handleError(PlayerError err) {
    state = state.copyWith(error: err);
  }

  void _saveCurrentResume() {
    final ref = state.currentMediaRef;
    if (ref != null && state.duration > Duration.zero) {
      _sessionRepo.saveResumePosition(ref.id, state.position, state.duration);
    }
  }

  Future<void> openMedia(MediaRef media, {Duration? startAt}) async {
    _saveCurrentResume();

    state = state.copyWith(
      currentMediaRef: media,
      currentSource: media.isRemote
          ? MediaSource.network(media.pathOrUri, title: media.title)
          : MediaSource.file(media.pathOrUri, title: media.title),
      error: null,
    );

    // Check for saved resume position if startAt is null
    final resumePos = startAt ?? _sessionRepo.getResumePosition(media.id, media.duration);

    await _engine.open(
      state.currentSource!,
      startAt: resumePos,
    );

    // Restore per-file preferences
    final subDelay = _sessionRepo.getSubtitleDelay(media.id);
    final audioDelay = _sessionRepo.getAudioDelay(media.id);
    final adjust = _sessionRepo.getVideoAdjust(media.id);

    if (subDelay != Duration.zero) await _engine.setSubtitleDelay(subDelay);
    if (audioDelay != Duration.zero) await _engine.setAudioDelay(audioDelay);
    if (adjust != VideoAdjust.normal) await _engine.setVideoAdjust(adjust);

    // Auto-discover sidecar subtitles if local file
    if (!media.isRemote) {
      final sidecars = await LibraryRepository.discoverSidecarSubtitles(media.pathOrUri);
      for (final subPath in sidecars) {
        await _engine.addSubtitleFile(subPath, select: false);
      }
    }

    // Record in recently played history
    await _libraryRepo.recordPlayed(media);
  }

  Future<void> togglePlay() => _engine.playOrPause();
  Future<void> play() => _engine.play();
  Future<void> pause() => _engine.pause();
  Future<void> stop() => _engine.stop();

  Future<void> seek(Duration pos, {SeekMode mode = SeekMode.keyframe}) =>
      _engine.seek(pos, mode: mode);

  Future<void> seekBy(Duration delta) => _engine.seekBy(delta);
  Future<void> frameStep(int direction) => _engine.frameStep(direction);

  Future<void> setVolume(double vol) async {
    await _engine.setVolume(vol);
    await _sessionRepo.saveGlobalVolume(vol);
  }

  Future<void> setVolumeDelta(double delta) async {
    final nextVol = (state.volume + delta).clamp(0.0, 300.0);
    await setVolume(nextVol);
  }

  Future<void> toggleMute() => _engine.setMuted(!state.muted);

  Future<void> setSpeed(double speed) async {
    await _engine.setSpeed(speed);
    await _sessionRepo.saveGlobalSpeed(speed);
  }

  Future<void> setSpeedDelta(double delta) async {
    final nextSpeed = (state.speed + delta).clamp(0.1, 16.0);
    await setSpeed(nextSpeed);
  }

  Future<void> setAudioTrack(String? id) => _engine.setAudioTrack(id);
  Future<void> setVideoTrack(String? id) => _engine.setVideoTrack(id);
  Future<void> setSubtitleTrack(String? id) => _engine.setSubtitleTrack(id);
  Future<void> setSecondarySubtitleTrack(String? id) =>
      _engine.setSecondarySubtitleTrack(id);

  Future<void> setSubtitleDelay(Duration delay) async {
    await _engine.setSubtitleDelay(delay);
    if (state.currentMediaRef != null) {
      await _sessionRepo.saveSubtitleDelay(state.currentMediaRef!.id, delay);
    }
  }

  Future<void> setAudioDelay(Duration delay) async {
    await _engine.setAudioDelay(delay);
    if (state.currentMediaRef != null) {
      await _sessionRepo.saveAudioDelay(state.currentMediaRef!.id, delay);
    }
  }

  Future<void> setVideoAdjust(VideoAdjust adjust) async {
    await _engine.setVideoAdjust(adjust);
    if (state.currentMediaRef != null) {
      await _sessionRepo.saveVideoAdjust(state.currentMediaRef!.id, adjust);
    }
  }

  Future<void> setVideoTransform(VideoTransform t) => _engine.setVideoTransform(t);
  Future<void> setAudioFilters(AudioFilter filter) => _engine.setAudioFilters(filter);
  Future<void> setSubtitleStyle(SubtitleStyle style) => _engine.setSubtitleStyle(style);
  Future<void> setAbLoop(Duration? a, Duration? b) => _engine.setAbLoop(a, b);

  Future<void> toggleFullscreen() async {
    final nextMode = state.viewMode == ViewMode.fullscreen
        ? ViewMode.windowed
        : ViewMode.fullscreen;
    state = state.copyWith(viewMode: nextMode);
    await PlatformBridge.setFullscreen(nextMode == ViewMode.fullscreen);
  }

  Future<void> toggleAlwaysOnTop() async {
    final next = !state.isAlwaysOnTop;
    state = state.copyWith(isAlwaysOnTop: next);
    await PlatformBridge.setAlwaysOnTop(next);
  }

  Future<Uint8List?> captureScreenshot({bool includeSubtitles = true}) =>
      _engine.screenshot(includeSubtitles: includeSubtitles);

  @override
  void dispose() {
    _resumeSaveTimer?.cancel();
    _snapshotSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }
}
