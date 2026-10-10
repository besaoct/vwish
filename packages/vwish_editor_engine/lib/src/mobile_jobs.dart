// OWNER: ENG-03
//
// Placeholder (D-33, created by ENG-01). ENG-03 replaces the bodies (ARCH §12.3, §15):
// MobileThumbnailSource (requestId, priority, cancel, <= 8 tiles in flight), MobileWaveformSource
// and MobileMediaJobs over JobsHostApi (startJob / cancelJob / setJobPriority, progress and typed
// results from `channels.router.job(jobId)`, proxyStatus). Only the declared public names exist
// here; every member throws `UnimplementedError`.

import 'package:vwish_editor_core/model.dart' show TimeRange, TimeUs;
import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

import 'pigeon/engine_channels.dart';

Never _todo(String type) => throw UnimplementedError('$type is implemented by ENG-03');

/// Thumbnail strips over `JobsHostApi.thumbnailTile` (ARCH §12.3, ENG-03).
final class MobileThumbnailSource implements ThumbnailSource {
  /// Creates the source.
  MobileThumbnailSource(EngineChannels channels);

  @override
  ThumbnailHandle request(ThumbnailRequest request, {required ThumbPriority priority}) => _todo('MobileThumbnailSource');
}

/// Waveform peaks over `JobsHostApi.startJob(waveform)` (ARCH §12.3, ENG-03).
final class MobileWaveformSource implements WaveformSource {
  /// Creates the source.
  MobileWaveformSource(EngineChannels channels);

  @override
  MediaJob<WaveformPeaks> peaks(EngineMedia media, {int audioStream = 0}) => _todo('MobileWaveformSource');
}

/// Proxies, reverse renditions, freeze stills and speech audio over `JobsHostApi`
/// (ARCH §12.3, ENG-03).
final class MobileMediaJobs implements MediaJobs {
  /// Creates the jobs service.
  MobileMediaJobs(EngineChannels channels);

  @override
  MediaJob<GeneratedAsset> proxy(EngineMedia media) => _todo('MobileMediaJobs');

  @override
  MediaJob<GeneratedAsset> reverse(EngineMedia media, TimeRange source, {required String outputPath}) => _todo('MobileMediaJobs');

  @override
  MediaJob<GeneratedAsset> freezeFrame(EngineMedia media, TimeUs sourceTime, {required String outputPath}) => _todo('MobileMediaJobs');

  @override
  MediaJob<ExtractedSpeechAudio> extractSpeechAudio(SpeechAudioJobRequest request) => _todo('MobileMediaJobs');

  @override
  ProxyStatus proxyStatus(EngineMedia media) => _todo('MobileMediaJobs');
}
