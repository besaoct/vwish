// OWNER: UX-07
//
// Placeholder (D-33) created by UX-01. UX-07 replaces this file:
// EditorScope, the InheritedWidget that supplies the ProjectId (ARCH §17.3).
// Until then it declares only the public names other files compile against.

import 'package:flutter/widgets.dart';
import 'package:vwish_editor_core/model.dart' show ProjectId;

/// Supplies the open project's id to the editor's widgets (ARCH §17.3).
class EditorScope extends InheritedWidget {
  /// Creates the scope.
  const EditorScope({super.key, required this.projectId, required super.child});

  /// The open project.
  final ProjectId projectId;

  /// The id of the nearest scope, or null.
  static ProjectId? maybeIdOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<EditorScope>()?.projectId;

  /// The id of the nearest scope.
  static ProjectId idOf(BuildContext context) {
    final id = maybeIdOf(context);
    assert(id != null, 'EditorScope.idOf called outside an editor');
    return id!;
  }

  @override
  bool updateShouldNotify(EditorScope oldWidget) => oldWidget.projectId != projectId;
}
