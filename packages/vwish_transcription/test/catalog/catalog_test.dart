// OWNER: AI-08

import 'package:flutter_test/flutter_test.dart';
import 'package:vwish_transcription/vwish_transcription.dart';

void main() {
  test('pinned catalog matches ARCH §16.2', () {
    expect(SpeechModelCatalog.fast.bytes, 32152673);
    expect(SpeechModelCatalog.balanced.bytes, 59707625);
    expect(SpeechModelCatalog.accurate.bytes, 190085487);
    expect(SpeechModelCatalog.vad.bytes, 885098);
    for (final m in [...SpeechModelCatalog.models, SpeechModelCatalog.vad]) {
      expect(m.host, SpeechModelCatalog.host);
      expect(m.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(m.url, endsWith(m.fileName));
    }
  });

  test('tier gating: Accurate hidden below 4 GB, Fast only on low-RAM devices, nothing on 32-bit', () {
    const gib = 1024 * 1024 * 1024;
    expect(SpeechModelCatalog.availableTiers(physicalRamBytes: 3 * gib, is64Bit: true), [SpeechModelTier.fast, SpeechModelTier.balanced]);
    expect(SpeechModelCatalog.availableTiers(physicalRamBytes: 6 * gib, is64Bit: true), hasLength(3));
    expect(SpeechModelCatalog.availableTiers(physicalRamBytes: 6 * gib, is64Bit: true, isLowRamDevice: true), [SpeechModelTier.fast]);
    expect(SpeechModelCatalog.availableTiers(physicalRamBytes: 6 * gib, is64Bit: false), isEmpty);
    expect(SpeechModelCatalog.recommendedTier(physicalRamBytes: 2 * gib), SpeechModelTier.fast);
    expect(SpeechModelCatalog.recommendedTier(physicalRamBytes: 4 * gib), SpeechModelTier.balanced);
  });

  test('99 languages, unique codes, no yue, jw maps to jv, RTL set', () {
    expect(whisperLanguages, hasLength(99));
    expect(whisperLanguages.map((l) => l.whisperCode).toSet(), hasLength(99));
    expect(languageForWhisperCode('yue'), isNull);
    expect(languageForWhisperCode('jw')!.bcp47, 'jv');
    expect(whisperLanguages.where((l) => l.rtl).map((l) => l.whisperCode).toSet(), {'ar', 'fa', 'ur', 'he', 'yi', 'ps', 'sd'});
    expect(languageForLocale('pt-BR')!.whisperCode, 'pt');
    expect(languageForWhisperCode('ja')!.script, ScriptProfile.cjk);
  });
}
