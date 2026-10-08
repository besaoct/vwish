// OWNER: AI-02
//
// Whether on-device speech recognition can run here (ai.md §4.7, ARCH §16.1, D-43(b)). Pure:
// opening the native library is AI-07's runtime; nothing here touches dart:ffi.

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:meta/meta.dart';

/// Why speech recognition is unavailable.
enum WhisperUnsupportedReason {
  /// Desktop or web (the editor is iOS/Android only in v1).
  platform,

  /// CPU ABI without a shim (Android armeabi-v7a, D-43(b)).
  abi,

  /// OS too old (below the editor gate).
  osVersion,

  /// The native library is missing or its ABI version does not match.
  libraryUnavailable,
}

/// Support state of the whisper runtime.
@immutable
sealed class WhisperSupport {
  const WhisperSupport();

  /// Platform-level support, without loading the library: iOS and Android (arm64-v8a, x86_64)
  /// are candidates; everything else is unsupported. [abi] is Android's primary ABI when known.
  static WhisperSupport evaluate({TargetPlatform? platform, bool isWeb = kIsWeb, String? abi}) {
    if (isWeb) return const WhisperUnsupported(WhisperUnsupportedReason.platform);
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const WhisperSupported();
      case TargetPlatform.android:
        if (abi != null && abi != 'arm64-v8a' && abi != 'x86_64') {
          return const WhisperUnsupported(WhisperUnsupportedReason.abi);
        }
        return const WhisperSupported();
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return const WhisperUnsupported(WhisperUnsupportedReason.platform);
    }
  }
}

/// Speech recognition can run (subject to model tiers and RAM gating in vwish_transcription).
final class WhisperSupported extends WhisperSupport {
  /// Creates the state.
  const WhisperSupported();

  @override
  bool operator ==(Object other) => other is WhisperSupported;

  @override
  int get hashCode => (WhisperSupported).hashCode;
}

/// Speech recognition cannot run.
final class WhisperUnsupported extends WhisperSupport {
  /// Creates the state.
  const WhisperUnsupported(this.reason);

  /// Why.
  final WhisperUnsupportedReason reason;

  @override
  bool operator ==(Object other) => other is WhisperUnsupported && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
