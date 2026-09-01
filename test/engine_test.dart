import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_domain/vwish_domain.dart';
import 'package:vwish_engine/vwish_engine.dart';

void main() {
  group('op_engine FakePlaybackEngine Tests', () {
    late FakePlaybackEngine engine;

    setUp(() {
      engine = FakePlaybackEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('Open media emits playing snapshot with metadata and chapters', () async {
      await engine.initialize();
      await engine.open(MediaSource.file('/test/media.mkv'));

      expect(engine.currentSnapshot.status, PlaybackStatus.playing);
      expect(engine.currentSnapshot.chapters.length, 3);
      expect(engine.currentSnapshot.duration, const Duration(minutes: 10));
    });

    test('Transport controls mutate snapshot state correctly', () async {
      await engine.initialize();
      await engine.open(MediaSource.file('/test/media.mkv'));

      await engine.pause();
      expect(engine.currentSnapshot.status, PlaybackStatus.paused);

      await engine.setVolume(150.0);
      expect(engine.currentSnapshot.volume, 150.0);

      await engine.setSpeed(1.5);
      expect(engine.currentSnapshot.speed, 1.5);

      await engine.seek(const Duration(minutes: 5));
      expect(engine.currentSnapshot.position, const Duration(minutes: 5));
    });
  });
}
