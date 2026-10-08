// OWNER: ENG-01 (then frozen by ENG-06)
//
// Scaffold placeholder of the Pigeon-backed engine (ARCH §12, §12.6). ENG-01 replaces the
// bootstrap channel with the generated Pigeon host APIs (EngineHostApi, PreviewHostApi,
// JobsHostApi, ExportHostApi incl. start(…, whenDetached)/resume/consumeJobRecord,
// RecorderHostApi, PlatformHostApi, EngineEventsApi) and wires the mobile_* services
// (ENG-02/03/04). Until then every call fails with `notSupportedOnDevice` and capabilities()
// reports `engine_not_available`, so the editor shows its unsupported state instead of crashing.

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

import 'error_mapper.dart';

/// The iOS + Android editor engine.
final class MobileEditorEngine implements EditorEngine {
  /// Creates the engine for [config]. [channel] is for tests.
  MobileEditorEngine({required this.config, @visibleForTesting MethodChannel? channel}) : _channel = channel ?? bootstrapChannel;

  /// Channel registered by the placeholder native plugins (removed by ENG-01's Pigeon surface).
  static const MethodChannel bootstrapChannel = MethodChannel('com.vecvel.vwish.editor.engine/bootstrap');

  /// Engine directories.
  final EditorEngineConfig config;

  final MethodChannel _channel;
  EditorCapabilities? _caps;

  Never _unavailable(String what) =>
      throw EngineFailure.of(EngineErrorCode.notSupportedOnDevice, debugDetail: '$what: the native editor engine is not built yet');

  @override
  Future<EditorCapabilities> capabilities() async {
    final cached = _caps;
    if (cached != null) return cached;
    try {
      await guardEngineCall(() => _channel.invokeMethod<Object?>('capabilities'));
    } on EngineFailure catch (f) {
      if (f.code != EngineErrorCode.notSupportedOnDevice) rethrow;
    }
    return _caps = EditorCapabilities.unsupported(UnsupportedReasons.engineNotAvailable);
  }

  @override
  Future<EditCompatibility> compatibility(String pathOrUri) async =>
      const NotEditable('engine_not_available', 'the native editor engine is not built yet');

  @override
  Future<MediaProbe> probe(EngineMedia media) async => _unavailable('probe');

  @override
  Future<PreviewSession> openPreview(PreviewConfig config) async => _unavailable('openPreview');

  @override
  ThumbnailSource get thumbnails => _unavailable('thumbnails');

  @override
  WaveformSource get waveforms => _unavailable('waveforms');

  @override
  MediaJobs get jobs => _unavailable('jobs');

  @override
  ExportService get exporter => _unavailable('exporter');

  @override
  VoiceRecorder? get voiceRecorder => null;

  @override
  MediaPicker get picker => _unavailable('picker');

  @override
  FileHandoff get files => _unavailable('files');

  @override
  MediaAccess get access => _unavailable('access');

  @override
  BackgroundWorkGuard get background => _unavailable('background');

  @override
  ExternalDropTarget get drops => _unavailable('drops');

  @override
  Future<int> freeBytes(String path) async => _unavailable('freeBytes');

  @override
  Stream<EngineSignal> get signals => const Stream.empty();

  @override
  Future<void> trimCaches(CacheTrimLevel level) async {}
}
