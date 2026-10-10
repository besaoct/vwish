import 'dart:isolate';
import 'package:test/test.dart';
import 'package:vwish_editor_core/plan.dart';
import 'package:vwish_editor_core/eval.dart';
import 'package:vwish_editor_core/model.dart';
import '../../support/random_project.dart';
import 'support.dart';

void main() {
  test('smoke', () async {
    final p = randomProject(11, const RandomProjectSpec(items: 2000));
    print('items ${p.index.itemCount}');
    final r = resolverFor(p);
    var ramps = 0; var vis = 0;
    for (final t in p.tracks) { if (t.kind == TrackKind.video || t.kind == TrackKind.overlay) for (final i in t.items) { if (i is MediaClip) { vis++; if (i.speed is SpeedRamp) ramps++; } } }
    print('visual clips $vis ramps $ramps');
    final times = await Isolate.run(() {
      final sw = Stopwatch();
      final out = <int>[];
      for (var i = 0; i < 25; i++) { sw..reset()..start(); compilePlan(p, PlanTarget.preview, r); sw.stop(); out.add(sw.elapsedMicroseconds); }
      out.sort();
      return out;
    });
    print(times);
    final c = compilePlan(p, PlanTarget.preview, r);
    print('layers ${c.plan.layers.length} slots ${c.packing.slotCount}');
    final small = randomProject(3, const RandomProjectSpec(items: 12));
    print(canonical(compilePlan(small, PlanTarget.preview, resolverFor(small, proxied: {for (final a in small.pool.assets.values) a.id})).plan));
  });
}
