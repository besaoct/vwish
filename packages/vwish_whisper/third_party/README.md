<!-- OWNER: AI-01. Documented placeholder: whisper.cpp is NOT downloaded by the scaffold. -->
# third_party/whisper.cpp (not vendored yet)

AI-01 vendors **whisper.cpp v1.9.4** (commit `927cfce34f31707e17f2bff35c349632fb9e2c3a`,
ggml 0.23.0), pruned to about 7.8 MB / 192 files, into `third_party/whisper.cpp/` with
`third_party/VENDORED.md` (commit, tarball sha256, pruning list), the reproducible
`tool/vendor_whisper.sh` and `LICENSE-THIRD-PARTY.md` (MIT notices for whisper.cpp and ggml).
AI-01 also reviews the v1.9.5 changelog (`d1be6fde`, 2026-10-06) and either re-pins (updating
ARCH §16.1) or records why v1.9.4 stays.

Until then the plugin builds without any native library: `WhisperRuntime.open()` reports
`unsupported(libraryUnavailable)` on iOS/Android and `unsupported(platform)` on desktop. Models are
never bundled; they are downloaded on first use after consent (ARCH §16.2–§16.3).
