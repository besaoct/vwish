// OWNER: CORE-27
//
// The media pool service contract (ARCH §9.2, §9.3). CORE-27 implements import and the managed
// store; CORE-28 implements availability, relink (incl. `autoMatch` for "Relink several") and GC.
// The value types are declared here (by the scaffold) so both tickets share one contract.

import 'package:meta/meta.dart';

import '../ids/ids.dart';
import '../model/pool/media_asset.dart';
import '../model/pool/picked_media.dart';
import '../ops/outcome.dart';
import '../session/session.dart';

/// Where imported media should land on the timeline (null = bin only).
@immutable
final class ImportTarget {
  /// Creates a target.
  const ImportTarget({this.track, this.atUs, this.asOverlay = false});

  /// Preferred track, or null for the default lane of the media kind.
  final TrackId? track;

  /// Timeline time (on the grid), or null for the playhead.
  final int? atUs;

  /// Add as a picture-in-picture overlay instead of the main lane.
  final bool asOverlay;
}

/// Result of importing one picked item.
@immutable
sealed class ImportOutcome {
  const ImportOutcome(this.picked);

  /// The item this outcome is about.
  final PickedMedia picked;
}

/// Imported (or reused: re-picking the same file reuses the same `MediaId`).
final class ImportedMedia extends ImportOutcome {
  /// Creates the outcome.
  const ImportedMedia(super.picked, this.asset, {this.reused = false});

  /// The pool asset.
  final MediaAsset asset;

  /// Whether an existing asset was reused.
  final bool reused;
}

/// Not imported.
final class ImportRejected extends ImportOutcome {
  /// Creates the outcome.
  const ImportRejected(super.picked, this.reason);

  /// Stable reason code (`unsupported`, `diskFull`, `accessDenied`, `containerUnsupportedIos`, …).
  final String reason;
}

/// Availability of one asset (ARCH §9.3).
enum MediaAvailability {
  /// Readable and matching its fingerprint.
  available,

  /// Not found.
  missing,

  /// Grant revoked or bookmark unresolvable.
  accessLost,

  /// Found but the hash differs ("Use updated file" or Relink).
  changed,

  /// A rendition, still or proxy is gone (requeued silently).
  derivedMissing,
}

/// Availability of every asset of a project.
@immutable
final class MediaAvailabilityReport {
  /// Creates a report.
  MediaAvailabilityReport(Map<MediaId, MediaAvailability> byMedia) : byMedia = Map.unmodifiable(byMedia);

  /// State per asset.
  final Map<MediaId, MediaAvailability> byMedia;

  /// Assets that block export (missing, access lost, changed).
  Iterable<MediaId> get blocking => byMedia.entries
      .where((e) => e.value == MediaAvailability.missing || e.value == MediaAvailability.accessLost || e.value == MediaAvailability.changed)
      .map((e) => e.key);
}

/// Whether a candidate can replace a missing asset.
@immutable
sealed class RelinkCheck {
  const RelinkCheck();
}

/// Fingerprint equal, or duration ±100 ms with equal kind and dimensions.
final class RelinkMatch extends RelinkCheck {
  /// Creates the result.
  const RelinkMatch({required this.exactFingerprint});

  /// Whether the quickHash matched exactly.
  final bool exactFingerprint;
}

/// Durations differ; accepting clamps clips (with a notice).
final class RelinkDurationMismatch extends RelinkCheck {
  /// Creates the result.
  const RelinkDurationMismatch({required this.expectedUs, required this.actualUs});

  /// Expected duration.
  final int expectedUs;

  /// Candidate duration.
  final int actualUs;
}

/// A different media kind (refused).
final class RelinkDifferentKind extends RelinkCheck {
  /// Creates the result.
  const RelinkDifferentKind();
}

/// Not usable (reason code).
final class RelinkUnsupported extends RelinkCheck {
  /// Creates the result.
  const RelinkUnsupported(this.reason);

  /// Reason code.
  final String reason;
}

/// "Relink several": one pick proposed for one missing asset.
@immutable
final class RelinkProposal {
  /// Creates a proposal; [media] is null when the pick could not be assigned (ties are left
  /// unassigned).
  const RelinkProposal({required this.pick, required this.media, required this.check});

  /// The picked file.
  final PickedMedia pick;

  /// The missing asset it would replace, or null.
  final MediaId? media;

  /// Why.
  final RelinkCheck check;
}

/// A same-folder candidate (path locators only).
@immutable
final class RelinkCandidate {
  /// Creates a candidate.
  const RelinkCandidate({required this.media, required this.pick, required this.check});

  /// Missing asset.
  final MediaId media;

  /// File found next to the anchor.
  final PickedMedia pick;

  /// Check result.
  final RelinkCheck check;
}

/// Imports, availability and relink for one session's pool (ARCH §9.2).
abstract interface class MediaPoolService {
  /// Imports picked media following the import policy (ARCH §9.1); sticky pool changes.
  Future<List<ImportOutcome>> import(EditSession session, List<PickedMedia> picked, {ImportTarget? target});

  /// Availability on open, on resume and after relink.
  Stream<MediaAvailabilityReport> watchAvailability(EditSession session);

  /// Checks one candidate for one missing asset.
  Future<RelinkCheck> checkRelink(EditSession session, MediaId id, PickedMedia candidate);

  /// "Relink several": pairs each pick with the best missing asset (fingerprint first, then
  /// duration ±100 ms with equal kind and dimensions; ties unassigned).
  Future<List<RelinkProposal>> autoMatch(EditSession session, List<PickedMedia> picks);

  /// Applies relinks as one undoable "Relink media" entry.
  Future<EditOutcome> relink(EditSession session, Map<MediaId, PickedMedia> picks);

  /// Files next to [anchor] that match other missing assets (readable folders only).
  Future<List<RelinkCandidate>> findInSameFolder(EditSession session, PickedMedia anchor);
}
