// OWNER: CORE-24
//
// Placeholder (D-33) for the store filesystem abstraction (ARCH §8.3): `StoreFs`,
// `LocalStoreFs` and `FaultInjectingFs` are implemented by CORE-24. The typed store failure is
// declared here by the scaffold because the repository contract (CORE-25) and the editor's
// `SaveStatus.failed(StoreFailure)` (UX-08) refer to it.

import 'package:meta/meta.dart';

/// Kinds of persistence failure (ARCH §19).
enum StoreFailureKind {
  /// Not enough free space.
  diskFull,

  /// The OS refused access.
  permissionDenied,

  /// The file or project does not exist.
  notFound,

  /// No valid copy could be read (checksum mismatch everywhere).
  corrupt,

  /// Written by a newer app whose `minReader` is above this app's schema (D-12).
  newerSchema,

  /// The project is already open in this process.
  busy,

  /// Any other I/O error.
  io,
}

/// A typed persistence failure. [debugDetail] never contains paths or user content.
@immutable
final class StoreFailure implements Exception {
  /// Creates a failure.
  const StoreFailure(this.kind, [this.debugDetail = '']);

  /// Kind.
  final StoreFailureKind kind;

  /// Diagnostic text without paths.
  final String debugDetail;

  @override
  bool operator ==(Object other) => other is StoreFailure && other.kind == kind && other.debugDetail == debugDetail;

  @override
  int get hashCode => Object.hash(kind, debugDetail);

  @override
  String toString() => 'StoreFailure(${kind.name}${debugDetail.isEmpty ? '' : ': $debugDetail'})';
}
