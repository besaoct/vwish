<div align="center">

# 🎬 Vwish Video Player

**Ultra-high performance, cross-platform media player powered by Flutter & libmpv.**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Engine](https://img.shields.io/badge/Engine-libmpv%20%2B%20FFmpeg-5C2D91)](https://mpv.io)
[![Platform](https://img.shields.io/badge/Platforms-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-22c55e)](#supported-platforms)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](#-sponsor--support)

</div>

---

## 🌟 Overview

**Vwish Player** is a modern desktop and mobile media player engineered for audiophiles, cinephiles, and power users. Instead of reinventing media decoding pipelines, Vwish leverages **`libmpv`** and **FFmpeg** behind a modular Flutter architecture, providing hardware-accelerated playback for virtually every container and codec available.

---

## 💖 Sponsor & Support

If you enjoy using **Vwish Player** or find our engineering helpful, consider sponsoring the project to support active development and new features:

- 💖 **GitHub Sponsors**: [github.com/sponsors/besaoct](https://github.com/sponsors/besaoct)
- ☕ **Buy Me a Coffee**: [buymeacoffee.com/besaoct](https://buymeacoffee.com/besaoct)
- 🌐 **GitHub Profile**: [github.com/besaoct](https://github.com/besaoct)

---

## ✨ Features

- ⚡ **Native Hardware Acceleration**: Zero-copy GPU decoding (`VideoToolbox` on macOS/iOS, `D3D11VA`/`NVDEC` on Windows, `VAAPI` on Linux, `MediaCodec` on Android).
- 🎚️ **10-Band Graphic Equalizer & Audio DSP**: Real-time parametric frequency equalization, EQ presets (Rock, Pop, Classical, Voice, Bass Boost), Night Mode Dynamic Range Compression (DRC), and `-16 LUFS` loudness normalization.
- 🔊 **300% Volume Booster**: Continuous volume scaling from 0% to 100% (Cyan) with a designated Amber Boost zone extending up to 300%.
- 🎨 **Deep OLED Theme & Precision Seek Bar**: Precision seeking with buffer visualization, chapter tick marks, hover time tooltips, and A-B loop band highlighting.
- 📊 **"Stats for Nerds" HUD**: Real-time diagnostics overlay detailing active video/audio codecs, framerates, dropped frames, A/V desync, color primaries, bitrate, and one-click technical report export.
- 📂 **Smart Queue & Natural Sort**: Numerical episode sorting (`Episode 2` precedes `Episode 10`), regex scene parser (`S01E02`, `1x04`, `EP03`, anime `- 07`), auto-advance circuit breaker, shuffle with seed preservation, and sidecar subtitle auto-discovery.
- 🔒 **Non-Destructive Invariant**: Vwish only stores playback cache, state, and history in sandboxed application directories. User media libraries and folders are strictly read-only.
- ⌨️ **Extensive Desktop Hotkeys & Gestures**: Smooth mouse wheel volume/seeking, drag-and-drop file targets, and full keymap navigation.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| <kbd>Space</kbd> / <kbd>K</kbd> | Play / Pause |
| <kbd>←</kbd> / <kbd>→</kbd> | Seek ±5 seconds |
| <kbd>J</kbd> / <kbd>L</kbd> | Seek ±10 seconds |
| <kbd>↑</kbd> / <kbd>↓</kbd> | Volume ±5% (boosts up to 300%) |
| <kbd>M</kbd> | Toggle Mute |
| <kbd>F</kbd> | Toggle Fullscreen |
| <kbd>T</kbd> | Pin Always on Top |
| <kbd>[</kbd> / <kbd>]</kbd> | Speed ±0.1x (0.25x – 3.0x) |
| <kbd>I</kbd> | Toggle "Stats for Nerds" Diagnostics HUD |
| <kbd>P</kbd> | Toggle Queue / Playlist Side-Sheet |
| <kbd>O</kbd> | Open File Dialog |

---

## 🏗️ Architecture

Vwish is organized as a clean, modular Flutter monorepo:

```
vwish_player/
├── lib/
│   ├── app.dart                    # MaterialApp.router with Vwish dark theme & router
│   ├── main.dart                   # Composition root & MediaKit bootstrap
│   └── router/app_router.dart      # GoRouter navigation declaration
├── packages/
│   ├── vwish_domain/               # Pure Dart domain models & immutable state
│   ├── vwish_engine/               # libmpv / media_kit playback engine abstraction
│   ├── vwish_data/                 # AppStorage, natural sort, session repositories
│   ├── vwish_ui_kit/               # OLED dark theme, seek bar, volume slider, glass cards
│   ├── vwish_platform/             # Window management, wakelocks, native file pickers
│   └── vwish_features/             # Player controllers, viewport, overlays, HUD
└── test/
    ├── domain_test.dart
    ├── scanner_test.dart
    ├── engine_test.dart
    └── widget_test.dart
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
   git clone https://github.com/besaoct/vwish.git
   cd vwish
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run tests**:
   ```bash
   flutter test
   ```

4. **Launch Application**:
   ```bash
   # Run on macOS
   flutter run -d macos

   # Run on Windows
   flutter run -d windows

   # Run on Linux
   flutter run -d linux

   # Run on Android
   flutter run -d android

   # Run on iOS Simulator
   flutter run -d ios
   ```

---

## 📄 License & Conduct

- **License**: Proprietary — Copyright © 2026 besaoct. All rights reserved. See [`LICENSE`](LICENSE) for terms.
- **Code of Conduct**: See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
