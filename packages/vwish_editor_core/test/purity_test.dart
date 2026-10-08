// OWNER: CORE-01
//
// ARCH §4.2 rule 2: vwish_editor_core depends on no Flutter or vwish_* package, and uses dart:io /
// dart:isolate only under lib/src/store/.

import 'dart:io';

import 'package:test/test.dart';

/// Violations in one source file (path relative to the package root, `/`-separated).
List<String> purityViolations(String relPath, String source) {
  final out = <String>[];
  final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
  final inStore = relPath.startsWith('lib/src/store/') || relPath == 'lib/store.dart';
  for (final m in directive.allMatches(source)) {
    final uri = m[1]!;
    if (uri.startsWith('package:flutter')) out.add('$relPath imports $uri');
    if (uri.startsWith('package:vwish_') && !uri.startsWith('package:vwish_editor_core/')) out.add('$relPath imports $uri');
    if ((uri == 'dart:io' || uri == 'dart:isolate') && !inStore) out.add('$relPath imports $uri outside lib/src/store/');
  }
  return out;
}

void main() {
  test('lib/ is pure', () {
    final violations = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final rel = f.path.replaceAll(r'\', '/');
      violations.addAll(purityViolations(rel, f.readAsStringSync()));
    }
    expect(violations, isEmpty);
  });

  group('scanner catches negative fixtures', () {
    test('flutter import', () => expect(purityViolations('lib/src/model/x.dart', "import 'package:flutter/widgets.dart';"), hasLength(1)));
    test('vwish_* import', () => expect(purityViolations('lib/src/ops/x.dart', "import 'package:vwish_data/vwish_data.dart';"), hasLength(1)));
    test('dart:io outside store', () => expect(purityViolations('lib/src/plan/x.dart', "import 'dart:io';"), hasLength(1)));
    test('dart:isolate outside store', () => expect(purityViolations('lib/src/eval/x.dart', 'import "dart:isolate";'), hasLength(1)));
    test('dart:io inside store is allowed', () => expect(purityViolations('lib/src/store/x.dart', "import 'dart:io';"), isEmpty));
    test('self import is allowed', () => expect(purityViolations('lib/x.dart', "export 'package:vwish_editor_core/model.dart';"), isEmpty));
  });
}
