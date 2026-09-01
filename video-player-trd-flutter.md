# Technical Requirements Document — Cross-Platform Desktop Video Player

**Working name:** Vwish 
**Stack:** Flutter (Dart, stable channel) + `media_kit` → libmpv → FFmpeg
**Targets:** Windows 10+, macOS 12+, Linux (X11 + Wayland)
**Status:** Draft v1.0 — supersedes the web TRD
**Doc owner:** _TBD_

---

## 0. Thesis

We are not writing a media pipeline. **libmpv already is one**, and it is the most format-complete, hardware-accelerated, battle-tested playback engine available under a permissive-enough licence. Roughly 60% of the target feature list exists today as mpv properties we bind to rather than build.

Therefore the project's actual work is:

1. A **control surface** — the settings tree, seek bar, menus, overlays, gestures, keyboard map.
2. A **library and session layer** — playlists, resume state, history, sidecar discovery.
3. **Shell integration and packaging** for three operating systems.

The engine is a dependency, not a deliverable. Every architectural decision below protects that boundary.

**Why Flutter specifically:** libmpv renders into a **texture that participates in the widget tree**. Controls are widgets drawn over a widget, composited by one engine on one clock. The alternative approach used by web-shell stacks — hand a native window handle to mpv and float a transparent HTML layer above it — produces resize tearing, z-order fights, per-platform click-through handling, and simply does not work on Wayland. Choosing Flutter deletes that entire problem class rather than mitigating it.

---

## 1. Goals and non-goals

### 1.1 Goals

| # | Goal |
|---|---|
| G1 | Play essentially any consumer video file: MKV, MP4, MOV, AVI, WebM, TS, M2TS, FLV, WMV, OGV, ISO/BDMV folders |
| G2 | Full codec coverage: H.264, HEVC (8/10-bit), AV1, VP9, VP8, MPEG-2, VC-1, ProRes, DNxHD; AAC, AC-3, E-AC-3, DTS, DTS-HD, TrueHD, FLAC, Opus, PCM |
| G3 | Three source classes: local files/folders, network URLs (HTTP, HLS, DASH, RTSP, SMB/NFS), and streaming sites via yt-dlp |
| G4 | Hardware-accelerated decode on all three platforms, with graceful software fallback |
| G5 | A control surface matching or exceeding YouTube's, plus the desktop-only features it lacks (§5) |
| G6 | Identical UI and behaviour across Windows, macOS, and Linux; native shell integration on each |
| G7 | Plugin/extension boundary so analytics, scrobbling, and subtitle providers are optional modules |
| G8 | Fully keyboard-operable; screen-reader labelled; remappable shortcuts |
| G9 | Cold start to first frame < 1.5 s; idle memory < 200 MB |

### 1.2 Non-goals (v1)

- Editing, trimming, encoding, or export.
- Mobile (Flutter makes this cheap later; it is not v1 scope).
- Casting to external devices (v2 plugin).
- A media *server*. This is a client.
- Building or vendoring a custom FFmpeg.

---

## 2. Technology decisions

### 2.1 Stack

| Layer | Choice | Rationale |
|---|---|---|
| UI framework | **Flutter 3.x, stable** | Texture-based video compositing; single rendering engine on all platforms; hot reload |
| Language | **Dart 3.x**, sound null safety | Records, patterns, sealed classes, exhaustive switch |
| Playback | **`media_kit`** (+ `media_kit_video`, `media_kit_libs_video`) | Thin Dart binding over libmpv; ships prebuilt libmpv per platform |
| Engine | **libmpv**, built `-Dgpl=false` (LGPL) | See §12 licensing |
| State | **Riverpod 2.x** (code-generated) | Compile-safe DI, testable without widgets, fine-grained rebuilds |
| Local DB | **`drift`** (SQLite) | Typed queries, migrations, streams; library index + watch state |
| Prefs | **`shared_preferences`** for scalars; drift for structured | |
| Routing | **`go_router`** | Deep links (`vwishplayer://`), window routes |
| i18n | **`intl`** + ARB | |
| Logging | **`logger`** + rotating file sink | |
| Packaging | `flutter_distributor` / `msix` / `create_dmg` / `flatpak`+`AppImage` | §11 |

### 2.2 Rejected alternatives

| Option | Why not |
|---|---|
| Electron + React | Native-surface overlay compositing: resize tearing, Wayland `--wid` unsupported, per-platform click-through. 150 MB, 250 MB idle RAM. |
| Tauri + libmpv | Same overlay problem as Electron; system webview fragmentation adds nothing here. |
| Qt 6 / QML + libmpv | Genuinely strong alternative (Haruna, SMPlayer, Jellyfin Media Player). Loses hot reload; C++ slows control-surface iteration, which is the bulk of the work. Keep as fallback if `media_kit` becomes a blocker. |
| Native Rust GUI (egui/iced/slint) | Hand-building an animated nested settings tree, EQ, and subtitle styling panel in immediate-mode is where this project dies. |
| Custom FFmpeg pipeline (any language) | Months of A/V sync, seek, and HW-context work to reach where mpv already is. |
| `dart:ffi` direct to libmpv, no `media_kit` | Viable and kept as the escape hatch (§13), but re-solves texture interop and per-platform libmpv bundling for no v1 gain. |

### 2.3 The `media_kit` dependency, honestly

It is maintained by a small team. Mitigations, in order of escalation:

1. **All engine access goes through our own `PlaybackEngine` interface** (§4.1). No `media_kit` type appears in UI or domain code.
2. `media_kit` exposes the raw mpv handle, so `setProperty` / `command` / `observeProperty` cover anything the Dart API doesn't wrap. In practice we use this for most advanced features anyway.
3. If it stalls, `PlaybackEngine` is reimplemented over `dart:ffi` against libmpv's C API — small, stable, ~30 functions.

Because of (1), that swap is a contained rewrite of one package, not a project restart.

---

## 3. Architecture

### 3.1 Package layout

```
vwishplayer/
├─ packages/
│  ├─ vwish_engine/           # PlaybackEngine interface + media_kit impl. No Flutter imports.
│  ├─ vwish_domain/           # Entities, value objects, pure logic. No Flutter, no I/O.
│  ├─ vwish_data/             # drift DB, file scanner, ffprobe-ish metadata, prefs, sidecar discovery
│  ├─ vwish_ui_kit/           # Design tokens, primitives, icons, motion curves, themes
│  ├─ vwish_features/         # Feature modules: player, library, settings, playlist, subtitles…
│  └─ vwish_platform/         # Shell integration behind one interface per capability
├─ app/                    # Composition root, routing, window setup, entrypoint
├─ native/                 # Per-platform glue (Swift/C++/C) where vwish_platform needs it
└─ tooling/                # Build scripts, packaging, corpus fixtures, CI
```

