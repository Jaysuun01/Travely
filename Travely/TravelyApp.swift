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
import LocalAuthentication

struct RootView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        Group {
            if !viewModel.isAuthenticated {
                // Not signed in - show login
                LoginView()
            } else if viewModel.biometricEnabled && !viewModel.isBioAuth {
                // Signed in but needs Face ID - show Face ID
                Color.clear.onAppear {
                    authenticateBiometrics()
                }
            } else {
                // Signed in and Face ID passed (or not needed) - show main app
                ContentView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                viewModel.initializeAuthState()
            }
        }
    }
    
    private func authenticateBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Use Face ID to access your account"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Face ID successful - showing main app")
                        viewModel.isBioAuth = true
                    } else if let error = error {
                        print("❌ Face ID failed:", error.localizedDescription)
                        // On failure, sign out
                        viewModel.signOut()
                    }
                }
            }
        } else {
            print("⚠️ Face ID not available:", error?.localizedDescription ?? "Unknown error")
            // If Face ID isn't available, disable it and continue
            viewModel.biometricEnabled = false
            viewModel.isBioAuth = true
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

        // Configure Firebase
        FirebaseApp.configure(options: options)
        
        // Check for existing sign-in
        if let user = Auth.auth().currentUser {
            print("✅ Found existing sign-in for user:", user.uid)
        }
        
        print("✅ Firebase configured, clientID =", FirebaseApp.app()?.options.clientID ?? "nil")
        return true
    }
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}
