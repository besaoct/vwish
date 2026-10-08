// OWNER: CORE-29
//
// RenderPlan contract fixtures: JSON Schema, byte-identical round trip, validator, grid cuts.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';
import 'package:vwish_editor_core/plan.dart';

const _dir = 'test/fixtures/render_plans/contract';

Uint8List _bytes(String path) => Uint8List.fromList(utf8.encode(File(path).readAsStringSync().trimRight()));

void main() {
  final schema = JsonSchema.create(
    jsonDecode(File('schema/render_plan.v1.schema.json').readAsStringSync()) as Object,
    schemaVersion: SchemaVersion.draft2020_12,
  );
  final valid = Directory(_dir).listSync().whereType<File>().where((f) => f.path.endsWith('.json') && !f.path.endsWith('.expected_active.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in valid) {
    final name = f.uri.pathSegments.last;
    test('$name validates against the JSON Schema', () {
      final result = schema.validate(jsonDecode(f.readAsStringSync()));
      expect(result.isValid, isTrue, reason: result.errors.join('\n'));
    });
    test('$name round-trips byte-identically', () {
      final bytes = _bytes(f.path);
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      final Uint8List again;
      if (json.containsKey('rev')) {
        final plan = PlanJson.decodePlanBytes(bytes);
        expect(PlanValidator.validate(plan), isEmpty);
        again = PlanJson.encodePlanBytes(plan);
      } else if (json.containsKey('from')) {
        again = PlanJson.encodePatchBytes(PlanJson.decodePatchBytes(bytes));
      } else {
        again = PlanJson.encodeTransientBytes(PlanJson.decodeTransientBytes(bytes));
      }
      expect(utf8.decode(again), utf8.decode(bytes));
    });
  }

  for (final f in Directory('$_dir/invalid').listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    test('invalid/$name fails with the expected layer id', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final expected = json['_expect']! as Map<String, Object?>;
      final violations = PlanValidator.validate(PlanJson.decodePlan(json));
      expect(
        violations.any((v) => v.code.name == expected['code'] && v.id == expected['id']),
        isTrue,
        reason: violations.join('\n'),
      );
    });
  }

  test('grid_cuts_30fps: active layers per frame, also from platform times (D-35)', () {
    final plan = PlanJson.decodePlanBytes(_bytes('$_dir/grid_cuts_30fps.json'));
    final expected = jsonDecode(File('$_dir/grid_cuts_30fps.expected_active.json').readAsStringSync()) as Map<String, Object?>;
    final grid = plan.canvas.gridRate;
    for (final e in (expected['frames']! as List).cast<Map<String, Object?>>()) {
      final k = e['k']! as int;
      final active = (e['active']! as List).cast<String>();
      expect(plan.activeLayerIdsAt(grid.timeOfFrame(k)), active, reason: 'k=$k');
      // A platform clock stamps frame k at P(k), up to 1 µs before the plan edge: map it first.
      final fromPlatform = grid.timeOfFrame(grid.frameIndexNearest(grid.platformTimeOfFrame(k)));
      expect(plan.activeLayerIdsAt(fromPlatform), active, reason: 'k=$k via P(k)');
    }
  });

  test('colour codec', () {
    expect(PlanJson.encodeColor(0xFF102030), '#102030FF');
    expect(PlanJson.decodeColor('#102030FF'), 0xFF102030);
    expect(PlanJson.decodeColor('#102030'), 0xFF102030);
  });
}