**Dependency rule:** `app → vwish_features → { vwish_domain, vwish_ui_kit, vwish_platform } → vwish_engine/vwish_data`. `vwish_domain` depends on nothing. Enforced by `dependency_validator` in CI.

### 3.2 Runtime topology

```
┌──────────────────────────────────────────────────────────────┐
│  Flutter UI (widget tree, single compositor)                 │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Stack                                                 │  │
│  │   ├─ Video(controller)      ← libmpv texture widget    │  │
│  │   ├─ SubtitleOverlay        ← libass, drawn by mpv     │  │
│  │   ├─ ControlsLayer          ← our widgets              │  │
│  │   ├─ MenuLayer / ToastLayer                            │  │
│  │   └─ GestureDetector / Shortcuts / FocusScope          │  │
│  └────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│  Riverpod providers  (PlayerState, LibraryState, Settings)   │
├──────────────────────────────────────────────────────────────┤
│  PlaybackEngine (our interface)                              │
│     commands ↓                          property streams ↑   │
├──────────────────────────────────────────────────────────────┤
│  media_kit  →  libmpv  →  FFmpeg + libass + hwdec            │
│                    │                                          │
│                    └─ ytdl_hook → yt-dlp (subprocess)        │
├──────────────────────────────────────────────────────────────┤
│  drift/SQLite · file system · OS shell APIs                  │
└──────────────────────────────────────────────────────────────┘
```

Rendering: `media_kit_video` acquires mpv frames into a GPU texture registered with the Flutter engine (ANGLE/D3D11 on Windows, Metal on macOS, GL/EGL on Linux) and presents it via `Texture`. Nothing is copied to the CPU. The subtitle overlay is drawn by mpv inside the same texture so libass positioning and karaoke are exact; only *our* chrome is Flutter-drawn.

### 3.3 Threading

Dart is single-isolate by default; decode happens on mpv's own threads, so the UI isolate stays free. Move to background isolates (`Isolate.run` / `compute`) for: library scanning, thumbnail generation, subtitle file parsing, DB migrations, and hashing for subtitle lookup. Never block the UI isolate on file I/O.

---

## 4. Engine layer

### 4.1 The interface

```dart
// packages/vwish_engine/lib/src/playback_engine.dart
abstract interface class PlaybackEngine {
  Future<void> initialize(EngineConfig config);
  Future<void> dispose();

  // Source
  Future<void> open(MediaSource source, {Duration? startAt});
  Future<void> stop();

  // Transport
  Future<void> play();
  Future<void> pause();
  Future<void> playOrPause();
  Future<void> seek(Duration position, {SeekMode mode = SeekMode.keyframe});
  Future<void> seekBy(Duration delta);
  Future<void> frameStep(int direction); // +1 / -1

  // Audio
  Future<void> setVolume(double percent);   // 0–1000, >100 boosts
  Future<void> setMuted(bool muted);
  Future<void> setAudioDelay(Duration delay);
  Future<void> setAudioTrack(int? id);
  Future<void> setAudioFilters(List<AudioFilter> filters); // EQ, dynaudnorm, downmix

  // Video
  Future<void> setSpeed(double speed);      // 0.0625–16, pitch-corrected
  Future<void> setVideoTrack(int? id);
  Future<void> setVideoAdjust(VideoAdjust adjust); // brightness…gamma
  Future<void> setVideoTransform(VideoTransform t); // zoom, pan, rotate, aspect
  Future<void> setDeinterlace(bool on);
  Future<void> setHwdec(HwdecMode mode);

  // Subtitles
  Future<void> setSubtitleTrack(int? id);
  Future<void> addSubtitleFile(String path, {bool select = true});
  Future<void> setSubtitleDelay(Duration delay);
  Future<void> setSubtitleStyle(SubtitleStyle style);
  Future<void> setSecondarySubtitleTrack(int? id);

  // Misc
  Future<void> setAbLoop(Duration? a, Duration? b);
  Future<Uint8List> screenshot({bool includeSubtitles, ScreenshotFormat format});
  Future<T?> getProperty<T>(String name);
  Future<void> setProperty(String name, Object? value);
  Future<void> command(List<String> args);

  // Observation
  Stream<PlayerSnapshot> get snapshots;
  Stream<EngineEvent> get events;
  ValueListenable<int?> get textureId;
}
```

Every UI action funnels through this. Two implementations ship: `MpvPlaybackEngine` (media_kit) and `FakePlaybackEngine` (deterministic, for widget tests and golden tests without a GPU).

### 4.2 mpv property map

This table *is* the feature spec for the engine. Most "advanced" features are one line.

