import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_data/vwish_data.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_engine/vwish_engine.dart';
import 'package:vwish_features/vwish_features.dart';
import 'package:vwish_ui_kit/vwish_ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vwish_player/app.dart';

void main() {
  testWidgets('VwishApp initializes and renders player controls', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sessionRepo = SessionRepository(prefs);
    final libraryRepo = LibraryRepository(prefs);
    final fakeEngine = FakePlaybackEngine();
    await fakeEngine.initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackEngineProvider.overrideWithValue(fakeEngine),
          sessionRepositoryProvider.overrideWithValue(sessionRepo),
          libraryRepositoryProvider.overrideWithValue(libraryRepo),
        ],
        child: const VwishApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial idle state
    expect(find.text('No Media Loaded'), findsOneWidget);

    // Open media
    await fakeEngine.open(MediaSource.file('/test/demo.mkv', title: 'demo.mkv'));
    await tester.pumpAndSettle();

    // Verify playback controls are present
    expect(find.byType(VwishControlsOverlay), findsOneWidget);
    expect(find.byType(VwishSeekBar), findsOneWidget);
    expect(find.byType(VwishVolumeSlider), findsOneWidget);

    await fakeEngine.dispose();
  });
}
