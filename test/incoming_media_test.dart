import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_engine/vwish_engine.dart';
import 'package:vwish_features/vwish_features.dart';
import 'package:vwish_platform/vwish_platform.dart';
import 'package:vwish/app.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';

import 'library_test_utils.dart';

Future<FakePlaybackEngine> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final engine = FakePlaybackEngine();
  await engine.initialize();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playbackEngineProvider.overrideWithValue(engine),
        sessionRepositoryProvider.overrideWithValue(SessionRepository(prefs)),
        libraryRepositoryProvider.overrideWithValue(
          LibraryRepository(prefs, storage: LibraryStorage(isMobile: false)),
        ),
      ],
      child: const VwishApp(),
    ),
  );
  await pumpFrames(tester);
  return engine;
}

Future<void> _tearDown(WidgetTester tester, FakePlaybackEngine engine) async {
  VwishToast.dismiss();
  await tester.pumpWidget(const SizedBox());
  await engine.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IncomingMediaBridge Unit Tests', () {
    test('getInitialMedia returns mockInitialMedia and resets', () async {
      IncomingMediaBridge.mockInitialMedia = 'https://example.com/video.mp4';
      final initial = await IncomingMediaBridge.getInitialMedia();
      expect(initial, 'https://example.com/video.mp4');
    });

    test('MethodChannel getInitialMedia and onOpenMedia communication', () async {
      const channel = MethodChannel('vwish/media_intent');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInitialMedia') {
          return '/storage/emulated/0/Download/sample.mp4';
        }
        return null;
      });

      final initial = await IncomingMediaBridge.getInitialMedia();
      expect(initial, '/storage/emulated/0/Download/sample.mp4');

      final events = <String>[];
      final sub = IncomingMediaBridge.onMediaOpened.listen(events.add);

      // Simulate native platform invoking onOpenMedia
      final binaryMessenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final encodedCall = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onOpenMedia', '/storage/emulated/0/Movies/runtime.mp4'),
      );
      await binaryMessenger.handlePlatformMessage('vwish/media_intent', encodedCall, (data) {});
      await Future<void>.delayed(Duration.zero);

      expect(events, ['/storage/emulated/0/Movies/runtime.mp4']);
      await sub.cancel();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('onMediaOpened receives emitted mock media', () async {
      final events = <String>[];
      final sub = IncomingMediaBridge.onMediaOpened.listen(events.add);

      IncomingMediaBridge.emitMockMedia('https://example.com/stream.m3u8');
      await Future<void>.delayed(Duration.zero);

      expect(events, ['https://example.com/stream.m3u8']);
      await sub.cancel();
    });
  });

  group('VwishApp Incoming Media Handling', () {
    testWidgets('Cold launch with mock initial media automatically plays and opens player', (tester) async {
      const videoUrl = 'https://example.com/files_app_open.mp4';
      IncomingMediaBridge.mockInitialMedia = videoUrl;

      final engine = await _pumpApp(tester);
      await pumpFrames(tester, count: 10);

      // Player screen should be presented
      expect(find.byType(VwishPlayerScreen), findsOneWidget);
      expect(engine.currentSnapshot.status, PlaybackStatus.playing);

      final container = ProviderScope.containerOf(tester.element(find.byType(VwishPlayerScreen)));
      expect(container.read(playerControllerProvider).currentMediaRef?.pathOrUri, videoUrl);

      await _tearDown(tester, engine);
    });

    testWidgets('Cold launch with vwish:// deep link plays target media', (tester) async {
      const targetUrl = 'https://example.com/deep_link_video.mp4';
      IncomingMediaBridge.mockInitialMedia = 'vwish://open?url=$targetUrl';

      final engine = await _pumpApp(tester);
      await pumpFrames(tester, count: 10);

      expect(find.byType(VwishPlayerScreen), findsOneWidget);
      expect(engine.currentSnapshot.status, PlaybackStatus.playing);

      final container = ProviderScope.containerOf(tester.element(find.byType(VwishPlayerScreen)));
      expect(container.read(playerControllerProvider).currentMediaRef?.pathOrUri, targetUrl);

      await _tearDown(tester, engine);
    });

    testWidgets('Runtime media event while app is open triggers playback and navigates to player', (tester) async {
      IncomingMediaBridge.mockInitialMedia = null;
      final engine = await _pumpApp(tester);

      expect(find.byType(VwishHomeScreen), findsOneWidget);
      expect(find.byType(VwishPlayerScreen), findsNothing);

      const runtimeUrl = 'https://example.com/opened_from_files_at_runtime.mp4';
      IncomingMediaBridge.emitMockMedia(runtimeUrl);
      await pumpFrames(tester, count: 10);

      expect(find.byType(VwishPlayerScreen), findsOneWidget);
      expect(engine.currentSnapshot.status, PlaybackStatus.playing);

      final container = ProviderScope.containerOf(tester.element(find.byType(VwishPlayerScreen)));
      expect(container.read(playerControllerProvider).currentMediaRef?.pathOrUri, runtimeUrl);

      await _tearDown(tester, engine);
    });
  });
}
