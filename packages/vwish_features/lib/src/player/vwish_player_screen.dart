import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import '../controllers/providers.dart';
import '../diagnostics/vwish_diagnostics_overlay.dart';
import '../queue/vwish_queue_sheet.dart';
import '../settings/vwish_settings_panel.dart';
import 'vwish_controls_overlay.dart';
import 'vwish_video_viewport.dart';

// Shortcut Intents
class PlayPauseIntent extends Intent { const PlayPauseIntent(); }
class SeekIntent extends Intent { final Duration delta; const SeekIntent(this.delta); }
class VolumeDeltaIntent extends Intent { final double delta; const VolumeDeltaIntent(this.delta); }
class ToggleMuteIntent extends Intent { const ToggleMuteIntent(); }
class ToggleFullscreenIntent extends Intent { const ToggleFullscreenIntent(); }
class ToggleAlwaysOnTopIntent extends Intent { const ToggleAlwaysOnTopIntent(); }
class ToggleDiagnosticsIntent extends Intent { const ToggleDiagnosticsIntent(); }
class ToggleQueueSheetIntent extends Intent { const ToggleQueueSheetIntent(); }
class ToggleSettingsIntent extends Intent { const ToggleSettingsIntent(); }
class OpenFileIntent extends Intent { const OpenFileIntent(); }
class SpeedDeltaIntent extends Intent { final double delta; const SpeedDeltaIntent(this.delta); }

class VwishPlayerScreen extends ConsumerStatefulWidget {
  const VwishPlayerScreen({super.key});

  @override
  ConsumerState<VwishPlayerScreen> createState() => _VwishPlayerScreenState();
}

