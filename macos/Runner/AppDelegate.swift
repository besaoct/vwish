import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static var pendingMedia: String?
  static var mediaChannel: FlutterMethodChannel?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    if let file = filenames.first {
      AppDelegate.pendingMedia = file
      AppDelegate.mediaChannel?.invokeMethod("onOpenMedia", arguments: file)
    }
    sender.reply(toOpenOrPrint: .success)
  }

  static func setupMediaChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "vwish/media_intent", binaryMessenger: messenger)
    mediaChannel = channel
    channel.setMethodCallHandler { (call, result) in
      if call.method == "getInitialMedia" {
        let media = AppDelegate.pendingMedia
        AppDelegate.pendingMedia = nil
        result(media)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    if let pending = AppDelegate.pendingMedia {
      channel.invokeMethod("onOpenMedia", arguments: pending)
    }
  }
}
