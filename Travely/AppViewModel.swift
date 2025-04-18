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
    
    @AppStorage("biometricEnabled") var biometricEnabled = false

    func initializeAuthState() {
        self.isAuthenticated = Auth.auth().currentUser != nil
    }

    func signIn(with displayName: String?) {
        self.userName = displayName
        self.isAuthenticated = true
    }

    func signOut() {
        do {
            try? Auth.auth().signOut()
            biometricEnabled = false
            isAuthenticated = false
            isBioAuth = false
            userName = nil
        }
    }
}
