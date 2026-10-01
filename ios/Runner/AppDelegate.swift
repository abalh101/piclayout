import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PicLayoutMedia") else { return }
    let channel = FlutterMethodChannel(name: "piclayout/media", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "isInstalled":
        let schemes = ["instagram": "instagram://", "snapchat": "snapchat://", "whatsapp": "whatsapp://", "facebook": "fb://"]
        guard let app = args["app"] as? String, let scheme = schemes[app], let url = URL(string: scheme) else {
          result(nil) // No reliable public installation probe for this target.
          return
        }
        result(UIApplication.shared.canOpenURL(url))
      case "shareTo":
        result(false) // iOS uses the native activity sheet for image sharing.
      case "saveToGallery":
        guard let path = args["path"] as? String, FileManager.default.fileExists(atPath: path) else {
          result(FlutterError(code: "file_missing", message: nil, details: nil)); return
        }
        let save = {
          PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: path))
          }) { success, error in
            DispatchQueue.main.async {
              if success { result(nil) }
              else { result(FlutterError(code: "save_failed", message: error?.localizedDescription, details: nil)) }
            }
          }
        }
        if #available(iOS 14, *) {
          PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized || status == .limited { save() }
            else { DispatchQueue.main.async { result(FlutterError(code: "permission_denied", message: nil, details: nil)) } }
          }
        } else {
          PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized { save() }
            else { DispatchQueue.main.async { result(FlutterError(code: "permission_denied", message: nil, details: nil)) } }
          }
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
}
