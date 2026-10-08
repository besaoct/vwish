// OWNER: CORE-09
//
// Placeholder (D-33). CORE-09 adds the subtypes of ARCH §7.1: TrackLocked, ItemNotFound,
// WouldOverlap, OutOfSourceRange, BelowMinDuration, NothingAtTime, UnsupportedForKind,
// IncompatibleTrack, NotAdjacent, TransitionTooLong(maxFrames), KeyframeExists, EmptyText, NoRoom,
// RippleBlockedByLinkedItem, LimitExceeded(what, limit), MediaUnavailable, CannotDeleteMainTrack,
// InvalidValue, InternalInconsistency. Rejections are data and are never thrown.

/// Why a command was refused. Sealed; subtypes are declared by CORE-09.
sealed class EditRejection {
  const EditRejection();
}
