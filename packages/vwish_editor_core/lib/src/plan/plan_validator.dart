// OWNER: CORE-29
//
// RenderPlan invariants (ARCH §11.3). Native validators mirror these; a violation natively is
// `planInvalid` (a bug: logged with the layer id, preview shows the last good frame).

import 'package:meta/meta.dart';

import '../time/time.dart';
import 'render_plan.dart';

/// Kinds of plan invariant violations.
enum PlanViolationCode {
  /// `v` is not 1.
  version,

  /// Canvas size or rates are invalid.
  canvas,

  /// `durUs` is negative or off the grid.
  duration,

  /// Two layers or two audio segments share an id.
  duplicateId,

  /// A referenced asset is missing or has an incompatible kind.
  asset,

  /// `t0 < t1 ≤ durUs` does not hold.
  range,

  /// A layer edge, map breakpoint or audio edge is off the `canvas.gridFps` grid (D-35).
  offGrid,

  /// A map is empty, not contiguous over `t`, or has a rate outside [0.1, 10].
  map,

  /// A media layer has no `seq`, a non-media layer has one, or two layers sharing a `seq` overlap.
  seq,

  /// Layers or audio segments are not sorted.
  order,

  /// Animation keys are unsorted, duplicated or on an unknown channel; `reveal` is misplaced.
  anim,

  /// A value is outside its range.
  value,

  /// `z` outside the four bands, or more than two layers overlap within one `z`.
  zBand,

  /// Audio gain envelope is empty or negative/above 2.
  gain,
}

/// One violation, naming the offending layer or segment id when there is one.
@immutable
final class PlanViolation {
  /// Creates a violation.
  const PlanViolation(this.code, this.message, {this.id});

  /// Kind.
  final PlanViolationCode code;

  /// Human-readable detail (no paths).
  final String message;

  /// Layer, segment or asset id, when applicable.
  final String? id;

  @override
  String toString() => 'PlanViolation(${code.name}${id == null ? '' : ' $id'}: $message)';
}

/// Validates RenderPlans against ARCH §11.3.
abstract final class PlanValidator {
  static const double _minRate = 0.1;
  static const double _maxRate = 10;
  static const double _rateEps = 1e-6;
  static const Set<int> _rates = {24, 25, 30, 48, 50, 60};

