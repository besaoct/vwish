// OWNER: AI-02

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_whisper/vwish_whisper.dart';

void main() {
  test('platform support matrix', () {
    expect(WhisperSupport.evaluate(platform: TargetPlatform.iOS, isWeb: false), const WhisperSupported());
    expect(WhisperSupport.evaluate(platform: TargetPlatform.android, isWeb: false, abi: 'arm64-v8a'), const WhisperSupported());
    expect(WhisperSupport.evaluate(platform: TargetPlatform.android, isWeb: false, abi: 'armeabi-v7a'),
        const WhisperUnsupported(WhisperUnsupportedReason.abi));
    for (final p in [TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux]) {
      expect(WhisperSupport.evaluate(platform: p, isWeb: false), const WhisperUnsupported(WhisperUnsupportedReason.platform));
    }
  });

  test('runtime opens without a native library and never throws', () async {
    final rt = await WhisperRuntime.open();
    expect(rt.support, isA<WhisperUnsupported>());
  });

  test('C header and Dart agree on the ABI version', () {
    final header = File('src/vw_whisper.h').readAsStringSync();
    expect(RegExp(r'#define VW_ABI_VERSION (\d+)').firstMatch(header)!.group(1), '$vwAbiVersion');
  });
}
