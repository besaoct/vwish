<div align="center">

# 🎬 Vwish

**Ultra-high performance media player & next-generation creative editing workstation.**
*Powered by Flutter, libmpv, and on-device AI.*

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Engine](https://img.shields.io/badge/Engine-libmpv%20%2B%20FFmpeg-5C2D91)](https://mpv.io)
[![AI Engine](https://img.shields.io/badge/AI-whisper.cpp%20(On--Device)-FF6F00)](https://github.com/ggerganov/whisper.cpp)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-22c55e)](#supported-platforms)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](#-sponsor--support)

</div>

---

## 🌟 Overview & The Vwish Vision

**Vwish** bridges high-fidelity media playback with a modern, non-destructive creative editing workstation in a single unified application.

- 🎥 **The Player**: Engineered for cinephiles, audiophiles, and power users. Leverages **`libmpv`** and **FFmpeg** behind a modular Flutter architecture to deliver zero-copy, hardware-accelerated playback for virtually every container and codec in existence.
- ✂️ **The Editor Vision (v1.1.0)**: Expanding beyond playback into a complete, non-destructive timeline editing suite. Featuring frame-accurate cuts, multi-track compositing, professional color grading, real-time visual FX, and **on-device AI auto-captioning** powered by `whisper.cpp`—with zero cloud dependencies and total privacy.

---

## 💖 Sponsor & Support

If you enjoy using **Vwish** or find our engineering helpful, consider sponsoring the project to support active development and upcoming features:

- 💖 **GitHub Sponsors**: [github.com/sponsors/vecvel](https://github.com/sponsors/vecvel)
- ☕ **Buy Me a Coffee**: [buymeacoffee.com/vecvel](https://buymeacoffee.com/vecvel)
- 🌐 **GitHub Profile**: [github.com/vecvel](https://github.com/vecvel)

---

## ✨ Feature Overview

### 🎬 1. High-Fidelity Player Engine
- ⚡ **Native Hardware Acceleration**: Zero-copy GPU decoding (`VideoToolbox` on macOS/iOS, `D3D11VA`/`NVDEC` on Windows, `VAAPI` on Linux, `MediaCodec` on Android).
- 🎚️ **10-Band Graphic Equalizer & Audio DSP**: Real-time parametric frequency equalization, EQ presets (Rock, Pop, Classical, Voice, Bass Boost), Night Mode Dynamic Range Compression (DRC), and `-16 LUFS` loudness normalization.
- 🔊 **300% Volume Booster**: Continuous volume scaling from 0% to 100% (Cyan) with a designated Amber Boost zone extending up to 300%.
- 🎨 **Deep OLED Theme & Precision Seek Bar**: Precision seeking with buffer visualization, chapter tick marks, hover time tooltips, and A-B loop band highlighting.
- 📊 **"Stats for Nerds" HUD**: Real-time diagnostics overlay detailing active video/audio codecs, framerates, dropped frames, A/V desync, color primaries, bitrate, and one-click technical report export.
- 📂 **Smart Queue & Natural Sort**: Numerical episode sorting (`Episode 2` precedes `Episode 10`), regex scene parser (`S01E02`, `1x04`, `EP03`, anime `- 07`), auto-advance circuit breaker, shuffle with seed preservation, and sidecar subtitle auto-discovery.

---

### ✂️ 2. Non-Destructive Video Editor (v1.1.0 Vision)
- 🎞️ **Multi-Track Precision Timeline**:
  - Exact integer frame grid (24, 25, 30, 48, 50, 60 fps) ensuring frame-accurate edit points without microsecond drift.
  - Multi-track layering for video, B-roll overlays, text, subtitles, voiceovers, and background audio.
  - Ripple delete, ripple insert, blade split at playhead, trim handles, and clip slip/slide.
  - Variable speed ramping (0.1×–10×) with pitch-preserving time stretch, reverse playback, and freeze frames.
  - **Strict Non-Destructive Invariant**: Original user media files are never altered, moved, or deleted.
- 🎭 **Compositing, PiP & Chroma Key**:
  - Picture-in-Picture (PiP): Multi-layer video-over-video and image-over-video with direct on-screen transform manipulation (position, scale, rotation, crop, flip).
  - Real-Time Chroma Key: Green/blue screen removal with interactive color eyedropper, similarity, smoothness, and edge spill suppression.
  - Geometric Masking: Rectangle and circular feather masks with independent opacity and position controls.
- 🎨 **Color Grading & 3D LUTs**:
  - Full parametric color suite: exposure, brightness, contrast, highlights, shadows, saturation, temperature, and tint.
  - 3D LUT support with `.cube` file import and adjustable blend intensity.
  - Fast sharpening, gaussian blur, and cinematic vignette effects.
- 📐 **Linear Keyframing**:
  - Animate position, scale, rotation, opacity, volume, and visual effect parameters smoothly across the timeline.
- 🔤 **Dynamic Text Overlays & Subtitles**:
  - Rich typography with curated font families, custom fills, strokes, box backgrounds, and drop shadows.
  - Text entry animations including Fade, Slide, Scale, and Typewriter reveal.
  - In-timeline subtitle tracks with full support for manual creation, timing shifts, and SRT/VTT import/export.

---

### 🎙️ 3. On-Device AI Auto-Captions & Transcription
- 🔒 **100% Offline & Private**: Zero data sent to the cloud. Local transcription powered by embedded `whisper.cpp` (`vwish_whisper`).
- 🌐 **99 Languages Supported**: High-accuracy speech-to-text with automatic language detection or explicit locale selection.
- ⚡ **Hardware Accelerated**: Optimized execution utilizing Apple Metal/Accelerate on iOS/macOS and optimized CPU/NEON/GPU routines on Android.
- ⏱️ **Timestamp Alignment & Segmentation**: Natural sentence-boundary subtitle chunking automatically synced to the speech track.
- ✏️ **Interactive Post-Editing**: Generated captions land directly on the editor timeline as fully editable, stylable subtitle cues ready for export or burn-in.

---

### 🚀 4. Production Export & Render Engine
- ⚙️ **GPU-Accelerated Export**: Fast hardware-encoded export supporting H.264 and H.265 (HEVC) in MP4 and MOV containers.
- 📱 **One-Click Social Presets**: Instant export profiles tuned for YouTube (16:9 4K/1080p), YouTube Shorts, Instagram Reels (9:16), TikTok, and custom bitrate/resolution options.
- 🔥 **Subtitle Burn-In**: Option to permanently rasterize subtitles and text overlays directly into the exported video frames.
- 🛡️ **Reliability & Backgrounding**:
  - Resumable segmented export on iOS with background task handling and Android foreground service execution.
  - Dual-slot atomic project journaling with crash recovery and automatic migration safeguards.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| <kbd>Space</kbd> / <kbd>K</kbd> | Play / Pause |
| <kbd>←</kbd> / <kbd>→</kbd> | Seek ±5 seconds (Player) / Previous & Next Frame (Editor) |
| <kbd>J</kbd> / <kbd>L</kbd> | Seek ±10 seconds |
| <kbd>↑</kbd> / <kbd>↓</kbd> | Volume ±5% (boosts up to 300%) |
| <kbd>M</kbd> | Toggle Mute |
| <kbd>F</kbd> | Toggle Fullscreen |
| <kbd>T</kbd> | Pin Always on Top |
| <kbd>[</kbd> / <kbd>]</kbd> | Speed ±0.1x (0.25x – 3.0x in player) |
| <kbd>I</kbd> | Toggle "Stats for Nerds" Diagnostics HUD |
| <kbd>P</kbd> | Toggle Queue / Playlist Side-Sheet |
| <kbd>O</kbd> | Open File Dialog |
| <kbd>S</kbd> | Split Clip at Playhead (Editor) |
| <kbd>Delete</kbd> / <kbd>Backspace</kbd> | Delete Selected Item (Editor) |
| <kbd>⌘</kbd>/<kbd>Ctrl</kbd> + <kbd>Z</kbd> | Undo (Editor) |
| <kbd>⌘</kbd>/<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Z</kbd> | Redo (Editor) |
| <kbd>⌘</kbd>/<kbd>Ctrl</kbd> + <kbd>S</kbd> | Save Project (Editor) |

---

## 🏗️ Monorepo Architecture

Vwish is architected as an industrial-grade Flutter & Dart monorepo with strict package boundaries:

```
vwish/
├── lib/
│   ├── app.dart                    # App root with dark theme & routes
│   ├── main.dart                   # Composition root & MediaKit bootstrap
│   └── router/app_router.dart      # GoRouter declaration
├── packages/
│   │   # Player Core Packages
│   ├── vwish_domain/               # Pure Dart player models & state
│   ├── vwish_engine/               # libmpv / media_kit playback engine abstraction
│   ├── vwish_data/                 # Local storage, natural sorting, session cache
│   ├── vwish_ui_kit/               # OLED theme tokens, sliders, custom buttons
│   ├── vwish_platform/             # Window controls, wakelocks, native integrations
│   ├── vwish_features/             # Player screens, library views, HUD, playlists
│   │
│   │   # Editor & Vision Packages (v1.1.0)
│   ├── vwish_editor_core/          # Pure Dart timeline models, frame grid, render plan compiler
│   ├── vwish_editor_engine_api/    # Engine contracts, transport, preview & export protocols
│   ├── vwish_editor_engine/        # Native mobile rendering engine (Metal / Media3)
│   ├── vwish_transcription/        # Speech models catalog, transcription contracts & pipeline
│   └── vwish_whisper/              # On-device Whisper.cpp FFI bindings & native plugins
├── docs/
│   └── editor/                     # Architecture specification & 158-ticket build plan
└── test/                           # End-to-end and unit test suites
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10+ stable)
- Xcode (for macOS / iOS builds)
- Android Studio / Android SDK (for Android builds)
- Visual Studio C++ Build Tools (for Windows builds)

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/vecvel/vwish.git
   cd vwish
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run tests**:
   ```bash
   # Run app tests
   flutter test

   # Run editor core tests
   ./scripts/ci/editor/core.sh
   ```

4. **Launch Application**:
   ```bash
   # Run on macOS (Player)
   flutter run -d macos

   # Run on iOS with Editor enabled
   flutter run -d ios --dart-define=VWISH_EDITOR=true

   # Run on Android with Editor & AI Captions
   flutter run -d android --dart-define=VWISH_EDITOR=true --dart-define=VWISH_AUTO_CAPTIONS=true

   # Run on Windows / Linux
   flutter run -d windows
   flutter run -d linux
   ```

---

## 📄 License & Conduct

- **License**: Proprietary — Copyright © 2026 vecvel. All rights reserved. See [`LICENSE`](LICENSE) for terms.
- **Code of Conduct**: See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