  /// All violations of [plan] (empty when valid).
  static List<PlanViolation> validate(RenderPlan plan) {
    final out = <PlanViolation>[];
    void add(PlanViolationCode c, String m, [String? id]) => out.add(PlanViolation(c, m, id: id));

    if (plan.v != renderPlanVersion) add(PlanViolationCode.version, 'v must be $renderPlanVersion');
    final c = plan.canvas;
    if (c.w < 16 || c.h < 16 || c.w.isOdd || c.h.isOdd) add(PlanViolationCode.canvas, 'w/h must be even and ≥ 16');
    if (!_rates.contains(c.fps) || !_rates.contains(c.gridFps)) add(PlanViolationCode.canvas, 'fps and gridFps must be integer v1 rates');
    final grid = FrameRate(c.gridFps <= 0 ? 30 : c.gridFps, 1);
    bool onGrid(TimeUs t) => grid.isOnGrid(t);
    if (plan.durUs < 0 || !onGrid(plan.durUs)) add(PlanViolationCode.duration, 'durUs must be ≥ 0 and on the gridFps grid');

    // Layers.
    final ids = <String>{};
    final bySeq = <int, List<PlanLayer>>{};
    final byZ = <int, List<PlanLayer>>{};
    PlanLayer? prev;
    for (final l in plan.layers) {
      if (!ids.add(l.id)) add(PlanViolationCode.duplicateId, 'duplicate layer id', l.id);
      if (prev != null && _compareLayers(prev, l) > 0) add(PlanViolationCode.order, 'layers must be sorted by (z, t0, id)', l.id);
      prev = l;
      if (!(l.t0 < l.t1) || l.t0 < 0 || l.t1 > plan.durUs) add(PlanViolationCode.range, 'needs 0 ≤ t0 < t1 ≤ durUs', l.id);
      if (!onGrid(l.t0) || !onGrid(l.t1)) add(PlanViolationCode.offGrid, 'layer edges must lie on the gridFps grid', l.id);
      if (l.z < 0 || l.z >= 40000) add(PlanViolationCode.zBand, 'z outside the four bands', l.id);
      (byZ[l.z] ??= []).add(l);

      final assetKind = l.asset == null ? null : plan.assets[l.asset]?.kind;
      switch (l.kind) {
        case PlanLayerKind.media:
          if (assetKind != PlanAssetKind.video) add(PlanViolationCode.asset, 'media layers need a video asset', l.id);
          if (l.seq == null || l.seq! < 0) {
            add(PlanViolationCode.seq, 'media layers need seq ≥ 0', l.id);
          } else {
            (bySeq[l.seq!] ??= []).add(l);
          }
          _checkMap(l.map, l.t0, l.t1, onGrid, (m) => add(PlanViolationCode.map, m, l.id), (m) => add(PlanViolationCode.offGrid, m, l.id));
        case PlanLayerKind.image:
          if (assetKind != PlanAssetKind.image) add(PlanViolationCode.asset, 'image layers need an image asset', l.id);
          if (l.seq != null) add(PlanViolationCode.seq, 'only media layers carry seq', l.id);
        case PlanLayerKind.sprite:
          if (assetKind != PlanAssetKind.sprite) add(PlanViolationCode.asset, 'sprite layers need a sprite asset', l.id);
          if (l.seq != null) add(PlanViolationCode.seq, 'only media layers carry seq', l.id);
        case PlanLayerKind.solid:
          if (l.color == null) add(PlanViolationCode.value, 'solid layers need a color', l.id);
          if (l.seq != null) add(PlanViolationCode.seq, 'only media layers carry seq', l.id);
      }
      if (l.kind != PlanLayerKind.media && (l.map.isNotEmpty || l.hold)) {
        add(PlanViolationCode.map, 'map/hold only on media layers', l.id);
      }
      final lut = l.fx.lut;
      if (lut != null && plan.assets[lut.asset]?.kind != PlanAssetKind.lut) add(PlanViolationCode.asset, 'lut asset missing', l.id);
      _checkValues(l, (m) => add(PlanViolationCode.value, m, l.id));
      for (final e in l.anim.entries) {
        if (!PlanChannels.all.contains(e.key)) add(PlanViolationCode.anim, 'unknown channel ${e.key}', l.id);
        if (!_sortedUnique(e.value)) add(PlanViolationCode.anim, 'keys of ${e.key} must be sorted and unique', l.id);
      }
      if (l.anim.containsKey(PlanChannels.reveal)) {
        final ok = l.kind == PlanLayerKind.sprite && plan.assets[l.asset]?.reveal == true;
        if (!ok) add(PlanViolationCode.anim, 'reveal only on sprites whose asset has reveal: true', l.id);
      }
      for (final m in l.cmasks) {
        for (final e in m.anim.entries) {
          if (!PlanChannels.canvasMask.contains(e.key) || !_sortedUnique(e.value)) {
            add(PlanViolationCode.anim, 'invalid canvas-mask channel ${e.key}', l.id);
          }
        }
      }
    }

    // Packing slots never overlap (CORE-36).
    for (final slot in bySeq.values) {
      final sorted = [...slot]..sort((a, b) => a.t0.compareTo(b.t0));
      for (var i = 1; i < sorted.length; i++) {
        if (sorted[i].t0 < sorted[i - 1].t1) {
          add(PlanViolationCode.seq, 'overlaps ${sorted[i - 1].id} in seq ${sorted[i].seq}', sorted[i].id);
        }
      }
    }
    // Within one z, at most two layers at once (lowered transition windows).
    for (final group in byZ.values) {
      final events = <(TimeUs, int, String)>[];
      for (final l in group) {
        events
          ..add((l.t0, 1, l.id))
          ..add((l.t1, -1, l.id));
      }
      events.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
      var active = 0;
      for (final e in events) {
        active += e.$2;
        if (active > 2) {
          add(PlanViolationCode.zBand, 'more than two layers overlap within one z', e.$3);
          break;
        }
      }
    }

    // Audio.
    final audioIds = <String>{};
    AudioSeg? prevA;
    for (final a in plan.audio) {
      if (!audioIds.add(a.id)) add(PlanViolationCode.duplicateId, 'duplicate audio id', a.id);
      if (prevA != null && (prevA.t0 > a.t0 || (prevA.t0 == a.t0 && prevA.id.compareTo(a.id) > 0))) {
        add(PlanViolationCode.order, 'audio must be sorted by (t0, id)', a.id);
      }
      prevA = a;
      final kind = plan.assets[a.asset]?.kind;
      if (kind != PlanAssetKind.audio && kind != PlanAssetKind.video) add(PlanViolationCode.asset, 'audio needs an audio or video asset', a.id);
      if (!(a.t0 < a.t1) || a.t0 < 0 || a.t1 > plan.durUs) add(PlanViolationCode.range, 'needs 0 ≤ t0 < t1 ≤ durUs', a.id);
      if (!onGrid(a.t0) || !onGrid(a.t1)) add(PlanViolationCode.offGrid, 'audio edges must lie on the gridFps grid', a.id);
      _checkMap(a.map, a.t0, a.t1, onGrid, (m) => add(PlanViolationCode.map, m, a.id), (m) => add(PlanViolationCode.offGrid, m, a.id));
      if (a.gain.isEmpty) add(PlanViolationCode.gain, 'gain needs at least one key', a.id);
      if (a.gain.any((k) => k.v < 0 || k.v > 2)) add(PlanViolationCode.gain, 'gain values must be in [0, 2]', a.id);
      if (!_sortedUnique(a.gain)) add(PlanViolationCode.gain, 'gain keys must be sorted and unique', a.id);
    }
    return out;
  }