class _VwishPlayerScreenState extends ConsumerState<VwishPlayerScreen> {
  bool _showSettings = false;
  bool _showQueue = false;
  bool _showDiagnostics = false;
  bool _isDraggingFile = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    final playerCtrl = ref.read(playerControllerProvider.notifier);
    final queueCtrl = ref.read(queueControllerProvider.notifier);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDraggingFile = true),
      onDragExited: (_) => setState(() => _isDraggingFile = false),
      onDragDone: (details) async {
        setState(() => _isDraggingFile = false);
        if (details.files.isNotEmpty) {
          final refs = <MediaRef>[];
          for (final xFile in details.files) {
            final path = xFile.path;
            if (await FileSystemEntity.isDirectory(path)) {
              final folderItems = await LibraryRepository.scanDirectory(path);
              refs.addAll(folderItems);
            } else {
              refs.add(MediaRef(
                id: path,
                title: xFile.name,
                pathOrUri: path,
              ));
            }
          }
          if (refs.isNotEmpty) {
            await queueCtrl.playFrom(refs, startIndex: 0);
          }
        }
      },
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
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
          SingleActivator(LogicalKeyboardKey.keyT): ToggleAlwaysOnTopIntent(),
          SingleActivator(LogicalKeyboardKey.keyI): ToggleDiagnosticsIntent(),
          SingleActivator(LogicalKeyboardKey.keyP): ToggleQueueSheetIntent(),
          SingleActivator(LogicalKeyboardKey.keyO): OpenFileIntent(),
          SingleActivator(LogicalKeyboardKey.bracketLeft): SpeedDeltaIntent(-0.1),
          SingleActivator(LogicalKeyboardKey.bracketRight): SpeedDeltaIntent(0.1),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            PlayPauseIntent: CallbackAction<PlayPauseIntent>(
              onInvoke: (_) => playerCtrl.togglePlay(),
            ),
            SeekIntent: CallbackAction<SeekIntent>(
              onInvoke: (intent) => playerCtrl.seekBy(intent.delta),
            ),
            VolumeDeltaIntent: CallbackAction<VolumeDeltaIntent>(
              onInvoke: (intent) => playerCtrl.setVolumeDelta(intent.delta),
            ),
            ToggleMuteIntent: CallbackAction<ToggleMuteIntent>(
              onInvoke: (_) => playerCtrl.toggleMute(),
            ),
            ToggleFullscreenIntent: CallbackAction<ToggleFullscreenIntent>(
              onInvoke: (_) => playerCtrl.toggleFullscreen(),
            ),
            ToggleAlwaysOnTopIntent: CallbackAction<ToggleAlwaysOnTopIntent>(
              onInvoke: (_) => playerCtrl.toggleAlwaysOnTop(),
            ),
            ToggleDiagnosticsIntent: CallbackAction<ToggleDiagnosticsIntent>(
              onInvoke: (_) => setState(() => _showDiagnostics = !_showDiagnostics),
            ),
            ToggleQueueSheetIntent: CallbackAction<ToggleQueueSheetIntent>(
              onInvoke: (_) => setState(() => _showQueue = !_showQueue),
            ),
            OpenFileIntent: CallbackAction<OpenFileIntent>(
              onInvoke: (_) async {
                final files = await PlatformBridge.pickVideoFiles();
                if (files.isNotEmpty) {
                  final refs = files
                      .map((p) => MediaRef(
                            id: p,
                            title: p.split(RegExp(r'[/\\]')).last,
                            pathOrUri: p,
                          ))
                      .toList();
                  queueCtrl.playFrom(refs);
                }
                return null;
              },
            ),
            SpeedDeltaIntent: CallbackAction<SpeedDeltaIntent>(
              onInvoke: (intent) => playerCtrl.setSpeedDelta(intent.delta),
            ),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // 1. Video Texture Layer
                  Positioned.fill(
                    child: VwishVideoViewport(
                      onTap: () => playerCtrl.togglePlay(),
                      onDoubleTap: () => playerCtrl.toggleFullscreen(),
                    ),
                  ),

                  // 2. Custom Title Bar (Desktop Only)
                  if (state.viewMode != ViewMode.fullscreen)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: VwishTitleBar(
                        title: state.currentMediaRef?.title ?? 'Vwish Player',
                        isAlwaysOnTop: state.isAlwaysOnTop,
                        onToggleAlwaysOnTop: () => playerCtrl.toggleAlwaysOnTop(),
                      ),
                    ),

                  // 3. Controls Overlay (Bottom bar, top info, play HUD)
                  Positioned.fill(
                    child: VwishControlsOverlay(
                      onOpenSettings: () {
                        setState(() {
                          _showSettings = !_showSettings;
                          _showQueue = false;
                        });
                      },
                      onOpenQueue: () {
                        setState(() {
                          _showQueue = !_showQueue;
                          _showSettings = false;
                        });
                      },
                      onToggleDiagnostics: () {
                        setState(() => _showDiagnostics = !_showDiagnostics);
                      },
                    ),
                  ),

                  // 4. Nested Settings Menu (Positioned bottom right)
                  if (_showSettings)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: VwishSettingsPanel(
                        onClose: () => setState(() => _showSettings = false),
                      ),
                    ),

                  // 5. Queue Side-Sheet (Positioned bottom right)
                  if (_showQueue)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      top: state.viewMode != ViewMode.fullscreen ? 38 : 0,
                      child: VwishQueueSheet(
                        onClose: () => setState(() => _showQueue = false),
                      ),
                    ),

                  // 6. Diagnostics "Stats for Nerds" HUD
                  if (_showDiagnostics)
                    VwishDiagnosticsOverlay(
                      onClose: () => setState(() => _showDiagnostics = false),
                    ),

                  // 7. Drag-and-Drop Overlay Highlight
                  if (_isDraggingFile)
                    Positioned.fill(
                      child: Container(
                        color: VwishColors.primary.withValues(alpha: 0.35),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: VwishColors.surfaceElevatedHigher,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: VwishColors.cyan, width: 2),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.file_download_rounded, color: VwishColors.cyan, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  'Drop video files or folders to play',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
