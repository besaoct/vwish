// OWNER: API-01
//
// Pickers, file handoff, media access, background leases and external drops (ARCH §12.4, §9,
// §15, D-13, D-18, D-44).

import 'dart:ui' show Offset;

import 'package:meta/meta.dart';
import 'package:vwish_editor_core/model.dart';

/// Where to pick from.
enum MediaPickSource {
  /// iOS PHPicker / Android Photo Picker (no library permission).
  photos,

  /// iOS document picker / Android SAF.
  files,
}

/// What may be picked.
enum MediaPickKind {
  /// Videos.
  video,

  /// Audio files.
  audio,

  /// Images.
  image,

  /// `.cube` LUTs.
  lut,

  /// SRT / VTT files.
  subtitle,
}

/// A picker request.
@immutable
final class MediaPickRequest {
  /// Creates a request.
  const MediaPickRequest({required this.source, required this.kinds, this.multiple = true});

  /// Source.
  final MediaPickSource source;

  /// Allowed kinds.
  final Set<MediaPickKind> kinds;

  /// Multi-select.
  final bool multiple;
}

/// The system pickers. iOS Photos picks are cloned natively into `work/picks/` before the
/// completion handler returns (`PickedMedia.isTemporaryCopy`, ARCH §9.1).
abstract interface class MediaPicker {
  /// Shows the picker; an empty list means cancelled.
  Future<List<PickedMedia>> pick(MediaPickRequest request);
}

/// Outcome of a file handoff.
enum FileHandoffOutcome {
  /// Saved / shared.
  done,

  /// The user cancelled the system sheet.
  cancelled,

  /// Permission denied (Photos add).
  denied,

  /// Failed.
  failed,
}

/// Result of a file handoff.
@immutable
final class FileHandoffResult {
  /// Creates a result.
  const FileHandoffResult(this.outcome, {this.savedUri});

  /// Outcome.
  final FileHandoffOutcome outcome;

  /// Gallery local identifier / content URI, when saved.
  final String? savedUri;
}

/// Delivers an export to the user (Photos add-only, Files/SAF, share sheet).
abstract interface class FileHandoff {
  /// Adds the video to Photos / Gallery (`Movies/Vwish`).
  Future<FileHandoffResult> saveToPhotos(String path);

  /// Lets the user choose a location (document picker for export / `ACTION_CREATE_DOCUMENT`).
  Future<FileHandoffResult> saveToFiles(String path, String suggestedName);

  /// System share sheet.
  Future<FileHandoffResult> share(String path);
}

/// The engine's media access: core [MediaAccessPort] (bookmarks, URI grants, stat, hash,
/// `excludeFromBackup` refusing paths outside the editor roots, D-44) plus the notification
/// permission prompt used by background export on Android.
abstract interface class MediaAccess implements MediaAccessPort {
  /// Asks for `POST_NOTIFICATIONS` (Android 13+); true elsewhere.
  Future<bool> requestNotificationPermission();
}

/// A background-work lease (iOS `beginBackgroundTask`, Android FGS-hosted lease).
abstract interface class BackgroundLease {
  /// Lease id.
  String get id;

  /// Fires when the OS is about to expire the lease (iOS).
  Stream<void> get expiring;

  /// Releases the lease.
  Future<void> release();
}

/// Keeps work alive while the app is in the background.
abstract interface class BackgroundWorkGuard {
  /// Acquires a lease showing [title] and [progress]; null when not available.
  Future<BackgroundLease?> acquire({required String title, required Stream<double> progress});
}

/// Items dropped onto the app from another app (D-18). Items are already app-owned temporary
/// copies (`work/drops/`), imported as managed copies.
@immutable
final class ExternalDrop {
  /// Creates a drop.
  const ExternalDrop({required this.items, required this.position});

  /// Dropped items.
  final List<PickedMedia> items;

  /// Drop position in logical px relative to the Flutter view.
  final Offset position;
}

/// External drag-and-drop target (iPad/iPhone `UIDropInteraction`, Android `OnDragListener`).
abstract interface class ExternalDropTarget {
  /// Enables or disables accepting drops (enabled only while the editor is visible).
  Future<void> setEnabled(bool on);

  /// Drops.
  Stream<ExternalDrop> get drops;
}
