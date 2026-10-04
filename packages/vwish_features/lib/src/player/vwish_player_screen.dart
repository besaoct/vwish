import 'dart:async';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/player_controller.dart';
import '../controllers/providers.dart';
import '../diagnostics/vwish_diagnostics_overlay.dart';
import '../queue/vwish_queue_sheet.dart';
import '../settings/vwish_settings_panel.dart';
import 'vwish_controls_overlay.dart';
import 'vwish_player_actions.dart';
import 'vwish_video_viewport.dart';

// Shortcut Intents
class PlayPauseIntent extends Intent { const PlayPauseIntent(); }
class SeekIntent extends Intent { final Duration delta; const SeekIntent(this.delta); }
class VolumeDeltaIntent extends Intent { final double delta; const VolumeDeltaIntent(this.delta); }
class ToggleMuteIntent extends Intent { const ToggleMuteIntent(); }
class ToggleFullscreenIntent extends Intent { const ToggleFullscreenIntent(); }
class EscapeIntent extends Intent { const EscapeIntent(); }
class ToggleAlwaysOnTopIntent extends Intent { const ToggleAlwaysOnTopIntent(); }
class ToggleDiagnosticsIntent extends Intent { const ToggleDiagnosticsIntent(); }
class ToggleQueueSheetIntent extends Intent { const ToggleQueueSheetIntent(); }
class ToggleSettingsIntent extends Intent { const ToggleSettingsIntent(); }
class OpenFileIntent extends Intent { const OpenFileIntent(); }
class SpeedDeltaIntent extends Intent { final double delta; const SpeedDeltaIntent(this.delta); }
class CycleSubtitleIntent extends Intent { const CycleSubtitleIntent(); }
class CycleAudioTrackIntent extends Intent { const CycleAudioTrackIntent(); }

class VwishPlayerScreen extends ConsumerStatefulWidget {
  /// Returns to the previous screen (e.g. Home); the back control is hidden when null.
  final VoidCallback? onBack;

  const VwishPlayerScreen({super.key, this.onBack});

  @override
  ConsumerState<VwishPlayerScreen> createState() => _VwishPlayerScreenState();
}

