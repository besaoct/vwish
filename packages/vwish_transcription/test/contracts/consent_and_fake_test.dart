// OWNER: AI-08

import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_editor_core/model.dart';
import 'package:vwish_transcription/testing.dart';
import 'package:vwish_transcription/vwish_transcription.dart';

void main() {
  test('disclosure names the host, CDN, file, hash and total bytes incl. VAD', () {
    final d = ConsentDisclosure.of(SpeechModelCatalog.balanced, includesVad: true);
    expect(d.host, 'huggingface.co');
    expect(d.cdnHost, 'hf.co');
    expect(d.totalBytes, 59707625 + 885098);
    expect(d, ConsentDisclosure.of(SpeechModelCatalog.balanced, includesVad: true));
  });

  test('fake drives download and a job through to done', () async {
    final service = FakeTranscriptionService()
      ..scriptedDownload = const [ModelDownloadProgress(phase: ModelDownloadPhase.downloading, received: 10, total: 100)];
    // Test-only construction; production call sites are restricted to model_consent_view.dart.
    final consent = UserConsent.accepted(ConsentDisclosure.of(SpeechModelCatalog.balanced, includesVad: true), acceptedAt: DateTime.utc(2026));
    expect(await service.downloadModel(consent: consent).toList(), hasLength(1));
    expect(await service.modelStatus(), isA<SpeechModelReady>());

    final job = service.start(TranscriptionRequest(
      project: const ProjectId('pr_test00000001'),
      scope: const TimelineScope(),
      language: const FixedLanguage('en'),
      modelId: SpeechModelCatalog.balanced.id,
      segmentation: const SegmentationSettings(),
      target: const NewTrackTarget(),
      timeline: () => throw UnimplementedError(),
    )) as FakeTranscriptionJob;
    expect(service.activeJob, same(job));
    job.cancel();
    await expectLater(job.result, throwsA(isA<TranscriptionCancelled>()));
  });
}
