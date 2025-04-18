//
//  AppViewModel.swift
//  Travely
//
//  Created by Ather Ahmed on 3/11/25.
//
import Foundation
import FirebaseAuth
import SwiftUI

class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isBioAuth = false
    @Published var userName: String? = nil
    
    @AppStorage("biometricEnabled") var biometricEnabled: Bool = false
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // biometricEnabled is already stored in @AppStorage
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    print("✅ Auth state changed: signed in as", user.uid)
                    self.userName = user.displayName
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
        // Check if we have a Firebase user
        if let user = Auth.auth().currentUser {
            self.userName = user.displayName
            self.isAuthenticated = true
            // isBioAuth will be false by default, requiring Face ID if enabled
        }
    }

    func signIn(with displayName: String?) {
        self.userName = displayName
        // isAuthenticated will be set by auth state listener
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // State reset will be handled by auth state listener
            biometricEnabled = false
        } catch {
            print("❌ Error signing out:", error)
        }
    }
}