| Feature | mpv property / command |
|---|---|
| Play / pause | `pause` |
| Position / duration | `time-pos`, `duration`, `percent-pos` |
| Buffered / cache | `demuxer-cache-time`, `demuxer-cache-state` |
| Speed | `speed` + `audio-pitch-correction=yes` |
| Volume / mute | `volume` (0–1000), `mute` |
| Volume boost > 100% | `volume-max=300` |
| Frame step | `frame-step`, `frame-back-step` |
| Precise seek | `seek <t> absolute+exact` |
| A-B loop | `ab-loop-a`, `ab-loop-b`, `ab-loop-count` |
| Subtitle delay | `sub-delay` |
| Audio delay | `audio-delay` |
| Subtitle styling | `sub-font`, `sub-font-size`, `sub-color`, `sub-border-size`, `sub-border-color`, `sub-back-color`, `sub-shadow-offset`, `sub-pos`, `sub-scale`, `sub-ass-override` |
| Secondary subtitles | `secondary-sid`, `secondary-sub-pos` |
| Add external sub | `sub-add <path> select` |
| Track lists | `track-list` (typed: video/audio/sub, lang, title, default, forced, codec) |
| Track selection | `vid`, `aid`, `sid` |
| Zoom / pan | `video-zoom`, `video-pan-x`, `video-pan-y` |
| Rotate | `video-rotate` (0/90/180/270) |
| Aspect / crop | `video-aspect-override`, `video-crop`, `panscan`, `keepaspect` |
| Colour adjust | `brightness`, `contrast`, `saturation`, `gamma`, `hue` |
| Sharpen / custom | `glsl-shaders` (FSRCNNX, Anime4K, etc.) |
| Deinterlace | `deinterlace` |
| Equalizer | `af=lavfi=[superequalizer=...]` or `equalizer` chain |
| Night mode / DRC | `af=lavfi=[dynaudnorm]` or `drc` |
| Loudness normalization | `af=lavfi=[loudnorm=I=-16]` |
| Channel downmix | `audio-channels=stereo` |
| Screenshot | `screenshot-to-file <path> <video\|subtitles\|window>` |
| Chapters | `chapter-list`, `chapter` |
| Playlist | `playlist`, `playlist-play-index`, `loadfile`, `playlist-next/prev` |
| Loop | `loop-file`, `loop-playlist` |
| HW decode | `hwdec=auto-safe`, read back `hwdec-current` |
| Stats | `estimated-vf-fps`, `frame-drop-count`, `vo-delayed-frame-count`, `video-bitrate`, `audio-bitrate`, `video-params/*`, `decoder-frame-drop-count` |
| Colour space / HDR | `video-params/colormatrix`, `primaries`, `gamma`, `sig-peak`; `target-colorspace-hint` |
| Media title / metadata | `media-title`, `metadata`, `filtered-metadata` |
| Network URLs | `loadfile <url>` (+ `script-opts=ytdl_hook-ytdl_path=...`) |
| Streaming sites | `ytdl=yes`, `ytdl-format` |
| Cache tuning | `cache=yes`, `demuxer-max-bytes`, `demuxer-readahead-secs` |
| Custom HTTP headers | `http-header-fields`, `user-agent`, `referrer` |

Observation uses `observeProperty` for reactive values and a periodic 4 Hz poll only for stats. Position updates come from mpv's own `time-pos` observation, not a Dart timer.

### 4.3 Startup configuration

```dart
final config = EngineConfig(
  vo: 'libmpv',                       // required for texture rendering
  hwdec: 'auto-safe',                 // VideoToolbox / D3D11VA / VAAPI-NVDEC
  gpuApi: Platform.isWindows ? 'd3d11'
        : Platform.isMacOS   ? 'metal'
        : 'opengl',
  cache: true,
  demuxerMaxBytes: 150 << 20,
  demuxerReadaheadSecs: 20,
  subAuto: 'fuzzy',                   // sidecar subtitle discovery
  subFilePaths: ['subs', 'Subs', 'subtitles'],
  audioFileAuto: 'fuzzy',
  keepOpen: true,                     // don't tear down at EOF; we own the end screen
  ytdl: true,
  screenshotFormat: 'png',
  volumeMax: 300,
  audioPitchCorrection: true,
  forceWindow: false,
  osc: false, osdLevel: 0, inputDefaultBindings: false, // we own ALL UI
);
```

`osc=false` and `input-default-bindings=no` are non-negotiable: mpv must render zero chrome and consume zero keys. Every pixel and every keystroke belongs to us.

---

## 5. Feature and control inventory

### 5.1 Primary control bar

| Control | Notes |
|---|---|
| Play / pause | Morphing icon, `AnimatedIcon` |
| Previous / next | Playlist-aware; hidden for single item |
| Seek bar | Played fill + cache-ahead band + hover preview + drag |
| — Thumbnail preview | Generated locally, §7 |
| — Chapter segments | Split bar with gaps; segment hover expansion |
| — Markers | Typed: bookmark, intro, credits, note |
| — A-B loop region | Draggable handles, shaded band |
| Volume | Button + slider; scroll to adjust; boost band visually distinct above 100% |
| Time display | `current / total`, click → remaining, click → clock |
| Chapter title | Inline; click opens chapter list |
| Subtitles | Quick toggle; right-click → track list |
| Settings | Opens the nested menu, §5.2 |
| Playlist | Side sheet with reorder and drag-drop |
| PiP / always-on-top | Compact floating window mode |
| Fullscreen | Per-platform native fullscreen behaviour |

### 5.2 Settings menu (nested, height-animated)

- **Video** — track, quality (for adaptive/yt-dlp sources), aspect override, zoom/pan/rotate/flip, crop, deinterlace, hwdec mode, GLSL shader presets (off / sharpen / Anime4K / FSRCNNX).
- **Colour** — brightness, contrast, saturation, hue, gamma; per-file persistence; reset.
- **Audio** — track, delay (±10 s, 10 ms steps), channel mode, device selection, **10-band EQ** with presets, night mode (DRC), loudness normalization, volume boost cap.
- **Subtitles** — track, secondary track, add file, download (OpenSubtitles plugin), delay (±10 s, 50 ms steps), font family/size/scale/colour/border/shadow/background, vertical position, `sub-ass-override` mode (respect vs force style), encoding override for legacy SRT.
- **Playback** — speed (presets + 0.0625–16 slider), pitch correction, loop (off/one/all/A-B), autoplay next, resume behaviour, sleep timer, skip-silence.
- **Interface** — theme (dark/light/system/OLED black), accent colour, control density, always-show-controls, auto-hide delay, thumbnail previews on/off, language, remap shortcuts.
- **Advanced** — cache size, readahead, custom mpv `--options` passthrough, config file editor, stats overlay, logging level, reset all.

### 5.3 Overlays

Big centre play button · buffering indicator (deferred 400 ms) · title bar on hover · toast layer for transient feedback (`Speed 1.5×`, `Sub delay +100 ms`) · error card with cause and retry · end screen (replay, next-up countdown) · **stats overlay** (§9) · skip-intro/credits button from chapter markers · drag-and-drop target highlight.

### 5.4 Desktop-only features the web version could never have

| Feature | Basis |
|---|---|
| **Plays literally everything** | MKV, DTS-HD, TrueHD, ProRes, VC-1, 10-bit HEVC, BDMV folders |
| **Bitstream/multichannel audio** | 5.1/7.1 output, passthrough where the device supports it |
| **GLSL upscaling shaders** | Anime4K, FSRCNNX, ravu — real quality gains |
| **Folder & library scanning** | Recursive watch, SQLite index, resume across a series |
| **Sidecar auto-discovery** | `movie.en.srt`, `/Subs/` directories, external audio tracks |
| **Full ASS/SSA** | libass native, karaoke and positioning intact |
| **yt-dlp integration** | Paste any streaming URL; format selection |
| **Network shares** | SMB/NFS/FTP/SFTP paths as first-class sources |
| **Global media keys + OS integration** | Play/pause from keyboard, taskbar, Now Playing |
| **Multi-window** | Independent player windows, each with its own engine |
| **Frame-exact stepping and capture** | Genuinely frame-accurate, unlike browsers |
| **File association + "Open with"** | Becomes the system default player |