  static int _compareLayers(PlanLayer a, PlanLayer b) {
    if (a.z != b.z) return a.z.compareTo(b.z);
    if (a.t0 != b.t0) return a.t0.compareTo(b.t0);
    return a.id.compareTo(b.id);
  }

  static bool _sortedUnique(List<AnimKey> keys) {
    for (var i = 1; i < keys.length; i++) {
      if (keys[i].tUs <= keys[i - 1].tUs) return false;
    }
    return true;
  }

  static void _checkMap(List<MapSegment> map, TimeUs t0, TimeUs t1, bool Function(TimeUs) onGrid,
      void Function(String) bad, void Function(String) offGrid) {
    if (map.isEmpty) {
      bad('map must cover [t0, t1)');
      return;
    }
    if (map.first.t0 != t0 || map.last.t1 != t1) bad('map must start at t0 and end at t1');
    for (var i = 0; i < map.length; i++) {
      final s = map[i];
      if (i > 0 && s.t0 != map[i - 1].t1) bad('map segments must be contiguous');
      if (!onGrid(s.t0) || !onGrid(s.t1)) offGrid('map breakpoints must lie on the gridFps grid');
      final r = s.rate;
      if (r < _minRate - _rateEps || r > _maxRate + _rateEps) bad('segment rate $r outside [0.1, 10]');
    }
  }

  static void _checkValues(PlanLayer l, void Function(String) bad) {
    bool unit(double v) => v >= 0 && v <= 1;
    if (!unit(l.xf.op)) bad('xf.op outside [0, 1]');
    final adj = l.fx.adj;
    if (adj != null && adj.values.any((v) => v < -1 || v > 1)) bad('adj values outside [-1, 1]');
    final d = l.fx.detail;
    if (d != null && !(unit(d.sharpen) && unit(d.blur) && unit(d.vignette))) bad('detail values outside [0, 1]');
    final lut = l.fx.lut;
    if (lut != null && !unit(lut.i)) bad('lut.i outside [0, 1]');
    final ch = l.fx.chroma;
    if (ch != null && !(unit(ch.sim) && unit(ch.smooth) && unit(ch.spill))) bad('chroma values outside [0, 1]');
    final m = l.fx.mask;
    if (m != null && !(unit(m.feather) && unit(m.op) && m.corner >= 0 && m.corner <= 0.5)) bad('mask values out of range');
    final c = l.crop;
    if (!(unit(c.l) && unit(c.t) && unit(c.r) && unit(c.b) && c.l < c.r && c.t < c.b)) bad('crop must satisfy 0 ≤ l < r ≤ 1, 0 ≤ t < b ≤ 1');
  }
}
