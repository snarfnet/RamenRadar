import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

@main
struct RamenRadarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active && !attRequested {
                        attRequested = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            ATTrackingManager.requestTrackingAuthorization { status in
                                print("ATT status: \(status.rawValue)")
                            }
                        }
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}
