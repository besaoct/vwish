// OWNER: CORE-03
//
// Tracks and compositing bands (ARCH §6.2, D-09).

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../ids/ids.dart';
import 'items.dart';
import 'subtitle.dart';
import 'transition.dart';

const Object _keep = Object();

/// Track kinds. Canonical order in `Timeline.tracks` is `[video…, overlay…, text…, subtitle…,
/// audio…]`; z bands bottom → top are video (main lowest) → overlay → text → subtitle. The UI shows
/// visual lanes in reverse z order (D-09).
enum TrackKind {
  /// Video lanes (the first one is the main lane).
  video,

  /// Picture-in-picture / image overlay lanes.
  overlay,

  /// Audio lanes.
  audio,

  /// Text overlay lanes.
  text,

  /// Subtitle lanes.
  subtitle;

  /// Whether items of this kind produce visual layers.
  bool get isVisual => this != audio;

  /// Compositing band (0 video, 1 overlay, 2 text, 3 subtitle) or null for audio (ARCH §11.4).
  int? get band => switch (this) {
        TrackKind.video => 0,
        TrackKind.overlay => 1,
        TrackKind.text => 2,
        TrackKind.subtitle => 3,
        TrackKind.audio => null,
      };

  /// Position of this kind in the canonical track order.
  int get canonicalOrder => switch (this) {
        TrackKind.video => 0,
        TrackKind.overlay => 1,
        TrackKind.text => 2,
        TrackKind.subtitle => 3,
        TrackKind.audio => 4,
      };
}

/// Role of an audio lane (drives defaults, AI caption priority and music exclusion).
enum AudioRole {
  /// Audio extracted from video.
  original,

  /// Voice-over recordings.
  voice,

  /// Background music.
  music,

  /// Sound effects.
  effects,
}

/// A lane of the timeline.
@immutable
final class Track {
  /// Creates a track. [items] must be sorted by start and non-overlapping.
  Track({
    required this.id,
    required this.kind,
    this.name = '',
    this.isMain = false,
    this.locked = false,
    this.hidden = false,
    this.muted = false,
    this.solo = false,
    this.audioRole,
    this.subtitle,
    List<TimelineItem> items = const [],
    List<Transition> transitions = const [],
    this.changedAt = 0,
  })  : items = List.unmodifiable(items),
        transitions = List.unmodifiable(transitions);

  /// Stable id.
  final TrackId id;

  /// Kind.
  final TrackKind kind;

  /// User-visible name (may be empty: the UI derives "Video 2" etc.).
  final String name;

  /// Exactly one track is the main track: the first video track.
  final bool isMain;

  /// Locked tracks reject every command targeting them (`TrackLocked`).
  final bool locked;

  /// Hidden tracks contribute no visual layers.
  final bool hidden;

  /// Muted tracks contribute no audio.
  final bool muted;

  /// Solo affects audio only: when any track is soloed, only soloed tracks are audible.
  final bool solo;

  /// Role of an audio track.
  final AudioRole? audioRole;

  /// Subtitle data, present exactly on subtitle tracks.
  final SubtitleTrackData? subtitle;

  /// Items sorted by start, non-overlapping (unmodifiable).
  final List<TimelineItem> items;

  /// Transitions between touching items (video/overlay lanes only), sorted by cut time.
  final List<Transition> transitions;

  /// Session-monotonic revision stamp of the last change to this track (never reused).
  final int changedAt;

  /// A copy with the given fields replaced; pass null to clear `audioRole`/`subtitle`.
  Track copyWith({
    TrackKind? kind,
    String? name,
    bool? isMain,
    bool? locked,
    bool? hidden,
    bool? muted,
    bool? solo,
    Object? audioRole = _keep,
    Object? subtitle = _keep,
    List<TimelineItem>? items,
    List<Transition>? transitions,
    int? changedAt,
  }) =>
      Track(
        id: id,
        kind: kind ?? this.kind,
        name: name ?? this.name,
        isMain: isMain ?? this.isMain,
        locked: locked ?? this.locked,
        hidden: hidden ?? this.hidden,
        muted: muted ?? this.muted,
        solo: solo ?? this.solo,
        audioRole: identical(audioRole, _keep) ? this.audioRole : audioRole as AudioRole?,
        subtitle: identical(subtitle, _keep) ? this.subtitle : subtitle as SubtitleTrackData?,
        items: items ?? this.items,
        transitions: transitions ?? this.transitions,
        changedAt: changedAt ?? this.changedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is Track &&
      other.id == id &&
      other.kind == kind &&
      other.name == name &&
      other.isMain == isMain &&
      other.locked == locked &&
      other.hidden == hidden &&
      other.muted == muted &&
      other.solo == solo &&
      other.audioRole == audioRole &&
      other.subtitle == subtitle &&
      other.changedAt == changedAt &&
      const ListEquality<TimelineItem>().equals(other.items, items) &&
      const ListEquality<Transition>().equals(other.transitions, transitions);

  @override
  int get hashCode => Object.hash(id, kind, name, isMain, locked, hidden, muted, solo, audioRole, subtitle,
      changedAt, Object.hashAll(items), Object.hashAll(transitions));
}
