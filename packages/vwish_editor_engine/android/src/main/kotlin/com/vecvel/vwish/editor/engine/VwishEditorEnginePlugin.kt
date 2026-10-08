// OWNER: ENG-08 (minimal placeholder created by ENG-01's scaffold; frozen by ENG-06)
//
// Registers a bootstrap channel whose every call fails with `notSupportedOnDevice`, so the Dart
// engine reports `engine_not_available` until ENG-08 installs the Pigeon host APIs
// (ARCH §12.6) and the service placeholders of ARCH §4.4.

package com.vecvel.vwish.editor.engine

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VwishEditorEnginePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.vecvel.vwish.editor.engine/bootstrap").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        result.error("notSupportedOnDevice", "The native editor engine is not built yet", mapOf("retryable" to false))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
