//
//  TravelyApp.swift
//  Travely
//
//  Created by Ather Ahmed on 2/26/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct RootView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        Group {
            if viewModel.isAuthenticated && (!viewModel.biometricEnabled || viewModel.isBioAuth) {
                ContentView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                viewModel.initializeAuthState()
            }
        }
    }
}

@main
struct TravelyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var viewModel = AppViewModel()

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

extension UIApplication {
    /// Returns the top-most `UIViewController` in the key window's hierarchy.
    static var topViewController: UIViewController? {
        guard let scene = shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var vc = window.rootViewController
        else { return nil }

        while let presented = vc.presentedViewController {
            vc = presented
        }
        return vc
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            var options = FirebaseOptions(contentsOfFile: path)
        else {
            fatalError("⚠️  Could not load Firebase plist")
        }

        // 🔑  Force options.bundleID to match *this* build's bundle identifier
        options.bundleID = Bundle.main.bundleIdentifier!

        FirebaseApp.configure(options: options)
        print("✅ Firebase configured, clientID =", FirebaseApp.app()?.options.clientID ?? "nil")
        return true
    }
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}
