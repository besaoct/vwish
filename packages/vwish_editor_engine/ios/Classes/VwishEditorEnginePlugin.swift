// OWNER: ENG-07 (minimal placeholder created by ENG-01; frozen by ENG-06)
//
// Registers no Pigeon host API yet, so every call from Dart fails with `channel-error`, which
// error_mapper.dart maps to `notSupportedOnDevice`: MobileEditorEngine.capabilities() reports
// `engine_not_available` and the editor shows its unsupported state. ENG-07 installs the host APIs
// generated in Classes/Pigeon/EngineApi.g.swift (EngineHostApiSetup, PreviewHostApiSetup,
// JobsHostApiSetup, ExportHostApiSetup, RecorderHostApiSetup, PlatformHostApiSetup), the
// EngineEventsStreamHandler, and the service placeholders of ARCH §4.4.

import Flutter
import UIKit

public final class VwishEditorEnginePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Intentionally empty until ENG-07 (ARCH §12.6).
  }
}
