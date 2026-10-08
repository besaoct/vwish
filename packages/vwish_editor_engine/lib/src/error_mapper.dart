// OWNER: ENG-01
//
// Maps channel errors to typed engine failures (ARCH §12.5, §19). No raw PlatformException ever
// leaves the plugin; unknown codes map to `internal`; messages are scrubbed of paths.

import 'package:flutter/services.dart';
import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

final RegExp _pathLike = RegExp(r'''(file|content)://\S+|(?<![\w.])/(?:[^\s/'"]+/)+[^\s'"]*''');

/// Removes anything that looks like a file path or URI from [text] (defence in depth: native
/// code must not send paths in the first place).
String scrubPaths(String text) => text.replaceAll(_pathLike, '<path>');

/// Converts any error thrown by a channel call into an [EngineFailure].
EngineFailure mapEngineError(Object error) {
  if (error is EngineFailure) return error;
  if (error is PlatformException) {
    final details = error.details;
    final map = details is Map ? details : const <Object?, Object?>{};
    return EngineFailure.of(
      EngineErrorCode.fromName(error.code),
      debugDetail: scrubPaths(error.message ?? ''),
      itemId: map['itemId'] as String?,
      mediaFingerprint: map['mediaFingerprint'] as String?,
      retryable: map['retryable'] == true,
    );
  }
  if (error is MissingPluginException) {
    return EngineFailure.of(EngineErrorCode.notSupportedOnDevice, debugDetail: 'engine plugin not registered on this platform');
  }
  return EngineFailure.of(EngineErrorCode.internal, debugDetail: error.runtimeType.toString());
}

/// Runs [call] and rethrows any error as an [EngineFailure].
Future<T> guardEngineCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on Object catch (e) {
    throw mapEngineError(e);
  }
}
