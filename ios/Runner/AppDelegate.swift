import Flutter
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var photoPicker: PhotoPickerSession?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PicLayoutMedia") else {
      return
    }
    let channel = FlutterMethodChannel(name: "piclayout/media", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: nil, details: nil))
        return
      }
      let arguments = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "pickPhotos":
        guard let limit = arguments["limit"] as? Int, (1...20).contains(limit),
              photoPicker == nil, let presenter = activePresenter() else {
          result(FlutterError(code: "picker_unavailable", message: nil, details: nil))
          return
        }
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = limit
        configuration.selection = .ordered
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.modalPresentationStyle = .fullScreen
        let session = PhotoPickerSession { [weak self] value in
          self?.photoPicker = nil
          result(value)
        }
        photoPicker = session
        picker.delegate = session
        presenter.present(picker, animated: true)
      case "shareFile", "saveToGallery":
        guard let path = arguments["path"] as? String,
              FileManager.default.fileExists(atPath: path) else {
          result(FlutterError(code: "file_missing", message: nil, details: nil))
          return
        }
        let file = URL(fileURLWithPath: path)
        if call.method == "shareFile" {
          share(file, arguments: arguments, result: result)
        } else {
          saveToGallery(file, result: result)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func activePresenter() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive && $0.keyWindow != nil }
    var presenter = scene?.keyWindow?.rootViewController
    while let presented = presenter?.presentedViewController {
      guard !presented.isBeingPresented, !presented.isBeingDismissed else { return nil }
      presenter = presented
    }
    guard presenter?.viewIfLoaded?.window != nil else { return nil }
    return presenter
  }

  private func share(_ file: URL, arguments: [String: Any], result: @escaping FlutterResult) {
    guard let presenter = activePresenter(), let view = presenter.viewIfLoaded,
          !view.bounds.isEmpty else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    let controller = UIActivityViewController(activityItems: [file], applicationActivities: nil)
    if let popover = controller.popoverPresentationController {
      let origin = CGRect(
        x: arguments["x"] as? Double ?? 0, y: arguments["y"] as? Double ?? 0,
        width: arguments["width"] as? Double ?? 0, height: arguments["height"] as? Double ?? 0
      )
      let visibleOrigin = view.convert(origin, from: view.window).intersection(view.bounds)
      popover.sourceView = view
      if visibleOrigin.isEmpty || visibleOrigin.isNull {
        popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        popover.permittedArrowDirections = []
      } else {
        popover.sourceRect = visibleOrigin
      }
    }
    controller.completionWithItemsHandler = { _, _, _, error in
      if let error {
        result(FlutterError(code: "share_failed", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
    presenter.present(controller, animated: true)
  }

  private func saveToGallery(_ file: URL, result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        DispatchQueue.main.async {
          result(FlutterError(code: "permission_denied", message: nil, details: nil))
        }
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: file, options: nil)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(nil)
          } else {
            result(FlutterError(code: "save_failed", message: error?.localizedDescription, details: nil))
          }
        }
      }
    }
  }
}

private final class PhotoPickerSession: NSObject, PHPickerViewControllerDelegate {
  private let complete: FlutterResult
  private var didFinish = false

  init(complete: @escaping FlutterResult) {
    self.complete = complete
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    guard !didFinish else { return }
    didFinish = true
    picker.dismiss(animated: true) {
      guard !results.isEmpty else {
        self.complete([String]())
        return
      }
      let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("piclayout_picker_\(UUID().uuidString)", isDirectory: true)
      self.copyPhotos(results, into: directory, paths: [])
    }
  }

  private func copyPhotos(_ photos: [PHPickerResult], into directory: URL, paths: [String]) {
    guard paths.count < photos.count else {
      complete(paths)
      return
    }
    let provider = photos[paths.count].itemProvider
    guard let type = provider.registeredTypeIdentifiers.compactMap({ UTType($0) })
      .first(where: { $0.conforms(to: .image) }) else {
      fail(directory)
      return
    }
    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
      var path: String?
      if let url, error == nil {
        let folder = directory.appendingPathComponent(String(paths.count), isDirectory: true)
        let suggestedName = provider.suggestedName.map { ($0 as NSString).lastPathComponent }
        let stem = suggestedName.map { ($0 as NSString).deletingPathExtension }
        let base = stem.flatMap { $0.isEmpty || $0 == "." || $0 == ".." ? nil : $0 } ?? "Photo"
        let fileExtension = url.pathExtension.isEmpty ? type.preferredFilenameExtension : url.pathExtension
        let target = folder.appendingPathComponent(base)
        let destination = fileExtension.map { target.appendingPathExtension($0) } ?? target
        do {
          try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
          // The provider removes its temporary file when this callback returns.
          try FileManager.default.copyItem(at: url, to: destination)
          path = destination.path
        } catch {
          path = nil
        }
      }
      let copiedPath = path
      DispatchQueue.main.async {
        if let copiedPath {
          self.copyPhotos(photos, into: directory, paths: paths + [copiedPath])
        } else {
          self.fail(directory)
        }
      }
    }
  }

  private func fail(_ directory: URL) {
    try? FileManager.default.removeItem(at: directory)
    complete(FlutterError(code: "photo_copy_failed", message: nil, details: nil))
  }
}
