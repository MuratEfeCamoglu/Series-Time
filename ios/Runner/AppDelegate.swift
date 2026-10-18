import Flutter
import UIKit

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SezonlukAppIcon") {
      registerAppIconChannel(messenger: registrar.messenger())
    }
  }

  // F22: Ayarlar › Uygulama simgesi. Sarı ana simgedir (nil); diğerleri Assets.xcassets'teki
  // AppIcon-<Renk> setleridir (ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS).
  private static let icons = ["yellow", "purple", "blue", "green", "red", "orange"]

  private func registerAppIconChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "sezonluk/app_icon", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "current":
        let alternate = UIApplication.shared.alternateIconName
        result(alternate?.replacingOccurrences(of: "AppIcon-", with: "").lowercased() ?? "yellow")
      case "set":
        guard UIApplication.shared.supportsAlternateIcons,
          let args = call.arguments as? [String: Any],
          let name = args["name"] as? String,
          AppDelegate.icons.contains(name)
        else {
          result(FlutterError(code: "invalid_icon", message: "Bilinmeyen simge", details: nil))
          return
        }
        let iconName = name == "yellow" ? nil : "AppIcon-\(name.capitalized)"
        UIApplication.shared.setAlternateIconName(iconName) { error in
          if let error = error {
            result(FlutterError(code: "icon_failed", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
