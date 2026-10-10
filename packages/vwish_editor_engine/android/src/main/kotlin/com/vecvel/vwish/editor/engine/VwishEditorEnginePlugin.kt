// OWNER: ENG-08 (minimal placeholder created by ENG-01; frozen by ENG-06)
//
// Registers no Pigeon host API yet, so every call from Dart fails with `channel-error`, which
// error_mapper.dart maps to `notSupportedOnDevice`: MobileEditorEngine.capabilities() reports
// `engine_not_available` and the editor shows its unsupported state. ENG-08 installs the host APIs
// generated in pigeon/EngineApi.g.kt (EngineHostApi.setUp, PreviewHostApi.setUp, JobsHostApi.setUp,
// ExportHostApi.setUp, RecorderHostApi.setUp, PlatformHostApi.setUp), the
// EngineEventsStreamHandler, and the service placeholders of ARCH §4.4.

package com.vecvel.vwish.editor.engine

import io.flutter.embedding.engine.plugins.FlutterPlugin

class VwishEditorEnginePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Intentionally empty until ENG-08 (ARCH §12.6).
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Nothing registered.
    }
}