### 5.5 Keyboard map (defaults, all remappable)

Implemented with Flutter `Shortcuts`/`Actions`/`Intent`, not raw key listeners — this gives free focus scoping, text-field suppression, and screen-reader compatibility.

| Key | Action | | Key | Action |
|---|---|---|---|---|
| `Space` / `K` | Play/pause | | `M` | Mute |
| `←` / `→` | ±5 s | | `↑` / `↓` | Volume ±5 |
| `J` / `L` | ±10 s | | `0`–`9` | Seek 0–90% |
| `,` / `.` | Frame back / forward | | `Home` / `End` | Start / end |
| `[` / `]` | Speed ∓0.1 | | `Backspace` | Reset speed |
| `F` / `Esc` | Fullscreen on/off | | `T` | Always-on-top |
| `C` | Cycle subtitle track | | `V` | Toggle subtitles |
| `Z` / `Shift`+`Z` | Sub delay ∓50 ms | | `X` | Reset sub delay |
| `A` / `Shift`+`A` | Audio delay ∓50 ms | | `#` | Cycle audio track |
| `I` | Stats overlay | | `S` | Screenshot |
| `B` | Bookmark | | `L` (mod) | Set A-B loop point |
| `P` | Playlist sheet | | `O` | Open file |
| `Ctrl`+`,` | Settings | | `?` | Shortcut sheet |

### 5.6 Pointer and trackpad

Double-click toggles fullscreen · single click toggles play (configurable) · wheel adjusts volume (Shift+wheel seeks) · drag on the video pans when zoomed · pinch/Ctrl+wheel zooms · horizontal trackpad swipe scrubs with preview · hover reveals controls with 3 s idle auto-hide (suppressed while a menu is open, a slider is dragged, or focus is keyboard-driven) · right-click opens the context menu · cursor auto-hides in fullscreen.

---

## 6. State management

Riverpod with code generation. Domain state is immutable Dart records/classes; the engine is the only mutable thing.

```dart
@riverpod
class PlayerController extends _$PlayerController {
  late final PlaybackEngine _engine;

  @override
  PlayerState build() {
    _engine = ref.watch(playbackEngineProvider);
    final sub = _engine.snapshots.listen(_apply);
    ref.onDispose(sub.cancel);
    return const PlayerState.initial();
  }

  void _apply(PlayerSnapshot s) => state = state.copyWith(
        status: s.status,
        position: s.position,
        duration: s.duration,
        cacheEnd: s.cacheEnd,
        tracks: s.tracks,
        chapters: s.chapters,
      );

  Future<void> togglePlay() => _engine.playOrPause();
  Future<void> seekBy(Duration d) => _engine.seekBy(d);
  Future<void> setSubtitleDelay(Duration d) async {
    await _engine.setSubtitleDelay(d);
    state = state.copyWith(subtitleDelay: d);
    ref.read(sessionRepositoryProvider).saveSubtitleDelay(state.sourceId, d);
  }
}
```

```dart
@freezed
sealed class PlayerState with _$PlayerState {
  const factory PlayerState({
    required PlaybackStatus status,     // idle|loading|playing|paused|buffering|ended|error
    required Duration position,
    required Duration duration,
    required Duration cacheEnd,
    required double speed,
    required double volume,
    required bool muted,
    required TrackSelection tracks,
    required List<Chapter> chapters,
    required VideoTransform transform,
    required VideoAdjust adjust,
    required Duration subtitleDelay,
    required Duration audioDelay,
    required AbLoop? abLoop,
    required ViewMode viewMode,
    required PlayerError? error,
  }) = _PlayerState;
}
```

**Rebuild discipline** matters at 60 fps: position updates must not rebuild the whole tree. Use `select` so only the seek bar and time label watch `position`, and drive the scrubber's own animation from a `ValueNotifier` rather than provider state during a drag.

---

## 7. Library, playlists, and sequential playback

### 7.0 The non-destructive invariant

**The player has exactly one writable location: its own app-data directory. It never writes to, moves, renames, reorganises, or deletes anything inside the user's media folders.**

Everything the user sees — playlists, collections, custom ordering, tags, posters, thumbnails, watch state — is a **row in our SQLite database pointing at a path**. The library is a *view over* the filesystem, never a copy of it and never a rewrite of it.

Concretely, this means:

| Thing | Where it lives | Never |
|---|---|---|
| Playlists, order, collections | app DB | Never an `.m3u` written beside the videos unless explicitly exported |
| Thumbnails / trickplay sprites | app cache dir, keyed by content hash | Never a `.thumbs/` folder next to the media |
| Downloaded subtitles | app data dir, linked by item id | Never written beside the video *unless* the user opts in per download |
| Watch position, per-file settings | app DB | Never a `.resume` or dotfile in the media folder |
| Posters / artwork | app cache dir | Never `folder.jpg` written into the source |
| Tags, ratings, notes | app DB | Never file metadata rewriting, never renaming |

The only filesystem operations permitted on media directories are **read**, **stat**, and **watch**. This is enforced structurally: file writes go through a single `AppStorage` service in `vwish_data` that physically cannot resolve a path outside the app directories, and a CI lint bans `File(...).write*` / `.rename` / `.delete` anywhere else in the codebase. Any future "organise my files" feature must be a separate, explicitly-confirmed, opt-in tool — not something the library layer can do by accident.

The user-facing promise, stated in onboarding: *"Your files stay exactly where they are. This player only reads them."*

### 7.1 Media identity — the hard part

Paths are a fragile primary key. Users rename folders, move drives, and remount volumes with different letters. If identity is path-only, every reorganisation silently destroys playlists and watch history — which would break the promise above in spirit even though no file was touched.

Identity is therefore a composite, resolved in order:

```dart
class MediaIdentity {
  final String volumeId;     // Windows volume GUID, macOS/Linux volume UUID
  final String relativePath; // path relative to the volume root
  final String? fileId;      // Windows FileID, or inode on macOS/Linux
  final int size;
  final DateTime mtime;
  final String quickHash;    // sha1(first 64 KB + last 64 KB + size) — fast, ~O(1)
}
```

**Relocation ladder** when a stored path no longer resolves:

1. Path exists, `size` + `mtime` match → hit.
2. Path missing → look up `fileId` on the same volume (survives rename/move within a volume, cheap on all three OSes).
3. Still missing → search known library roots for a matching `quickHash` (survives copy to a new drive).
4. Still missing → mark **Missing**, keep the row, grey it in the UI. Never auto-delete a library entry; a NAS being offline is not a reason to lose someone's playlist.
5. User can **Relocate…** manually. On relocating one item, diff the old and new paths and offer to apply the same prefix substitution to every other missing item sharing that prefix — one click repairs a whole moved library.

**macOS sandbox note:** if the app is sandboxed (required for the Mac App Store, optional for Developer ID distribution), raw paths stop working across launches. Store a **security-scoped bookmark** per granted root in the DB alongside the path, and wrap access in `startAccessingSecurityScopedResource()` / `stop…`. Decide sandboxing in phase 0 — retrofitting bookmarks later touches every read path.

### 7.2 Schema (drift)

```
volumes(id, uuid, label, kind, last_seen)

media_items(id, volume_id, relative_path, file_id, size, mtime, quick_hash,
            title, duration_ms, container, width, height, video_codec,
            audio_codec, streams_json, added_at, last_scanned_at,
            status)                     -- present | missing | unreadable

folders(id, volume_id, relative_path, recursive, watch, include_globs,
        exclude_globs, added_at)        -- library roots the user granted

playlists(id, name, kind, rules_json, sort_key, sort_dir, manual_order,
          created_at, updated_at, cover_item_id)
                                        -- kind: manual | smart | folder
playlist_items(id, playlist_id, media_item_id, position REAL, added_at)

collections(id, name, parent_id)        -- virtual folder tree
collection_items(collection_id, media_item_id)

tags(id, name, color)
item_tags(media_item_id, tag_id)

watch_state(media_item_id, position_ms, duration_ms, completed,
            play_count, last_played_at)
item_settings(media_item_id, sub_delay_ms, audio_delay_ms, sid, aid, vid,
              speed, video_adjust_json, subtitle_style_json)
bookmarks(id, media_item_id, position_ms, label, note, created_at)
history(id, media_item_id, played_at, position_ms, source)
```

`position REAL` on `playlist_items` is **fractional indexing**: to move an item between neighbours at 3.0 and 4.0, write 3.5. Reordering is a single-row update rather than renumbering the whole list — important when someone drags an item in a 2,000-entry playlist. Renormalise to integers in the background when gaps get too small.

### 7.3 Scanning and browsing

Two distinct browsing modes, both first-class:

**File browser mode** — a real directory tree of granted roots. Shows folders as folders, files as files, with badges (duration, resolution, watched state, subtitle availability) overlaid on the *actual* structure. No import step required: browse and play immediately. This is the mode people want when they already have a well-organised drive.

**Library mode** — the flattened, indexed, searchable view built from scanned roots, with collections, tags, and smart playlists on top.

**Scanning:** recursive walk in a background isolate; extension allow-list; skip hidden and system dirs; `size`+`mtime` fast path so a rescan of 50k files takes seconds. Metadata is read by a pooled headless mpv instance (`--vo=null --ao=null --pause --frames=0`) reading `duration`, `track-list`, and `video-params` — no separate ffprobe dependency. Scans are cancellable, resumable, and report progress. A debounced filesystem watcher (`package:watcher`) keeps granted roots live, with a manual "Rescan" always available.

**Sidecar discovery** is read-only: matching `.srt`/`.ass`/`.sub` next to the file, plus `Subs/`, `subs/`, `Subtitles/` subdirectories, resolved by mpv's `sub-auto=fuzzy` and `sub-file-paths`. External audio tracks likewise via `audio-file-auto`.

### 7.4 Sorting

Sorting is a *view* property stored per playlist and per folder view — it never changes anything on disk.

**Sort keys:** name (natural) · date added · date modified · date released · duration · size · resolution · file type · watch progress · last played · play count · rating · random (seeded) · **manual**.

**Natural sort is mandatory and must be correct.** `Episode 2` sorts before `Episode 10`; `1.mkv`, `2.mkv`, `10.mkv` sort in that order. Implement by chunking each name into alternating digit and non-digit runs and comparing runs numerically or lexically as appropriate, with a locale-aware collator (`intl`) for the text runs and case-insensitive comparison by default.

**Episode-aware ordering** on top of that: parse `S01E02`, `1x02`, `- 04 -`, `EP03`, `Part 2`, and `[Group] Title - 07 [1080p]` patterns into `(season, episode)` and sort by that when a folder is confidently detected as a series. Always show the user which rule was applied and let them override to plain natural sort — heuristics that can't be turned off are worse than none.

**Manual order** is the escape hatch: drag to reorder, and the playlist's `sort_key` flips to `manual`, freezing the current order into `position` values. Switching back to an automatic sort keeps the manual order stored, so it isn't lost.

Secondary sort key and ascending/descending are both configurable and persisted.

### 7.5 Playlists

Three kinds, all reference-only:

| Kind | Definition | Behaviour |
|---|---|---|
| **Manual** | An explicit ordered list of item ids | Drag to reorder, add/remove freely |
| **Folder** | A live pointer to a directory + sort rule | Auto-reflects files added or removed on disk |
| **Smart** | A stored rule set evaluated as a query | e.g. *unwatched AND added in last 30 days AND duration > 20 min* |

Smart playlist rules are stored as JSON and compiled to drift queries — fields (tag, folder, codec, resolution, duration, watched, rating, added, played), operators (is / is not / contains / >, <, between / in last N days), boolean groups, an optional item cap, and a sort. Because they're queries, they update themselves.

**Operations:** create, rename, duplicate, delete (removes the *playlist*, never files), add to playlist, remove from playlist, **Play next** / **Add to queue**, reorder by drag, multi-select with Shift/Ctrl, sort, shuffle-in-place (materialises a shuffled manual order), reverse, deduplicate, remove missing entries, merge two playlists, and export.

