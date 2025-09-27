import UIKit
import Flutter
import GoogleMaps // 1. ADDED THIS IMPORT

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. ADDED THIS LINE WITH YOUR API KEY
    GMSServices.provideAPIKey("AIzaSyBVZU3B8ggds2KMSvlYNCIvW87nHoo8KJY")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
