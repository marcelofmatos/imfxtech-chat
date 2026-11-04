import UIKit
import Flutter
import FirebaseCore
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FileDropPlugin") {
      FileDropPlugin.register(with: registrar)
    }
    // Platform.isIOS continues to be true when this binary runs on an Apple
    // Silicon Mac via "Designed for iPad" (not Mac Catalyst), so Dart needs
    // ProcessInfo.isiOSAppOnMac from this channel to tell the two apart.
    // See lib/utils/platform_infos.dart (isIOSAppOnMac).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "IOSAppOnMacPlugin") {
      let channel = FlutterMethodChannel(
        name: "com.imfxtech.chat/ios_app_on_mac",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "isIOSAppOnMac":
          result(ProcessInfo.processInfo.isiOSAppOnMac)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // From https://pub.dev/packages/flutter_local_notifications#-ios-setup
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate  }
}

// The desktop_drop plugin has no iOS implementation and pasteboard does not
// read files on iOS, so drag and drop / paste of files into a chat is handled
// here and delivered to lib/utils/ios_file_drop.dart.
class FileDropPlugin: NSObject, FlutterPlugin, UIDropInteractionDelegate {
  private let channel: FlutterMethodChannel
  private weak var registrar: FlutterPluginRegistrar?
  private var dropInteraction: UIDropInteraction?

  init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
    self.channel = channel
    self.registrar = registrar
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.imfxtech.chat/file_drop",
      binaryMessenger: registrar.messenger()
    )
    let instance = FileDropPlugin(channel: channel, registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "attach":
      if dropInteraction == nil, let view = registrar?.viewController?.view {
        // Nothing else deletes the copies of earlier drops and pastes.
        try? FileManager.default.removeItem(at: Self.copiesDirectory)
        let interaction = UIDropInteraction(delegate: self)
        view.addInteraction(interaction)
        dropInteraction = interaction
      }
      result(dropInteraction != nil)
    case "detach":
      if let interaction = dropInteraction {
        interaction.view?.removeInteraction(interaction)
        dropInteraction = nil
      }
      result(nil)
    case "pasteboardFiles":
      let pasteboard = UIPasteboard.general
      // Checking the types does not trigger the iOS paste prompt, so plain
      // text paste keeps going through the regular text path.
      guard pasteboard.types.contains(where: { Self.isFileType($0) }) else {
        result([])
        return
      }
      Self.copyFiles(from: pasteboard.itemProviders) { result($0) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    session.items.contains { Self.fileType(of: $0.itemProvider) != nil }
  }

  func dropInteraction(
    _ interaction: UIDropInteraction,
    sessionDidUpdate session: UIDropSession
  ) -> UIDropProposal {
    UIDropProposal(operation: .copy)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
    channel.invokeMethod("enter", arguments: nil)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
    channel.invokeMethod("exit", arguments: nil)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
    channel.invokeMethod("exit", arguments: nil)
  }

  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    Self.copyFiles(from: session.items.map { $0.itemProvider }) { [channel] files in
      channel.invokeMethod("drop", arguments: files)
    }
  }

  // Loose text and links (a dragged text selection, a copied string) are not
  // files. Text documents still are, because they carry a file name.
  private static func isFileType(_ identifier: String, named: Bool = false) -> Bool {
    guard let type = UTType(identifier), type.conforms(to: .data) else { return false }
    return named || !(type.conforms(to: .text) || type.conforms(to: .url))
  }

  private static func fileType(of provider: NSItemProvider) -> String? {
    provider.registeredTypeIdentifiers.first {
      isFileType($0, named: provider.suggestedName != nil)
    }
  }

  private static let copiesDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("file_drop", isDirectory: true)

  // Copies every file to its own temporary directory, keeping its name, and
  // calls back on the main thread with a list of {path, mimeType}.
  private static func copyFiles(
    from providers: [NSItemProvider],
    completion: @escaping ([[String: String]]) -> Void
  ) {
    let root = copiesDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let group = DispatchGroup()
    let lock = NSLock()
    var files = [[String: String]?](repeating: nil, count: providers.count)

    for (index, provider) in providers.enumerated() {
      guard let identifier = fileType(of: provider) else { continue }
      group.enter()
      provider.loadFileRepresentation(forTypeIdentifier: identifier) { url, _ in
        defer { group.leave() }
        guard let url = url else { return }
        let type = UTType(identifier)
        let suggested = provider.suggestedName ?? url.deletingPathExtension().lastPathComponent
        var name = (suggested as NSString).lastPathComponent
        if name.isEmpty || name == "." || name == ".." {
          name = "file"
        }
        let ext = url.pathExtension.isEmpty
          ? (type?.preferredFilenameExtension ?? "")
          : url.pathExtension
        if !ext.isEmpty && !name.lowercased().hasSuffix(".\(ext.lowercased())") {
          name += ".\(ext)"
        }
        let directory = root.appendingPathComponent("\(index)", isDirectory: true)
        let destination = directory.appendingPathComponent(name)
        do {
          try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
          )
          try FileManager.default.copyItem(at: url, to: destination)
        } catch {
          NSLog("FileDropPlugin: could not copy %@: %@", url.path, error.localizedDescription)
          return
        }
        var file = ["path": destination.path]
        file["mimeType"] = type?.preferredMIMEType
        lock.lock()
        files[index] = file
        lock.unlock()
      }
    }

    group.notify(queue: .main) { completion(files.compactMap { $0 }) }
  }
}
