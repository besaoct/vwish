import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_domain/vwish_domain.dart';

void main() {
  group('op_domain Model Tests', () {
    test('MediaSource creates local and network sources correctly', () {
      final fileSource = MediaSource.file('/path/to/movie.mkv', title: 'movie.mkv');
      expect(fileSource.isLocalFile, isTrue);
      expect(fileSource.title, 'movie.mkv');

      final netSource = MediaSource.network('https://example.com/live.m3u8');
      expect(netSource.isLocalFile, isFalse);
      expect(netSource.uri, 'https://example.com/live.m3u8');
    });

    test('VideoAdjust immutability and JSON serialization', () {
      const adjust = VideoAdjust(brightness: 10.0, contrast: -5.0, saturation: 20.0);
      final json = adjust.toJson();
      final fromJson = VideoAdjust.fromJson(json);

      expect(fromJson.brightness, 10.0);
      expect(fromJson.contrast, -5.0);
      expect(fromJson.saturation, 20.0);
    });

    test('AudioFilter presets application', () {
      const filter = AudioFilter();
      final rockFilter = filter.applyPreset('Rock');

      expect(rockFilter.equalizerBands[0].gain, 4.5);
      expect(rockFilter.equalizerBands[9].gain, 4.5);
    });

    test('QueueState navigation and mutations', () {
      final items = [
        const MediaRef(id: '1', title: 'Ep 1', pathOrUri: '/1.mkv'),
        const MediaRef(id: '2', title: 'Ep 2', pathOrUri: '/2.mkv'),
        const MediaRef(id: '3', title: 'Ep 3', pathOrUri: '/3.mkv'),
      ];

      final queue = QueueState(items: items, currentIndex: 0);
      expect(queue.hasCurrent, isTrue);
      expect(queue.currentItem?.title, 'Ep 1');
      expect(queue.hasNext, isTrue);
      expect(queue.nextItem?.title, 'Ep 2');
      expect(queue.hasPrevious, isFalse);
    });
  });
}
