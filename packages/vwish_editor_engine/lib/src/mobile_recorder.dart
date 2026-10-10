// OWNER: ENG-03
//
// Placeholder (D-33, created by ENG-01). ENG-03 replaces the bodies: MobileVoiceRecorder over
// RecorderHostApi with a RecordingSession whose levels (20 Hz) and interruptions come from
// `channels.router.job(recordingId)` (ARCH §12.4, §15). Only the declared public names exist
// here; every member throws `UnimplementedError`.

import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

import 'pigeon/engine_channels.dart';

Never _todo() => throw UnimplementedError('MobileVoiceRecorder is implemented by ENG-03');

/// Voice recorder over `RecorderHostApi` (ARCH §12.4, ENG-03).
final class MobileVoiceRecorder implements VoiceRecorder {
  /// Creates the recorder.
  MobileVoiceRecorder(EngineChannels channels);

  @override
  Future<MicPermission> permission() => _todo();

  @override
  Future<MicPermission> requestPermission() => _todo();

  @override
  Future<void> openSystemSettings() => _todo();

  @override
  Future<RecordingSession> start({required String outputPath}) => _todo();
}