**Import/export** is the one place we touch outside paths, and only on explicit user action: export to `.m3u8` (UTF-8, relative paths where the target shares a root, absolute otherwise), or to JSON with our full metadata. Import reads `.m3u`/`.m3u8`/`.pls`/`.xspf` and resolves entries against the library — **importing never copies media**, it only creates rows.

**Queue vs playlist.** These are separate concepts and conflating them is a common UX failure. The *playlist* is a saved, named, persistent list. The *queue* is the ephemeral now-playing sequence: it's seeded when you play something (from a playlist, a folder, or a multi-select), and `Play next` / `Add to queue` inject into it without mutating the saved playlist. Closing the app persists the queue so a restart resumes exactly where you were.

### 7.6 Sequential playback

**We own the sequence; mpv does not.** Our `QueueController` is the single source of truth for what plays next. mpv's internal playlist is used only as a **prefetch window**: we keep the current file plus the next one loaded with `prefetch-playlist=yes` so transitions are near-instant, and we drive advancement ourselves via `loadfile`. This keeps ordering, shuffle, repeat, and resume logic in testable Dart rather than split across two systems.

```dart
abstract interface class QueueController {
  QueueState get state;                    // items, index, repeat, shuffle
  Stream<QueueState> get changes;

  Future<void> playFrom(List<MediaRef> items, {int startIndex = 0});
  Future<void> next({bool userInitiated = true});
  Future<void> previous();                 // restarts current if >5 s elapsed
  Future<void> jumpTo(int index);
  void playNext(MediaRef item);            // insert after current
  void addToQueue(List<MediaRef> items);   // append
  void remove(int index);
  void move(int from, int to);
  void setRepeat(RepeatMode mode);         // off | one | all
  void setShuffle(bool on);                // preserves original order for restore
  void setStopAfterCurrent(bool on);
}
```

Behaviour details that matter:

- **Auto-advance** on `end-file` with reason `eof`. A user-initiated stop, a playback error, or `stopAfterCurrent` must *not* advance.
- **Errors don't stall the queue.** A missing or unreadable file toasts, marks the item, and advances after a short delay — with a circuit breaker that halts after 3 consecutive failures rather than racing through a broken folder.
- **Up-next overlay** in the final 10 s: next title, thumbnail, countdown, Cancel and Play-now buttons. Disabled by default for non-series content, configurable.
- **Per-item state restoration**: on advancing, apply that item's saved subtitle track, audio track, delays, and speed — or carry the current session's settings forward if the user has enabled "keep settings across files" (the right default for a series with consistently misaligned subs).
- **Resume within a sequence**: each item keeps its own resume position; finishing an item marks it complete and clears its resume so replaying starts at zero.
- **Repeat one** uses our controller, not `loop-file`, so the `played` count and history stay accurate.
- **Shuffle** is a seeded Fisher–Yates over indices, storing the original order so turning shuffle off restores it exactly. The currently-playing item stays put and shuffling applies to what remains.
- **Gapless-ish transitions**: with prefetch enabled, expect roughly 100–300 ms between files. True gapless video is not a goal; keeping the window from flashing or resizing between items is — hold the last frame until the next first frame arrives.

### 7.7 Playlist and queue UI

- **Side sheet** (`P`) with the queue: drag handles, current-item highlight, per-row duration and watched badge, right-click context menu, multi-select, search-within-list, and a "Clear played" action.
- **Library grid/list** with view toggle, density control, column chooser in list mode (name, duration, resolution, codec, size, added, watched), and column-header click-to-sort.
- **Breadcrumb file browser** with keyboard navigation, type-ahead jump, and Enter to play / Space to preview.
- **Drag and drop, everywhere**: files or folders onto the window → play immediately and seed a queue; onto the queue sheet → append; onto a playlist in the sidebar → add. Dropping a folder respects the current sort rule.
- **Multi-select actions**: play all, play next, add to queue, add to playlist, tag, mark watched/unwatched, remove from library (a DB-only operation, worded explicitly as *"Remove from library — your files stay on disk"*).
- **Missing items** render greyed with a "Locate…" affordance rather than vanishing.

### 7.8 Thumbnails, trickplay, and artwork

On first open of a local file, a background isolate steps a second headless mpv instance across N positions (1 per 5 s, capped at 200) writing JPEGs into a sprite **in the app cache directory**, keyed by `quick_hash`. Progressive: previews appear on the seek bar as they land. LRU-evicted with a 200 MB budget, and fully rebuildable — cache loss is never data loss.

Poster art follows the same rule: read `folder.jpg` / `poster.jpg` / embedded cover art if present, otherwise generate a frame grab into the cache. Nothing is written back.

### 7.9 Resume and history

Save `time-pos` every 5 s and on pause, close, and EOF. Restore when the stored position is between 30 s and `duration − 60 s`; below or above those thresholds, start fresh and mark complete respectively. Both thresholds are configurable. "Continue watching" is a smart playlist over `watch_state`, ordered by `last_played_at`, and — for detected series — surfaces the *next* episode rather than the partially-watched one when the current item is complete.

---

## 8. Platform integration

All behind interfaces in `vwish_platform`, one implementation per OS, mocked in tests.

| Capability | Windows | macOS | Linux |
|---|---|---|---|
| Window chrome | `bitsdojo_window` / custom title bar | Traffic lights, unified toolbar | GTK header bar |
| Fullscreen | Borderless maximize | Native fullscreen space | Toggle via wmctrl semantics |
| Always-on-top | `window_manager` | `window_manager` | `window_manager` |
| Prevent sleep | `SetThreadExecutionState` | `IOPMAssertion` | `org.freedesktop.ScreenSaver` inhibit / `systemd-inhibit` |
| Media keys / Now Playing | SMTC | `MPNowPlayingInfoCenter` + remote command centre | MPRIS2 D-Bus |
| Taskbar / Dock | Thumbnail toolbar, progress | Dock menu, progress | Unity launcher / MPRIS |
| File associations | Registry, MSIX manifest | `Info.plist` `CFBundleDocumentTypes` | `.desktop` MIME |
| Deep links | `vwishplayer://` registry | URL scheme in `Info.plist` | `.desktop` `x-scheme-handler` |
| Single instance | Named mutex | `NSDistributedNotification` | Abstract socket / D-Bus name |
| Drag-drop | `desktvwish_drop` | `desktvwish_drop` | `desktvwish_drop` |
| Global shortcuts | `hotkey_manager` | needs Accessibility permission | X11/portal |
| Native menus | — | `NSMenu` menu bar (required) | optional AppMenu |

