// OWNER: CORE-02
//
// Frame grid and platform-time rule (ARCH §5, D-35).

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vwish_editor_core/model.dart';

import '../../tool/gen_frame_vectors.dart' as gen;

void main() {
  const rates = FrameRate.supportedProjectRates;

  test('frameIndexOf inverts timeOfFrame on sampled frames up to 24 h', () {
    for (final fps in rates) {
      final r = FrameRate(fps, 1);
      for (final k in [0, 1, 2, 3, fps - 1, fps, fps + 1, 1000, 3600 * fps + 2, 24 * 3600 * fps - 1]) {
        expect(r.frameIndexOf(r.timeOfFrame(k)), k, reason: '$fps fps k=$k');
        expect(r.frameIndexOf(r.timeOfFrame(k + 1) - 1), k, reason: '$fps fps k=$k end');
      }
    }
  });

  test('frameIndexNearest maps every platform form of frame k back to k', () {
    for (final fps in rates) {
      final r = FrameRate(fps, 1);
      final h = floorDiv(microsPerSecond, 2 * fps) - 1;
      for (var k = 0; k < 3 * fps; k++) {
        final forms = [r.timeOfFrame(k), floorDiv(k * microsPerSecond, fps), r.platformTimeOfFrame(k)];
        for (final x in forms) {
          expect(r.frameIndexNearest(x), k, reason: '$fps fps k=$k x=$x');
        }
        expect(r.frameIndexNearest(r.platformTimeOfFrame(k) + h), k);
        expect(r.frameIndexNearest(r.platformTimeOfFrame(k) - h), k);
        expect(r.frameIndexOfRational(k, fps), k);
      }
    }
  });

  test('P(k) equals the Media3 double formula round((1e6/fps)*k)', () {
    for (final fps in rates) {
      final r = FrameRate(fps, 1);
      for (final k in [1, 2, 31, 32, 1001, 3600 * fps + 1, 24 * 3600 * fps - 1]) {
        expect(r.platformTimeOfFrame(k), ((1e6 / fps) * k).round(), reason: '$fps fps k=$k');
      }
    }
  });

  test('plan edges at k ≡ 1, 2 (mod 3) sit up to 1 µs after the platform time (why D-35 exists)', () {
    const r = FrameRate.fps30;
    expect(r.timeOfFrame(31) - r.platformTimeOfFrame(31), 1);
    expect(r.timeOfFrame(32) - r.platformTimeOfFrame(32), 0);
    expect(r.frameIndexOf(r.platformTimeOfFrame(31)), 30, reason: 'floor mapping is wrong for platform times');
    expect(r.frameIndexNearest(r.platformTimeOfFrame(31)), 31);
  });

  test('FrameRate.project accepts only v1 rates', () {
    expect(FrameRate.project(30), FrameRate.fps30);
    expect(() => FrameRate.project(29), throwsArgumentError);
  });

  test('Timecode round trip floors to the grid', () {
    for (final fps in rates) {
      final r = FrameRate(fps, 1);
      for (final t in [0, 1, 999999, 5333333, 3600 * 1000000 + 17]) {
        expect(Timecode.parse(Timecode.format(t, r), r), r.quantize(t));
      }
    }
  });

  test('committed frame_grid.json is up to date', () {
    final committed = jsonDecode(File('test/fixtures/vectors/frame_grid.json').readAsStringSync()) as Map<String, Object?>;
    final fresh = jsonDecode(jsonEncode(gen.buildVectors(androidSeekMsRounding: committed['androidSeekMsRounding'])));
    expect(committed, fresh);
  });
}
