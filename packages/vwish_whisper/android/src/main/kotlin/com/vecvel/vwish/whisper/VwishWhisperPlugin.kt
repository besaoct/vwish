// OWNER: AI-06 (placeholder created by AI-02's scaffold)
//
// AI-06 implements the `vwish/whisper` method channel and `vwish/whisper/events` event channel of
// ai.md §4.8 (device profile, available memory, free disk, metered network, thermal/memory/low-power
// events). Until then every call is unimplemented.

package com.vecvel.vwish.whisper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VwishWhisperPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "vwish/whisper").also { it.setMethodCallHandler(this) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) = result.notImplemented()

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
