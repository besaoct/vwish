// OWNER: AI-06 (placeholder created by AI-02's scaffold)
//
// AI-06 implements the `vwish/whisper` method channel and `vwish/whisper/events` event channel of
// ai.md §4.8 (device profile, available memory, free disk, metered network, backup exclusion,
// background tasks; thermal/memory/low-power events). Until then every call is unimplemented.

import Flutter
import UIKit

public final class VwishWhisperPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "vwish/whisper", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(VwishWhisperPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
