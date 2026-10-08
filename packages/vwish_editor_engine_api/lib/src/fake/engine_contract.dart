// OWNER: API-01
//
// Reusable engine contract kit (ARCH §12.2 normative semantics). Framework-free: returns the
// list of violations so `flutter_test`, `integration_test` (ENG-09 example host) and QA suites can
// all run it against any [EditorEngine].

import 'package:vwish_editor_core/model.dart';
import 'package:vwish_editor_core/plan.dart';

import '../engine.dart';
import '../export.dart';
import '../failures.dart';
import '../preview.dart';

/// A minimal valid 30 fps preview plan of one solid layer, used by the kit.
RenderPlan contractKitPlan({int rev = 1}) {
  const grid = FrameRate.fps30;
  final dur = grid.timeOfFrame(90);
  return RenderPlan(
    rev: rev,
    target: PlanTarget.preview,
    canvas: const PlanCanvas(w: 64, h: 36, fps: 30),
    durUs: dur,
    layers: [PlanLayer(id: 'it_kit00000001#tx0', z: 15, t0: 0, t1: dur, kind: PlanLayerKind.solid, color: 0xFF336699)],
  );
}

/// Runs the preview and export contract against [engine] and returns violations (empty = pass).
Future<List<String>> checkEngineContract(EditorEngine engine, {bool checkExportRecords = true}) async {
  final v = <String>[];
  final caps = await engine.capabilities();
  if (!caps.supported) return ['engine reports unsupported: ${caps.unsupportedReason}'];

  final session = await engine.openPreview(const PreviewConfig(canvasWidth: 64, canvasHeight: 36, fps: 30));
  final plan = contractKitPlan();
  final ack = await session.setPlan(plan);
  if (ack.rev != plan.rev) v.add('setPlan ack rev ${ack.rev} != ${plan.rev}');

  // Patch revision semantics.
  try {
    await session.applyPatch(RenderPlanPatch(from: plan.rev + 5, to: plan.rev + 6));
    v.add('applyPatch with a stale `from` must throw planOutOfSync');
  } on EngineFailure catch (e) {
    if (e.code != EngineErrorCode.planOutOfSync) v.add('stale patch threw ${e.code.name}, expected planOutOfSync');
  }
  // Transients never touch the revision.
  session.setTransient(const ItemId('it_kit00000001'), PlanTransient(item: 'it_kit00000001', layers: const [TransientLayer(id: 'it_kit00000001#tx0', xf: PlanTransform(op: 0.5))]));
  final patched = await session.applyPatch(RenderPlanPatch(from: plan.rev, to: plan.rev + 1));
  if (patched.rev != plan.rev + 1) v.add('patch ack rev ${patched.rev} != ${plan.rev + 1}');

  // Exact seek acks on the frame grid; seq increases.
  const grid = FrameRate.fps30;
  final t = grid.timeOfFrame(31) + 10;
  final a1 = await session.seek(t);
  if (a1.displayedFrame != grid.frameIndexOf(t)) v.add('exact seek displayed ${a1.displayedFrame}, expected ${grid.frameIndexOf(t)}');
  if (a1.displayedFrameTime != grid.timeOfFrame(a1.displayedFrame)) v.add('displayedFrameTime is not timeOfFrame(displayedFrame)');
  final a2 = await session.seek(grid.timeOfFrame(32));
  if (a2.seq <= a1.seq) v.add('seq must increase with every seek');
  await session.dispose();

  // Job cancel semantics.
  final job = engine.jobs.freezeFrame(const ResolvedMedia(uri: 'file:///kit.mp4', fingerprint: 'kit'), 0, outputPath: '/kit.png');
  job.cancel();
  try {
    await job.result;
    v.add('a cancelled job must complete with EngineCancelled');
  } on EngineCancelled {
    // expected
  } on Object catch (e) {
    v.add('cancelled job threw $e');
  }

  // One-shot export records disappear after consumeJobRecord.
  if (checkExportRecords) {
    for (final r in await engine.exporter.activeJobs()) {
      if (r is ExportInterrupted || r is ExportCompletedWhileDetached) {
        await engine.exporter.consumeJobRecord(r.jobId);
        final again = await engine.exporter.activeJobs();
        if (again.any((x) => x.jobId == r.jobId)) v.add('consumed record ${r.jobId} was returned again');
      }
    }
  }
  return v;
}
