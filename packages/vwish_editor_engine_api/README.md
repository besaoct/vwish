<!-- Scaffold stub; owner: API-01 (API-02 plan sync/transport, API-03 reference renderer, API-04 render prep). -->
# vwish_editor_engine_api

The editor's engine contract (ARCH §12): `EditorEngine`, preview sessions, media services and
jobs, export (incl. `whenDetached`, `resume`, `consumeJobRecord`; D-22, D-39), recorder,
platform services, capabilities (`tier`, `maxVisualSequences`, `maxTextureSize`) and typed
failures. Pure Flutter, no native code. `package:vwish_editor_engine_api/testing.dart` exports
`FakeEditorEngine` and the framework-free contract kit `checkEngineContract`.
