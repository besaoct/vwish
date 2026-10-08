// OWNER: CORE-24
//
// Placeholder (D-33) for the only code that writes into `Documents` (D-44, ARCH §9.6, §14.1
// step 6 "Keep a copy in Vwish"). CORE-24 implements it with these rules:
// - target directory `Documents/Exports/` only (`StoreRoots.documentsExportsDir`);
// - exclusive create, never overwrite; `'<name> (2).mp4'` naming reusing the vwish_data
//   `LibraryStorage._uniqueTarget` scheme;
// - refuses symlinked targets or parents;
// - the source is an app-owned export under `<cache>/vwish/editor/work/`.

import 'store_roots.dart';

/// Copies a finished export into `Documents/Exports/` without ever overwriting (D-44).
final class DocumentsExportWriter {
  /// Creates a writer for [roots].
  DocumentsExportWriter(this.roots);

  /// App roots.
  final StoreRoots roots;

  /// Copies [sourcePath] to a new, uniquely named file `Documents/Exports/<fileName>` and returns
  /// its absolute path. Implemented by CORE-24.
  Future<String> keepCopy(String sourcePath, {required String fileName}) =>
      throw UnimplementedError('DocumentsExportWriter is implemented by CORE-24');
}
