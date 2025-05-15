//
//  AppViewModel.swift
//  Travely
//
//  Created by Ather Ahmed on 3/11/25.
//  Modified by Phat on 5/10/25

import Foundation
import FirebaseAuth
import SwiftUI
import Network

class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isBioAuth = false
    @Published var userName: String? = nil
    @Published var isConnected = true // Network connectivity status

    @AppStorage("biometricEnabled") var biometricEnabled: Bool = false
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")

    init() {
        setupAuthStateListener()
        startNetworkMonitoring()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        networkMonitor.cancel()
    }

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    print("✅ Auth state changed: signed in as", user.uid)
                    self.userName = user.displayName ?? user.email
                    self.isAuthenticated = true
                } else {
                    print("ℹ️ Auth state changed: signed out")
                    self.isAuthenticated = false
                    self.isBioAuth = false
                    self.userName = nil
                }
            }
        }
    }

    func initializeAuthState() {
        if let user = Auth.auth().currentUser {
            self.userName = user.displayName ?? user.email
            self.isAuthenticated = true
        }
    }

    func signIn(with displayName: String?) {
        self.userName = displayName
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            biometricEnabled = false
        } catch {
            print("❌ Error signing out:", error)
        }
    }

    // Email Handling

    func changeEmail(to newEmail: String) {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No user signed in.")
            return
        }

        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { [weak self] error in
            if let error = error {
                print("❌ Failed to send verification for email update:", error.localizedDescription)
            } else {
                print("✅ Email updated to \(newEmail)")
                self?.userName = newEmail

                user.sendEmailVerification { error in
                    if let error = error {
                        print("❌ Failed to send verification email:", error.localizedDescription)
                    } else {
                        print("📧 Verification email sent to \(newEmail)")
                    }
                }
            }
        }
    }

    // Full Name Handling
    
    func updateFullName(to newFullName: String) {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No user signed in.")
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newFullName
        
        changeRequest.commitChanges { [weak self] error in
            if let error = error {
                print("❌ Failed to update display name:", error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self?.userName = newFullName
                    print("✅ Display name updated to \(newFullName)")
                }
            }
        }
    }

    // Password Handling

    func changePassword(new: String, confirm: String) {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No user signed in.")
            return
        }

        if new != confirm {
            print("❌ Passwords do not match.")
            return
        }

        user.updatePassword(to: new) { error in
            if let error = error {
                print("❌ Failed to update password:", error.localizedDescription)
            } else {
                print("🔐 Password successfully updated.")
            }
        }
    }

    // Data/Account Deletion

    func deleteUserData() {
        print("🗑️ User data deletion logic triggered.")
        // Add Firestore deletion logic if applicable
    }

    func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No user signed in.")
            return
        }

        user.delete { error in
            if let error = error as NSError? {
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("⚠️ Re-authentication required to delete account.")
                    // Implement re-authentication flow here
                } else {
                    print("❌ Failed to delete account:", error.localizedDescription)
                }
            } else {
                print("🧨 Account successfully deleted.")
                self.biometricEnabled = false
            }
        }
    }

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                print("Network connectivity changed: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
}

