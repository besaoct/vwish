// OWNER: AI-07
//
// Placeholder (D-33). AI-07 implements the Dart runtime of ai.md §4.7: WhisperRuntime.open()
// (never throws; opens the native library for this CPU and checks VW_ABI_VERSION), WhisperModel,
// WhisperJob (250 ms polling, Finalizer), WhisperTranscribeRequest, WhisperJobUpdate,
// RawSegment/RawWord, WhisperException(WhisperErrorKind). The scaffold declares only open() and
// support so desktop builds already report unsupported(platform) (AI-02 acceptance).

import '../support.dart';

/// The whisper runtime (ai.md §4.7).
abstract interface class WhisperRuntime {
  /// Opens the runtime. Never throws; check [support]. Until AI-07 lands this reports
  /// `unsupported(platform)` on desktop and `unsupported(libraryUnavailable)` on iOS/Android.
  static Future<WhisperRuntime> open() async {
    final platform = WhisperSupport.evaluate();
    return _UnavailableRuntime(
      platform is WhisperUnsupported ? platform : const WhisperUnsupported(WhisperUnsupportedReason.libraryUnavailable),
    );
  }

  /// Support state.
  WhisperSupport get support;

  /// whisper.cpp version of the loaded library ("" when unavailable).
  String get engineVersion;
}

final class _UnavailableRuntime implements WhisperRuntime {
  const _UnavailableRuntime(this.support);

  @override
  final WhisperSupport support;

  @override
  String get engineVersion => '';
}