**Wayland note:** because mpv renders into a Flutter texture rather than a native subsurface, there is no `--wid` dependency and no XWayland requirement. This is the payoff of the architecture — verify it in phase 1 anyway.

---

## 9. Diagnostics ("Stats for nerds")

Toggle with `I`. Two pages, poll at 4 Hz:

Container/codec strings · resolution, colour space, primaries, transfer, bit depth, HDR peak · `hwdec-current` and decoder name · display FPS vs estimated video FPS · dropped frames (decoder / VO / late) · A/V desync · cache: seconds buffered, bytes, underruns · bitrate (video/audio/total) · file path or URL, byte position · audio device, channels, sample rate · active filters and shaders · frame timings graph · app: memory, isolate count, texture id.

Also: `Copy diagnostics` writes an anonymised report (mpv version, hwdec, GPU, OS, active options, last 200 log lines) for bug reports.

---

## 10. Error handling

```dart
sealed class PlayerError {
  const PlayerError(this.message, {this.recoverable = false});
}
final class FileNotFound extends PlayerError { ... }
final class UnsupportedFormat extends PlayerError { ... }   // rare, but possible
final class DecoderInitFailed extends PlayerError { ... }   // → retry with hwdec=no
final class NetworkUnreachable extends PlayerError { ... }  // → backoff retry ×3
final class YtdlpFailed extends PlayerError { ... }         // → prompt yt-dlp update
final class PermissionDenied extends PlayerError { ... }    // → macOS TCC prompt
final class AudioDeviceLost extends PlayerError { ... }     // → reinit on device change
```

Recovery ladder: hardware decode failure automatically retries with `hwdec=no` and toasts a quality warning · network errors back off with jitter · audio device removal reinitialises on the default device · a corrupt file seeks to the next keyframe before failing. Users never see a raw mpv log line; the details live behind "Show technical details".

---

## 11. Build, packaging, distribution

| Platform | Format | Signing | Notes |
|---|---|---|---|
| Windows | MSIX + portable ZIP + optional NSIS | Authenticode (EV avoids SmartScreen warm-up) | Bundle `libmpv-2.dll`, VC++ runtime |
| macOS | `.dmg` (universal: arm64 + x86_64) | Developer ID + **notarization + stapling** | Hardened runtime; entitlements for file access; `@rpath` for libmpv, verify with `otool -L` |
| Linux | AppImage + Flatpak (+ optional `.deb`) | Flatpak signed by repo | Flatpak needs `org.freedesktop.Platform.ffmpeg-full`; AppImage bundles libmpv |

CI (GitHub Actions): matrix on `windows-latest`, `macos-14`, `ubuntu-22.04`. Steps: analyze → test → build → package → sign → smoke-test the artifact (launch, open a fixture, assert first frame) → publish. Secrets for signing certs; macOS notarization via `notarytool`.

**Size budget:** Windows ≤ 60 MB, macOS ≤ 80 MB universal, Linux AppImage ≤ 70 MB. Startup to first frame ≤ 1.5 s cold, ≤ 700 ms warm. Idle RSS ≤ 200 MB.

Auto-update: `shorebird` is unsuitable (native deps), so use a self-hosted appcast — Sparkle-style feed on macOS, custom checker + MSIX auto-update on Windows, Flatpak/AppImage-update on Linux.

---

## 12. Licensing

Non-optional homework before shipping anything commercial:

1. **Build libmpv with `-Dgpl=false`** for LGPL-2.1+. A default mpv build is GPL and would infect a proprietary app. Verify with `mpv --version` (it prints the licence).
2. **Dynamically link** libmpv and FFmpeg, ship the licence texts, and provide a written offer for the LGPL sources.
3. **FFmpeg must be built without `--enable-gpl` and without `--enable-nonfree`.** Check what `media_kit_libs_video` ships and rebuild if necessary.
4. **HEVC / AC-3 / DTS patent licensing.** Using the OS decoder is generally fine; distributing your own decoder in a commercial product may create obligations (Access Advance, Via LA, Dolby, DTS). Get counsel before commercial release. This is a real cost line, not a formality.
5. **yt-dlp** is unlicense/public-domain but invoking it to access some sites may violate those sites' terms — ship it as an optional, user-installed component rather than bundled, and don't advertise site-specific downloading.
6. App licence recommendation: **GPL-3.0 if open source** (simplest given the ecosystem), or commercial with the LGPL diligence above.

---

## 13. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| `media_kit` unmaintained or blocking bug | Medium-High | `PlaybackEngine` interface isolates it; `dart:ffi` fallback path documented and spiked in phase 1 |
| Texture interop bugs on a specific GPU/driver | Medium | Test matrix incl. Intel iGPU, NVIDIA, AMD, Apple Silicon; automatic `hwdec=no` fallback |
| Linux packaging fragmentation | Medium | Flatpak as the primary channel; AppImage as the portable fallback; don't chase distro packages in v1 |
| macOS notarization / entitlement friction | Medium | Set up the Developer account and a signed nightly build in phase 1, not at launch |
| Codec patent exposure | Medium | Legal review before commercial release; open-source route sidesteps most of it |
| Scope creep across 100+ features | High | Phases 1–4 are the MVP; everything else is explicitly deferred |
| Flutter desktop shell-integration gaps | Low-Medium | `vwish_platform` interfaces; write the native glue ourselves where packages fall short |
| 4K/8K performance on weak GPUs | Low | hwdec auto + shader presets off by default + a warning when dropped frames exceed 5% |

---

## 14. Delivery plan

