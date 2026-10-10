// OWNER: AI-07
//
// Placeholder (D-33). AI-02 declares the public API names of ai.md §4.7; AI-07 replaces the
// private stand-in below with the real runtime: opening the native library through
// `library_loader.dart` (never at import time), `WhisperModel` (async load, refcount), the polling
// `WhisperJob` (250 ms timer, Finalizer) and the schema-1 segment decoder. Until then `open()`
// reports `unsupported(platform)` on desktop and web and `unsupported(libraryUnavailable)` on
// iOS and Android, and `loadModel` throws `WhisperException(libraryUnavailable)`.

library;

import '../device/device.dart';
import '../support.dart';
import 'whisper_types.dart';

export 'whisper_types.dart';

/// The whisper runtime (ai.md §4.7).
abstract interface class WhisperRuntime {
  /// Opens the runtime. Never throws; check [support]. [channel] defaults to the plugin's device
  /// channel (tests pass a fake).
  static Future<WhisperRuntime> open({WhisperDeviceChannel? channel}) async {
    final platform = WhisperSupport.evaluate();
    return _UnavailableRuntime(
      platform is WhisperUnsupported ? platform : const WhisperUnsupported(WhisperUnsupportedReason.libraryUnavailable),
      channel ?? WhisperDeviceChannel(),
    );
  }

  /// Support state.
  WhisperSupport get support;

  /// whisper.cpp version of the loaded library ("" when unavailable).
  String get engineVersion;

  /// Device profile and thermal/memory/lifecycle events (ai.md §4.8).
  WhisperDeviceChannel get device;

  /// Starts loading a model; completes when ready. [cancel] abandons the result (the native load
  /// finishes, then frees itself). Throws [WhisperException].
  Future<WhisperModel> loadModel(
    String modelPath, {
    WhisperModelOptions options = const WhisperModelOptions(),
    WhisperCancelToken? cancel,
  });
}

/// A loaded model. At most one job runs on a model at a time.
abstract interface class WhisperModel {
  /// What the model reports.
  WhisperModelInfo get info;

  /// A job is running.
  bool get isBusy;

  /// Detects the spoken language.
  WhisperJob detectLanguage(WhisperDetectRequest request);

  /// Transcribes in chunks.
  WhisperJob transcribe(WhisperTranscribeRequest request);

  /// Releases the model (refcounted natively; freed after the last job).
  Future<void> release();
}

/// A native job polled every 250 ms.
abstract interface class WhisperJob {
  /// Broadcast updates; status is throttled to 4 Hz.
  Stream<WhisperJobUpdate> get updates;

  /// Completes with the result; throws [WhisperException] (`cancelled`, `inference`, `oom`, ...).
  Future<WhisperJobResult> get result;

  /// Cancels.
  void cancel();

  /// Pauses at the next chunk boundary, or aborts the running chunk (redone on resume) when
  /// [abortCurrentChunk] is true (iOS background).
  void pause({bool abortCurrentChunk = false});

  /// Resumes.
  void resume();

  /// Changes the thread count, applied at the next chunk.
  set threads(int value);
}

final class _UnavailableRuntime implements WhisperRuntime {
  const _UnavailableRuntime(this.support, this.device);

  @override
  final WhisperSupport support;

  @override
  final WhisperDeviceChannel device;

  @override
  String get engineVersion => '';

  @override
  Future<WhisperModel> loadModel(
    String modelPath, {
    WhisperModelOptions options = const WhisperModelOptions(),
    WhisperCancelToken? cancel,
  }) =>
      Future<WhisperModel>.error(const WhisperException(WhisperErrorKind.libraryUnavailable));
}
