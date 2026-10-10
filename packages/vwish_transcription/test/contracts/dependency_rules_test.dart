// OWNER: AI-08
//
// ARCH §4.2 rule 6: vwish_transcription is pure Dart logic. It may depend on vwish_editor_core,
// vwish_whisper and vwish_data only, never on the engine packages, vwish_editor, vwish_features or
// widget libraries.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _allowedVwish = {'vwish_editor_core', 'vwish_whisper', 'vwish_data'};
const _forbiddenFragments = ['vwish_editor_engine', 'vwish_engine', 'vwish_editor/', 'vwish_features', 'vwish_ui_kit', 'vwish_platform'];

void main() {
  final root = Directory.current.path.endsWith('vwish_transcription') ? Directory.current : Directory('packages/vwish_transcription');

  test('pubspec depends on no vwish package beyond core, whisper and data', () {
    final lines = File('${root.path}/pubspec.yaml').readAsLinesSync();
    final deps = <String>{};
    var inDeps = false;
    for (final l in lines) {
      if (RegExp(r'^\S').hasMatch(l)) inDeps = l.startsWith('dependencies:');
      final m = RegExp(r'^  (vwish_\w+):').firstMatch(l);
      if (inDeps && m != null) deps.add(m.group(1)!);
    }
    expect(deps, _allowedVwish);
  });

  test('lib/ imports only allowed packages and no widget or UI library', () {
    final files = Directory('${root.path}/lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    final importRe = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
    for (final f in files) {
      final isTesting = f.path.endsWith('lib/testing.dart');
      for (final m in importRe.allMatches(f.readAsStringSync())) {
        final uri = m.group(1)!;
        for (final bad in _forbiddenFragments) {
          expect(uri.contains(bad), isFalse, reason: '${f.path} imports $uri');
        }
        if (uri.startsWith('package:vwish_')) {
          final pkg = uri.substring('package:'.length).split('/').first;
          expect(_allowedVwish.contains(pkg) || pkg == 'vwish_transcription', isTrue, reason: '${f.path} imports $uri');
        }
        expect(uri.startsWith('package:flutter/'), isFalse, reason: '${f.path} imports Flutter UI: $uri (${isTesting ? 'testing' : 'lib'})');
      }
    }
  });
}
