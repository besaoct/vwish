<!-- Scaffold stub; owners: ENG-01 (Dart), ENG-07 (iOS), ENG-08 (Android), ENG-09 (example + CI). -->
# vwish_editor_engine

Flutter plugin (iOS + Android) implementing `vwish_editor_engine_api` (ARCH §4.4, §12–§15):
AVFoundation + Core Image/Metal on iOS, AndroidX Media3 on Android, hardware H.264/H.265, no
FFmpeg. Desktop is not declared; a later `vwish_editor_engine_desktop` implements the same API.

Scaffold state: the native plugin classes register a bootstrap channel that answers
`notSupportedOnDevice`, so `MobileEditorEngine.capabilities()` reports `engine_not_available`.
ENG-01 adds the Pigeon surface (`pigeons/engine_api.dart`, generated code committed), ENG-07/ENG-08
the native glue and service placeholders, ENG-09 the example host and CI scripts; ENG-06 freezes
the surface after the IOS-01/AND-01 spikes (D-42).
