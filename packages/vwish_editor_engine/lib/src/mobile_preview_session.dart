// OWNER: ENG-02
//
// Placeholder (D-33, created by ENG-01). ENG-02 replaces the bodies: MobilePreviewSession
// implements PreviewSession over PreviewHostApi (ARCH §12.2): plans and patches as UTF-8 JSON
// (PlanTransport, API-02) with PlanAck, planOutOfSync surfaced as EngineFailure, transients
// fire-and-forget and coalesced to one per frame, seq rules, scrub coalescing, clock and events
// from `channels.router.session(sessionId)`, idempotent dispose that releases the route.
// MobileEditorEngine.openPreview calls `PreviewHostApi.open` and constructs this class with the
// reply. Only the declared public names exist here; every member throws `UnimplementedError`.

import 'dart:typed_data';
import 'dart:ui' show Color, Offset, Size;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:vwish_editor_core/model.dart' show ItemId, TimeRange, TimeUs;
import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

import 'pigeon/engine_channels.dart';

Never _todo() => throw UnimplementedError('MobilePreviewSession is implemented by ENG-02');

/// A live preview over `PreviewHostApi` (ARCH §12.2, ENG-02).
final class MobilePreviewSession implements PreviewSession {
  /// Wraps native session [sessionId], bound to [textureId] and opened with [config].
  MobilePreviewSession({
    required EngineChannels channels,
    required PreviewConfig config,
    required String sessionId,
    required int textureId,
  });

  @override
  int get textureId => _todo();

  @override
  ValueListenable<Size?> get frameSize => _todo();

  @override
  Future<PlanAck> setPlan(RenderPlan plan) => _todo();

  @override
  Future<PlanAck> applyPatch(RenderPlanPatch patch) => _todo();

  @override
  void setTransient(ItemId item, PlanTransient transient) => _todo();

  @override
  void clearTransient(ItemId item) => _todo();

  @override
  Future<void> play({TimeRange? loop}) => _todo();

  @override
  Future<void> pause() => _todo();

  @override
  Future<SeekAck> seek(TimeUs t, {SeekKind kind = SeekKind.exact}) => _todo();

  @override
  Future<void> setQuality(PreviewQuality quality) => _todo();

  @override
  Future<void> setUseProxies(bool on) => _todo();

  @override
  Future<void> setEditingMode(PreviewEditingMode mode) => _todo();

  @override
  Future<void> showSourceFrame(EngineMedia media, TimeUs sourceTime) => _todo();

  @override
  Future<Color?> sampleColor(ItemId item, Offset normalizedSourcePoint) => _todo();

  @override
  Future<List<Uint8List>> renderLookStills(ItemId item, List<LookSpec> looks, {required int heightPx}) => _todo();

  @override
  Future<void> refresh() => _todo();

  @override
  Future<Uint8List> debugCaptureFrame() => _todo();

  @override
  Stream<PreviewClock> get clock => _todo();

  @override
  Stream<PreviewEvent> get events => _todo();

  @override
  Future<void> dispose() => _todo();
}
