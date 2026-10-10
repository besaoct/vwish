// OWNER: ENG-04
//
// Placeholder (D-33, created by ENG-01). ENG-04 replaces the bodies: MobileExportService
// implements ExportService over ExportHostApi (ARCH §12.4, §14, D-22, D-39): preflight,
// start(…, whenDetached), resume, activeJobs reattaching running jobs and reporting one-shot
// interrupted / resumable / completedWhileDetached records (`exportJobStateFromMsg`),
// consumeJobRecord; progress (<= 4 Hz) and results from `channels.router.job(jobId)`. Only the
// declared public names exist here; every member throws `UnimplementedError`.

import 'package:vwish_editor_engine_api/vwish_editor_engine_api.dart';

import 'pigeon/engine_channels.dart';

Never _todo() => throw UnimplementedError('MobileExportService is implemented by ENG-04');

/// Export over `ExportHostApi` (ARCH §12.4, §14, ENG-04).
final class MobileExportService implements ExportService {
  /// Creates the export service.
  MobileExportService(EngineChannels channels);

  @override
  Future<ExportPreflight> preflight(RenderPlan plan, EncodeSettings settings) => _todo();

  @override
  Future<ExportJob> start(
    RenderPlan plan,
    EncodeSettings settings, {
    required String outputPath,
    required String title,
    ExportDetachedHandoff whenDetached = ExportDetachedHandoff.saveToGallery,
  }) =>
      _todo();

  @override
  Future<ExportJob> resume(String jobId) => _todo();

  @override
  Future<List<ExportJobState>> activeJobs() => _todo();

  @override
  Future<void> consumeJobRecord(String jobId) => _todo();
}
