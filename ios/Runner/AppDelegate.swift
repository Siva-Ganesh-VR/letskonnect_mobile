import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FlutterViewController builds its own view, so the storyboard background is
    // not always what shows between the launch screen being torn down and
    // Flutter's first frame. Tint the window to the launch screen teal so that
    // gap can never flash white.
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    window?.backgroundColor = UIColor(red: 0.078, green: 0.722, blue: 0.651, alpha: 1)
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
