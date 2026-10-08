// OWNER: ENG-07 (minimal placeholder created by ENG-01's scaffold; frozen by ENG-06)
//
// Registers a bootstrap channel whose every call fails with `notSupportedOnDevice`, so the Dart
// engine reports `engine_not_available` until ENG-07 installs the Pigeon host APIs
// (ARCH §12.6) and the service placeholders of ARCH §4.4.

import Flutter
import UIKit

public final class VwishEditorEnginePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.vecvel.vwish.editor.engine/bootstrap",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(VwishEditorEnginePlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterError(
      code: "notSupportedOnDevice",
      message: "The native editor engine is not built yet",
      details: ["retryable": false]))
  }
}
