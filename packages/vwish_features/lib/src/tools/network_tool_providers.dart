import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vwish_data/vwish_data.dart';

/// The internet speed test; override with a fake in tests.
final speedTestServiceProvider = Provider<SpeedTestService>((ref) => SpeedTestService());

/// The stream link checker; override with a fake in tests.
final streamProbeProvider = Provider<StreamProbe>((ref) => StreamProbe());