| Phase | Scope | Effort |
|---|---|---|
| **0. Spikes** | Prove texture rendering on all 3 OSes; Wayland check; `dart:ffi` fallback spike; signed nightly on macOS | 1 wk |
| **1. Skeleton** | Monorepo, `PlaybackEngine` + mpv impl, Riverpod wiring, window shell, open a file and play | 2 wks |
| **2. Core controls** | Seek bar with cache band, volume, time, speed, fullscreen, keyboard/mouse, theming, auto-hide | 3 wks |
| **3. Tracks & subtitles** | Track menus, external subs, delay controls, full styling panel, secondary subs, chapters | 2 wks |
| **4. Queue & settings** | `QueueController`, sequential auto-advance, repeat/shuffle, queue sheet with drag-reorder, up-next overlay, nested settings tree, persistence, resume, drag-drop, file associations | 3 wks |
| **MVP** | | **~11 wks** |
| **5. Library & playlists** | `MediaIdentity` + relocation ladder, folder scanning and watching, drift index, file-browser and library modes, natural/episode sort, manual/folder/smart playlists, collections, tags, m3u import-export, posters, continue-watching, search | 4 wks |
| **6. Advanced media** | EQ, DRC, normalization, colour adjust, zoom/pan/rotate/crop, GLSL presets, screenshots, A-B loop, bookmarks | 2 wks |
| **7. Trickplay & polish** | Thumbnail generation + sprite cache, stats overlay, toasts, end screen, motion polish, a11y pass | 2 wks |
| **8. Platform integration** | Media keys, MPRIS/SMTC/Now Playing, sleep inhibit, deep links, single instance, tray, global hotkeys | 2 wks |
| **9. Network sources** | yt-dlp integration, URL open dialog, SMB/NFS, custom headers, stream format picker | 2 wks |
| **10. Release** | Packaging, signing, notarization, auto-update, crash reporting, docs, localisation | 2 wks |

~26 weeks for one experienced developer end to end; MVP at 11. Parallelises well across two, since UI and platform integration are largely independent.

---

## 15. Testing

- **Media corpus** (`tooling/fixtures`): ~60 short clips — every container × codec × bit depth × audio layout, plus ASS subs, forced subs, multi-audio, VFR, rotated, HDR10, 10-bit HEVC, truncated/corrupt files, and a BDMV folder.
- **Unit** (`test`): domain logic, subtitle parsers, time formatting, ABR-free playlist ordering, natural sort, EQ math. No Flutter.
- **Widget** (`flutter_test`): all controls against `FakePlaybackEngine`. Golden tests for the control bar, settings tree, and subtitle panel across both themes.
- **Integration** (`integration_test`): real playback on each OS in CI — open fixture, assert first frame arrives, seek accuracy within one frame, track switching, screenshot bytes are non-empty.
- **Manual matrix**: Windows 10/11 (Intel iGPU, NVIDIA, AMD), macOS Intel + Apple Silicon, Ubuntu/Fedora on X11 and Wayland, plus one low-end machine as the performance floor.
- **Soak**: 4 h continuous playback; assert RSS growth < 100 MB and zero texture leaks.
- **Non-destructive audit** (CI, all platforms): snapshot a fixture tree's paths, sizes, mtimes, and hashes; run a scripted session covering scan, folder playback, playlist creation and reorder, thumbnail generation, subtitle download, and library removal; re-snapshot and assert byte-identical. Paired with a static lint banning filesystem mutation outside `AppStorage`.
- **Ordering**: a fixture set of adversarial filenames (`1`, `2`, `10`, `Episode 2` vs `Episode 10`, `S01E09`/`S01E10`, `[Group] Show - 07 [1080p]`, mixed case, accented characters, leading zeros) with asserted expected order.
- **Relocation**: rename a folder, move a file within a volume, and copy the library to a second volume; assert playlists and watch state survive each via the ladder in §7.1.
- **Accessibility**: full keyboard traversal, semantic labels on every control, screen reader pass (Narrator/VoiceOver/Orca), `MediaQuery.disableAnimations` respected.

---

## 16. Definition of done (MVP)

- Opens and plays MKV/H.265, MP4/H.264, WebM/AV1, and an ASS-subtitled file on all three platforms with hardware decode active.
- Every control in §5.1 works by mouse, keyboard, and trackpad; zero mpv chrome visible; zero mpv default keybindings active.
- Subtitle and audio delay, track switching, speed, and A-B loop all function and persist per file.
- Dropping a folder plays its contents in correct natural/episode order, auto-advances through the whole sequence, and survives a missing file mid-list without stalling.
- Queue reorder, repeat one/all, shuffle-and-restore, play-next, and stop-after-current all behave correctly.
- **Verified non-destructive:** a filesystem audit over a full session (scan, play a folder, build playlists, reorder, generate thumbnails, download subtitles) shows zero writes, renames, or deletions anywhere outside the app data and cache directories.
- Resume works across restarts; drag-drop and file associations open the app.
- Signed and notarized artifacts for all three OSes install cleanly on a fresh machine.
- Startup, memory, and size budgets met; soak test clean.

---

## 17. Open questions

1. Open source or proprietary? Decides the licensing path in §12 and whether phase 0 needs a legal review.
2. **macOS sandboxing — decide in phase 0.** Mac App Store distribution requires it, which makes security-scoped bookmarks (§7.1) mandatory rather than optional. Retrofitting them later touches every file-read path in the app.
3. Is yt-dlp bundled, auto-downloaded on first use, or user-supplied? Legal and support implications differ sharply.
4. Do we need network shares (SMB/NFS) in v1, or is mounting them at the OS level acceptable?
5. Mobile later? If yes, keep `vwish_features` free of desktop-only assumptions from day one — cheap now, expensive to retrofit.
6. Target minimum hardware — does a 2015 Intel laptop need to play 4K HEVC smoothly? Sets the hwdec fallback policy.
7. Telemetry: opt-in crash reporting only, or usage analytics too?

---

## Appendix A — Key packages

| Purpose | Package |
|---|---|
| Playback | `media_kit`, `media_kit_video`, `media_kit_libs_video` |
| State | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` |
| Models | `freezed`, `json_serializable` |
| Database | `drift`, `sqlite3_flutter_libs` |
| Window | `window_manager`, `bitsdojo_window` (or custom) |
| Drag-drop | `desktvwish_drop` |
| File picking | `file_selector` |
| Paths | `path_provider`, `path` |
| Hotkeys | `hotkey_manager` |
| Menus | `menu_bar` / native channel |
| Packaging | `flutter_distributor`, `msix` |
| Logging | `logger`, `talker` |
| i18n | `intl`, `flutter_localizations` |

## Appendix B — Prior art worth studying

**IINA** (macOS, Swift + mpv) — the best-designed mpv front end; study its control surface and settings organisation. **Haruna** (Qt/QML + mpv) and **Celluloid** (GTK + mpv) — clean, minimal integrations. **Jellyfin Media Player** and **Plex Media Player** — mpv + web UI, the architecture we're deliberately avoiding, useful for seeing why. **mpv's own `input.conf` and manual** — the definitive list of what the engine can already do; read it before building any feature.
