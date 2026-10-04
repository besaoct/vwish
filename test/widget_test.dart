import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_engine/vwish_engine.dart';
import 'package:vwish_features/vwish_features.dart';
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
        libraryRepositoryProvider.overrideWithValue(LibraryRepository(prefs, storage: LibraryStorage(isMobile: false))),
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
  testWidgets('Home is the start screen with open actions and library sections', (tester) async {
    final engine = await _pumpApp(tester);

    expect(find.byType(VwishHomeScreen), findsOneWidget);
    expect(find.text('Open file'), findsOneWidget);
    expect(find.text('Open folder'), findsOneWidget);
    expect(find.text('Open link'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Folders'), findsOneWidget);
    expect(find.text('Continue watching'), findsNothing);
    expect(tester.takeException(), isNull);

    await _tearDown(tester, engine);
  });

  testWidgets('Open link validates, plays through the engine and opens the player', (tester) async {
    const url = 'https://example.com/videos/big_buck_bunny.mp4';
    final engine = await _pumpApp(tester);

    await tester.tap(find.text('Open link'));
    await pumpFrames(tester);
    await tester.enterText(find.byType(EditableText), 'not a url');
    await tester.tap(find.widgetWithText(VwishButton, 'Play'));
    await pumpFrames(tester);
    final error = MediaUrl.validationError('not a url')!;
    expect(find.text(error), findsOneWidget);
    expect(find.byType(VwishPlayerScreen), findsNothing);

    await tester.enterText(find.byType(EditableText), url);
    await pumpFrames(tester);
    expect(find.text(error), findsNothing, reason: 'the error re-checks live after the first submit');
    await tester.tap(find.widgetWithText(VwishButton, 'Play'));
    await pumpFrames(tester);

    expect(find.byType(VwishPlayerScreen), findsOneWidget);
    expect(engine.currentSnapshot.status, PlaybackStatus.playing);
    final container = ProviderScope.containerOf(tester.element(find.byType(VwishPlayerScreen)));
    expect(container.read(playerControllerProvider).currentMediaRef?.pathOrUri, url);
    expect(container.read(queueControllerProvider).items.single.isRemote, isTrue);

    GoRouter.of(tester.element(find.byType(VwishPlayerScreen))).pop();
    await pumpFrames(tester, count: 10);

    expect(find.byType(VwishPlayerScreen), findsNothing);
    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('Continue watching'), findsOneWidget);
    expect(find.text('big_buck_bunny.mp4'), findsNWidgets(2));
    expect(find.text('example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tearDown(tester, engine);
  });
}
