<!-- Scaffold stub; owners: AI-01 (vendoring), AI-02 (package, C ABI), AI-03 (shim), AI-04/AI-05 (native builds), AI-06 (device channel), AI-07 (runtime). -->
# vwish_whisper

FFI plugin (iOS + Android only) exposing on-device whisper.cpp through the C ABI in
`src/vw_whisper.h` (version 1; ai.md §4.5, with `vw_model_get_state` renamed from the design's
`vw_model_state`, which collided with the enum typedef). Bindings: `dart run ffigen --config
ffigen.yaml` → `lib/src/ffi/vw_whisper_bindings.g.dart` (committed). See `third_party/README.md`.
