// OWNER: CORE-08
//
// Placeholder (D-33). CORE-08 replaces this sub-barrel with the validator and `repair()` of
// ARCH §6.9 (invariants I1–I9). `ProjectOpenWarning` is declared here by the scaffold because the
// repository contract (`LoadedProject.warnings`, CORE-25) refers to it.

import 'package:meta/meta.dart';

/// Something `repair()` fixed or an unknown value met while opening a project (never fatal).
@immutable
final class ProjectOpenWarning {
  /// Creates a warning with a stable [code] and a message without paths or user content.
  const ProjectOpenWarning(this.code, [this.message = '']);

  /// Stable code (e.g. `unknownEnum`, `overlapRepaired`, `offGridSnapped`).
  final String code;

  /// Diagnostic detail.
  final String message;

  @override
  bool operator ==(Object other) => other is ProjectOpenWarning && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);
}
