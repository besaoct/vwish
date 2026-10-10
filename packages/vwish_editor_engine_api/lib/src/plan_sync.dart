// OWNER: API-02
//
// Placeholder (D-33, created by API-01). API-02 implements `PlanSync` (ARCH §13.1): schedule(project)
// with <= 1 compile in flight (latest wins), compile in an isolate above 300 items, diff,
// applyPatch, planOutOfSync -> setPlan(full) once -> else PreviewFailed. Only the declared public
// names exist here; every member throws `UnimplementedError`.

import 'package:vwish_editor_core/model.dart';
import 'package:vwish_editor_core/plan.dart';

import 'preview.dart';

/// What [PlanSync] is doing (ARCH §13.1).
enum PlanSyncStatus {
  /// Nothing scheduled.
  idle,

  /// A compile is running.
  compiling,

  /// A patch or full plan is being applied.
  applying,

  /// The last apply failed twice (the preview shows the last good frame).
  failed,
}

/// Keeps a [PreviewSession]'s plan in step with the project (ARCH §13.1, API-02).
class PlanSync {
  /// Creates the sync for [session]; [compile] turns a project into a preview plan.
  PlanSync(this.session, {required this.compile});

  /// The session being driven.
  final PreviewSession session;

  /// Project -> plan (runs in an isolate above 300 items).
  final Future<RenderPlan> Function(EditProject project) compile;

  /// Status changes (API-02).
  Stream<PlanSyncStatus> get status => throw UnimplementedError('PlanSync is implemented by API-02');

  /// The last acknowledged plan revision, structural flag and apply time (API-02).
  PlanAck? get lastAck => throw UnimplementedError('PlanSync is implemented by API-02');

  /// Schedules a compile and apply of [project]; the latest call wins (API-02).
  void schedule(EditProject project) => throw UnimplementedError('PlanSync is implemented by API-02');

  /// Sends a coalesced (<= 60 Hz) transient for [item] (API-02).
  void sendTransient(ItemId item, PlanTransient transient) => throw UnimplementedError('PlanSync is implemented by API-02');

  /// Drops the transient of [item] when a commit lands (API-02).
  void dropTransientsFor(ItemId item) => throw UnimplementedError('PlanSync is implemented by API-02');

  /// Stops scheduling.
  Future<void> dispose() => throw UnimplementedError('PlanSync is implemented by API-02');
}
