// IOS-01 / V-N23 spike: preview A/V latency through a Flutter Texture on iOS.
//
// Phase 1 plays with no compensation and measures the texture latency (display time of the
// raster that sampled a texture frame minus the display-link target time it was fetched for).
// Phase 2 applies that latency as `targetTimestamp + compensation` (ARCH §12.7) and measures the
// remaining A/V offset. Results are printed by the native side as `VWSPIKE-METRIC {json}`.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _channel = MethodChannel('vw.spike/latency');

void main() {
  runApp(const LatencyApp());
}

class LatencyApp extends StatefulWidget {
  const LatencyApp({super.key});

  @override
  State<LatencyApp> createState() => _LatencyAppState();
}

class _LatencyAppState extends State<LatencyApp> {
  int? _textureId;
  String _status = 'starting';
  final List<FrameTiming> _timings = [];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
    unawaited(_run());
  }

  List<List<int>> _drain() {
    final out = _timings
        .map((t) => [
              t.timestampInMicroseconds(FramePhase.vsyncStart),
              t.timestampInMicroseconds(FramePhase.rasterStart),
              t.timestampInMicroseconds(FramePhase.rasterFinish),
            ])
        .toList();
    _timings.clear();
    return out;
  }

  Future<void> _run() async {
    final id = await _channel.invokeMethod<int>('start');
    setState(() {
      _textureId = id;
      _status = 'phase 1 (no compensation)';
    });
    // Warm-up (decoder start, first frames): reported separately and discarded.
    await Future<void>.delayed(const Duration(seconds: 4));
    await _channel.invokeMethod<Object?>('report', {'phase': 'warmup', 'timings': _drain()});
    await Future<void>.delayed(const Duration(seconds: 5));
    final r1 = Map<String, Object?>.from(await _channel.invokeMethod<Map<Object?, Object?>>(
            'report', {'phase': 'uncompensated', 'timings': _drain()}) ??
        {});
    final latency = (r1['textureLatencyMsP50'] as num?)?.toDouble() ?? 0;
    // Re-arm with the measured latency, then measure again.
    await _channel.invokeMethod<Object?>(
        'report', {'phase': 'rearm', 'timings': _drain(), 'nextCompensationMs': latency});
    setState(() => _status = 'phase 2 (compensation $latency ms)');
    await Future<void>.delayed(const Duration(seconds: 5));
    await _channel.invokeMethod<Object?>(
        'report', {'phase': 'compensated', 'timings': _drain()});
    setState(() => _status = 'done');
    await _channel.invokeMethod<Object?>('exit');
  }

  @override
  Widget build(BuildContext context) {
    final id = _textureId;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF101014),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: id == null ? const SizedBox() : Texture(textureId: id),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status, style: const TextStyle(color: Color(0xFFFFFFFF))),
            ),
          ],
        ),
      ),
    );
  }
}