class _VwishPlayerScreenState extends ConsumerState<VwishPlayerScreen> {
  static const Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.space): PlayPauseIntent(),
    SingleActivator(LogicalKeyboardKey.keyK): PlayPauseIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): SeekIntent(Duration(seconds: -5)),
    SingleActivator(LogicalKeyboardKey.arrowRight): SeekIntent(Duration(seconds: 5)),
    SingleActivator(LogicalKeyboardKey.keyJ): SeekIntent(Duration(seconds: -10)),
    SingleActivator(LogicalKeyboardKey.keyL): SeekIntent(Duration(seconds: 10)),
    SingleActivator(LogicalKeyboardKey.arrowUp): VolumeDeltaIntent(5.0),
    SingleActivator(LogicalKeyboardKey.arrowDown): VolumeDeltaIntent(-5.0),
    SingleActivator(LogicalKeyboardKey.keyM): ToggleMuteIntent(),
    SingleActivator(LogicalKeyboardKey.keyF): ToggleFullscreenIntent(),
    SingleActivator(LogicalKeyboardKey.escape): EscapeIntent(),
    SingleActivator(LogicalKeyboardKey.keyT): ToggleAlwaysOnTopIntent(),
    SingleActivator(LogicalKeyboardKey.keyI): ToggleDiagnosticsIntent(),
    SingleActivator(LogicalKeyboardKey.keyP): ToggleQueueSheetIntent(),
    SingleActivator(LogicalKeyboardKey.keyO): OpenFileIntent(),
    SingleActivator(LogicalKeyboardKey.keyC): CycleSubtitleIntent(),
    CharacterActivator('#'): CycleAudioTrackIntent(),
    SingleActivator(LogicalKeyboardKey.bracketLeft): SpeedDeltaIntent(-0.1),
    SingleActivator(LogicalKeyboardKey.bracketRight): SpeedDeltaIntent(0.1),
    SingleActivator(LogicalKeyboardKey.comma, control: true): ToggleSettingsIntent(),
    SingleActivator(LogicalKeyboardKey.comma, meta: true): ToggleSettingsIntent(),
  };

  late final PlayerController _playerCtrl;
  bool _showSettings = false;
  bool _showQueue = false;
  bool _showDiagnostics = false;
  bool _isDraggingFile = false;
  bool _isLocked = false;
  late final VoidCallback _stopFullscreenSync;
  late final AppLifecycleListener _lifecycle;

  static bool get _isMobilePlatform =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    _playerCtrl = ref.read(playerControllerProvider.notifier);
    if (_isMobilePlatform) PlayerOrientation.enter(this);
    _stopFullscreenSync = PlatformBridge.listenFullscreen(_playerCtrl.syncFullscreen);
    _lifecycle = AppLifecycleListener(onInactive: _playerCtrl.saveResumePoint, onHide: _onHide);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _stopFullscreenSync();
    // The engine may already be shut down when the whole app tears down.
    _playerCtrl.pause().ignore();
    // Library screens have no fullscreen control, so never leave the window stuck in it.
    // Deferred: listeners can't rebuild while the tree is being torn down.
    scheduleMicrotask(() => _playerCtrl.exitFullscreen().ignore());
    if (_isMobilePlatform) PlayerOrientation.release(this);
    super.dispose();
  }

  void _onHide() {
    _playerCtrl.saveResumePoint();
    // Without Now Playing controls a backgrounded phone would keep playing unseen.
    if (_isMobilePlatform) unawaited(_playerCtrl.pause());
  }

  void _handleBack() {
    unawaited(_playerCtrl.pause());
    unawaited(_playerCtrl.exitFullscreen());
    // Upright right away, not when the closing route is finally disposed.
    if (_isMobilePlatform) unawaited(PlayerOrientation.release(this));
    widget.onBack?.call();
  }

  void _handleEscape() {
    if (_showSettings || _showQueue || _showDiagnostics) {
      setState(() {
        _showSettings = false;
        _showQueue = false;
        _showDiagnostics = false;
      });
    } else {
      unawaited(_playerCtrl.exitFullscreen());
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _showSettings = false;
        _showQueue = false;
        _showDiagnostics = false;
      }
    });
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
      _showQueue = false;
    });
  }

  void _toggleQueue() {
    setState(() {
      _showQueue = !_showQueue;
      _showSettings = false;
    });
  }

  void _cycleSubtitles() {
    final tracks = ref.read(playerControllerProvider).tracks;
    final ids = ['no', for (final track in tracks.subtitleTracks) track.id];
    final current = ids.indexOf(tracks.selectedSubtitleTrackId ?? 'no');
    _playerCtrl.setSubtitleTrack(ids[(current + 1) % ids.length]);
  }

  void _cycleAudioTracks() {
    final tracks = ref.read(playerControllerProvider).tracks;
    final ids = [for (final track in tracks.audioTracks) track.id];
    if (ids.length < 2) return;
    final current = ids.indexOf(tracks.selectedAudioTrackId ?? ids.first);
    _playerCtrl.setAudioTrack(ids[(current + 1) % ids.length]);
  }

  Future<void> _onDragDone(DropDoneDetails details) async {
    setState(() => _isDraggingFile = false);
    final refs = <MediaRef>[];
    for (final file in details.files) {
      if (await FileSystemEntity.isDirectory(file.path)) {
        refs.addAll(await LibraryRepository.scanDirectory(file.path));
      } else {
        refs.add(LibraryRepository.mediaRefForFile(file.path));
      }
    }
    if (refs.isNotEmpty) {
      await ref.read(queueControllerProvider.notifier).playFrom(refs);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlayerError?>(playerControllerProvider.select((s) => s.error), (_, error) {
      if (error == null) return;
      showPlayerToast(context, playerErrorMessage(error), kind: playerErrorToastKind(error));
    });
    final state = ref.watch(playerControllerProvider);
    final insets = MediaQuery.paddingOf(context);
    final titleBarVisible = hasDesktopWindowChrome(context) && state.viewMode != ViewMode.fullscreen;
    final topInset = titleBarVisible ? VwishTitleBar.height : 0.0;

    return DropTarget(
      onDragEntered: _isLocked ? null : (_) => setState(() => _isDraggingFile = true),
      onDragExited: _isLocked ? null : (_) => setState(() => _isDraggingFile = false),
      onDragDone: _isLocked ? null : _onDragDone,
      child: Shortcuts(
        shortcuts: _isLocked ? const <ShortcutActivator, Intent>{} : _shortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            PlayPauseIntent: CallbackAction<PlayPauseIntent>(onInvoke: (_) => _playerCtrl.togglePlay()),
            SeekIntent: CallbackAction<SeekIntent>(onInvoke: (intent) => _playerCtrl.seekBy(intent.delta)),
            VolumeDeltaIntent: CallbackAction<VolumeDeltaIntent>(
              onInvoke: (intent) => _playerCtrl.setVolumeDelta(intent.delta),
            ),
            ToggleMuteIntent: CallbackAction<ToggleMuteIntent>(onInvoke: (_) => _playerCtrl.toggleMute()),
            ToggleFullscreenIntent: CallbackAction<ToggleFullscreenIntent>(
              onInvoke: (_) => _playerCtrl.toggleFullscreen(),
            ),
            EscapeIntent: CallbackAction<EscapeIntent>(onInvoke: (_) => _handleEscape()),
            ToggleAlwaysOnTopIntent: CallbackAction<ToggleAlwaysOnTopIntent>(
              onInvoke: (_) => _playerCtrl.toggleAlwaysOnTop(),
            ),
            ToggleDiagnosticsIntent: CallbackAction<ToggleDiagnosticsIntent>(
              onInvoke: (_) => setState(() => _showDiagnostics = !_showDiagnostics),
            ),
            ToggleQueueSheetIntent: CallbackAction<ToggleQueueSheetIntent>(onInvoke: (_) => _toggleQueue()),
            ToggleSettingsIntent: CallbackAction<ToggleSettingsIntent>(onInvoke: (_) => _toggleSettings()),
            OpenFileIntent: CallbackAction<OpenFileIntent>(onInvoke: (_) => openVideoFiles(context, ref)),
            SpeedDeltaIntent: CallbackAction<SpeedDeltaIntent>(
              onInvoke: (intent) => _playerCtrl.setSpeedDelta(intent.delta),
            ),
            CycleSubtitleIntent: CallbackAction<CycleSubtitleIntent>(onInvoke: (_) => _cycleSubtitles()),
            CycleAudioTrackIntent: CallbackAction<CycleAudioTrackIntent>(onInvoke: (_) => _cycleAudioTracks()),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  const Positioned.fill(child: VwishVideoViewport()),
                  Positioned.fill(
                    child: VwishControlsOverlay(
                      onOpenSettings: _toggleSettings,
                      onOpenQueue: _toggleQueue,
                      onToggleDiagnostics: () => setState(() => _showDiagnostics = !_showDiagnostics),
                      isLocked: _isLocked,
                      onToggleLock: _toggleLock,
                      onBack: widget.onBack == null ? null : _handleBack,
                      topInset: topInset,
                    ),
                  ),
                  if (titleBarVisible)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: VwishTitleBar(
                        title: _isLocked ? null : state.currentMediaRef?.title ?? 'Vwish',
                        isAlwaysOnTop: state.isAlwaysOnTop,
                        onToggleAlwaysOnTop: _isLocked ? null : _playerCtrl.toggleAlwaysOnTop,
                      ),
                    ),
                  if (_showSettings)
                    _PanelSlot(
                      topInset: topInset,
                      maxWidth: 360,
                      maxHeight: 640,
                      child: VwishSettingsPanel(onClose: () => setState(() => _showSettings = false)),
                    ),
                  if (_showQueue)
                    _PanelSlot(
                      topInset: topInset,
                      maxWidth: 380,
                      maxHeight: 560,
                      child: VwishQueueSheet(onClose: () => setState(() => _showQueue = false)),
                    ),
                  if (_showDiagnostics)
                    VwishDiagnosticsOverlay(
                      onClose: () => setState(() => _showDiagnostics = false),
                      padding: EdgeInsets.fromLTRB(
                        insets.left,
                        insets.top + topInset + 52,
                        insets.right,
                        insets.bottom + playerControlsReserve(context),
                      ),
                    ),
                  if (_isDraggingFile) const Positioned.fill(child: _DropHighlight()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Places a floating panel at the bottom end, between the top bar and the controls; on short
/// screens it spans nearly the full height instead.
class _PanelSlot extends StatelessWidget {
  const _PanelSlot({
    required this.topInset,
    required this.maxWidth,
    required this.maxHeight,
    required this.child,
  });

  final double topInset;
  final double maxWidth;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final reserve = playerControlsReserve(context);
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < VwishBreakpoints.compact;
          final short = constraints.maxHeight < 520;
          final side = compact ? 12.0 : 16.0;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              insets.left + side,
              insets.top + topInset + (short ? 8 : 64),
              insets.right + side,
              insets.bottom + (short ? 8 : reserve),
            ),
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? double.infinity : maxWidth,
                  maxHeight: maxHeight,
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DropHighlight extends StatelessWidget {
  const _DropHighlight();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: VwishColors.scrim,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: VwishSurface(
            shadow: VwishShadow.soft,
            constraints: BoxConstraints(maxWidth: 420),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VwishTileIcon(Icons.file_download_rounded, size: 40),
                SizedBox(width: 14),
                Flexible(
                  child: Text(
                    'Drop videos or folders to play',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VwishTextStyles.headline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
