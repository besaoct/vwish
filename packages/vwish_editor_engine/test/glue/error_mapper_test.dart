// OWNER: ENG-01

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_editor_engine/vwish_editor_engine.dart';
import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every EngineErrorCode maps from a PlatformException', () {
    for (final c in EngineErrorCode.values) {
      final f = mapEngineError(PlatformException(code: c.name, details: {'itemId': 'it_x', 'retryable': true}));
      expect(f.code, c);
      expect(f.itemId, 'it_x');
      expect(f, c == EngineErrorCode.cancelled ? isA<EngineCancelled>() : isA<EngineError>());
    }
  });

  test('unknown codes map to internal and paths are scrubbed', () {
    final f = mapEngineError(PlatformException(code: 'weird', message: 'failed to open /var/mobile/Containers/a/b.mp4 and file:///x/y.mov'));
    expect(f.code, EngineErrorCode.internal);
    expect(f.debugDetail, isNot(contains('/var/mobile')));
    expect(f.debugDetail, isNot(contains('file://')));
  });

  test('a missing plugin is notSupportedOnDevice', () {
    expect(mapEngineError(MissingPluginException()).code, EngineErrorCode.notSupportedOnDevice);
  });

  test('placeholder engine reports engine_not_available through the native bootstrap answer', () async {
    const channel = MethodChannel('test/engine_bootstrap');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'notSupportedOnDevice', message: 'not built');
    });
    final engine = MobileEditorEngine(
      config: const EditorEngineConfig(cacheRoot: '/c/vwish/editor', supportRoot: '/s/vwish/editor'),
      channel: channel,
    );
    final caps = await engine.capabilities();
    expect(caps.supported, isFalse);
    expect(caps.unsupportedReason, UnsupportedReasons.engineNotAvailable);
    expect(() => engine.openPreview(const PreviewConfig(canvasWidth: 16, canvasHeight: 16, fps: 30)), throwsA(isA<EngineFailure>()));
  });
}
