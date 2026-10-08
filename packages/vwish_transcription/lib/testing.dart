// OWNER: AI-08
//
// FakeTranscriptionService: scriptable phases, failures, download progress and resumable jobs
// for widget tests (UX-37, UX-38) and the INT-04 wiring tests.

library;

import 'dart:async';

import 'package:vwish_editor_core/model.dart';

import 'vwish_transcription.dart';

/// A job the test drives with [emit], [finish] and [fail].
final class FakeTranscriptionJob implements TranscriptionJob {
  /// Creates a job.
  FakeTranscriptionJob(this.id, this.request);

  @override
  final String id;

  /// The request it was started with.
  final TranscriptionRequest request;

  final StreamController<TranscriptionProgress> _progress = StreamController<TranscriptionProgress>.broadcast();
  final Completer<TranscriptionResult> _result = Completer<TranscriptionResult>();

  /// Language codes provided by the UI.
  final List<String> providedLanguages = [];

  /// Whether [cancel] was called.
  bool cancelled = false;

  @override
  Stream<TranscriptionProgress> get progress => _progress.stream;

  @override
  Future<TranscriptionResult> get result => _result.future;

  /// Emits a progress sample.
  void emit(TranscriptionProgress p) => _progress.add(p);

  /// Completes with [result].
  void finish(TranscriptionResult result) {
    if (!_result.isCompleted) _result.complete(result);
    unawaited(_progress.close());
  }

  /// Fails with [failure].
  void fail(TranscriptionFailure failure) {
    if (!_result.isCompleted) _result.completeError(failure);
    unawaited(_progress.close());
  }

  @override
  void cancel() {
    cancelled = true;
    fail(const TranscriptionCancelled());
  }

  @override
  void provideLanguage(String code) => providedLanguages.add(code);
}

/// A scriptable [TranscriptionService].
final class FakeTranscriptionService implements TranscriptionService {
  /// Creates the fake (supported, Balanced recommended, nothing installed).
  FakeTranscriptionService({
    this.supportState = const TranscriptionSupported([SpeechModelTier.fast, SpeechModelTier.balanced, SpeechModelTier.accurate]),
  });

  /// Reported support.
  TranscriptionSupport supportState;

  /// Status per model id (missing when absent).
  final Map<String, SpeechModelStatus> statuses = {};

  /// Progress samples [downloadModel] emits before marking the model ready.
  List<ModelDownloadProgress> scriptedDownload = const [];

  /// Failure [downloadModel] ends with instead of succeeding.
  TranscriptionFailure? downloadFailure;

  /// Consents received (the call site is restricted in production code).
  final List<UserConsent> consents = [];

  /// Jobs started.
  final List<FakeTranscriptionJob> jobs = [];

  /// Resumable jobs by project.
  final Map<ProjectId, ResumableTranscription> resumable = {};

  /// Drafts [resegment] returns.
  List<SubtitleCueDraft> resegmentDrafts = const [];

  final StreamController<TranscriptionEvent> _events = StreamController<TranscriptionEvent>.broadcast();
  var _n = 0;

  @override
  List<TranscriptionLanguage> get languages => whisperLanguages;

  @override
  Future<TranscriptionSupport> support() async => supportState;

  @override
  List<SpeechModelOffer> get offers => [
        for (final m in SpeechModelCatalog.models)
          SpeechModelOffer(spec: m, available: true, recommended: m.tier == SpeechModelTier.balanced),
      ];

  @override
  SpeechModelSpec get defaultModel => SpeechModelCatalog.balanced;

  @override
  Future<SpeechModelStatus> modelStatus() => modelStatusOf(defaultModel.id);

  @override
  Future<SpeechModelStatus> modelStatusOf(String modelId) async => statuses[modelId] ?? const SpeechModelMissing();

  @override
  Stream<ModelDownloadProgress> downloadModel({required UserConsent consent}) async* {
    consents.add(consent);
    for (final p in scriptedDownload) {
      statuses[consent.disclosure.modelId] = SpeechModelDownloading(p);
      yield p;
    }
    final failure = downloadFailure;
    if (failure != null) throw failure;
    final spec = SpeechModelCatalog.byId(consent.disclosure.modelId)!;
    final ready = SpeechModelReady(InstalledSpeechModel(spec: spec, installedAt: DateTime.utc(2026)));
    statuses[spec.id] = ready;
    _events.add(ModelStatusChanged(spec.id, ready));
  }

  @override
  Future<void> cancelDownload() async {}

  @override
  Future<void> deleteModel() async {
    statuses.clear();
  }

  @override
  Future<void> deleteModelById(String modelId) async {
    statuses.remove(modelId);
  }

  @override
  Future<TranscriptionPreflight> preflight(TranscriptionRequest request) async =>
      TranscriptionPreflight(ok: true, downloadBytes: statuses[request.modelId] is SpeechModelReady ? 0 : defaultModel.bytes);

  @override
  TranscriptionJob start(TranscriptionRequest request) {
    final job = FakeTranscriptionJob('tj-${_n++}', request);
    jobs.add(job);
    _events.add(JobStarted(job));
    unawaited(job.result.then((_) {}, onError: (_) {}).whenComplete(() => _events.add(JobEnded(job.id))));
    return job;
  }

  @override
  Future<List<SubtitleCueDraft>> resegment(CaptionProvenance provenance, SegmentationSettings settings, TimelineView timeline) async =>
      resegmentDrafts;

  @override
  TranscriptionJob? get activeJob {
    for (final j in jobs.reversed) {
      if (!j.cancelled) return j;
    }
    return null;
  }

  @override
  Future<ResumableTranscription?> resumableFor(ProjectId project) async => resumable[project];

  @override
  Future<SpeechStorageUsage> storage() async => SpeechStorageUsage(
        modelBytes: statuses.values.whereType<SpeechModelReady>().fold(0, (a, s) => a + s.model.spec.bytes),
      );

  @override
  Stream<TranscriptionEvent> get events => _events.stream;
}
