// OWNER: API-02
//
// Placeholder (D-33, created by API-01). API-02 implements plan transport: UTF-8 JSON encoding of
// plans, patches and transients in an isolate (`PlanJson`, core) for the Pigeon control API
// (ARCH §11.1 rule 4). Only the declared public names exist here; every member throws
// `UnimplementedError`.

import 'dart:typed_data';

import 'package:vwish_editor_core/plan.dart';

/// Encodes plan payloads for the platform channel (ARCH §11.1, API-02).
abstract final class PlanTransport {
  /// UTF-8 JSON of [plan]; encoded in an isolate above a size threshold (API-02).
  static Future<Uint8List> encodePlan(RenderPlan plan) => throw UnimplementedError('PlanTransport is implemented by API-02');

  /// UTF-8 JSON of [patch] (API-02).
  static Future<Uint8List> encodePatch(RenderPlanPatch patch) => throw UnimplementedError('PlanTransport is implemented by API-02');

  /// UTF-8 JSON of [transient] (API-02).
  static Uint8List encodeTransient(PlanTransient transient) => throw UnimplementedError('PlanTransport is implemented by API-02');
}
