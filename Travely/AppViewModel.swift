//
//  AppViewModel.swift
//  Travely
//
//  Created by Ather Ahmed on 3/11/25.
//  Modified by Phat on 5/10/25

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import Network

@MainActor
class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @AppStorage("verificationPromptSeen") var verificationPromptSeen: Bool = false { didSet { recomputeAuth() }}
    private var signedInAccordingToFirebase = false { didSet { recomputeAuth() } }
    @Published var isBioAuth = false
    @Published var userName: String? = nil
    @Published var isConnected = true // Network connectivity status
    @Published var emailVerified = false
    private var userListener: ListenerRegistration?
    @Published var notifications: [AppNotification] = []
    private let db = Firestore.firestore()

    @AppStorage("biometricEnabled") var biometricEnabled: Bool = false
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")

    init() {
        setupAuthStateListener()
        startNetworkMonitoring()
        if let u = Auth.auth().currentUser {
            Task { await refreshState(for: u) }
        }
        loadNotifications() // Load notifications when view model is initialized
        NotificationCenter.default.addObserver(forName: .locationNotificationDelivered, object: nil, queue: .main) { [weak self] notif in
            guard let userInfo = notif.userInfo,
                  let title = userInfo["title"] as? String,
                  let body = userInfo["body"] as? String,
                  let date = userInfo["date"] as? Date else { return }
            let message = body
            let notification = AppNotification(
                id: UUID().uuidString,
                title: title,
                message: message,
                date: date,
                isRead: false
            )
            self?.addNotification(notification)
        }
        NotificationCenter.default.addObserver(forName: .locationNotificationScheduled, object: nil, queue: .main) { [weak self] notif in
            guard let userInfo = notif.userInfo,
                  let title = userInfo["title"] as? String,
                  let body = userInfo["body"] as? String,
                  let date = userInfo["date"] as? Date else { return }
            let message = body
            let notification = AppNotification(
                id: UUID().uuidString,
                title: title,
                message: message,
                date: date,
                isRead: false
            )
            self?.addNotification(notification)
        }
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
                    self.signedInAccordingToFirebase = true
                } else {
                    print("ℹ️ Auth state changed: signed out")
                    self.signedInAccordingToFirebase = false
                    self.isBioAuth = false
                    self.userName = nil
                    self.verificationPromptSeen = false
                }
                
                Task { await self.refreshState(for: user) }
            }
        }
    }

    func initializeAuthState() {
        if let user = Auth.auth().currentUser {
            self.userName = user.displayName ?? user.email
            self.signedInAccordingToFirebase = true
        }
    }

    func signIn(with displayName: String?) {
        self.userName = displayName
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            biometricEnabled = false
            verificationPromptSeen = false
            notifications.removeAll() // Clear notifications on sign out
        } catch {
            print("❌ Error signing out:", error)
        }
    }
    
    private func recomputeAuth() {
        // User counts as "authenticated" only when BOTH are true
        isAuthenticated = signedInAccordingToFirebase && verificationPromptSeen
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

    func deleteAccount(onReauthRequired: (() -> Void)? = nil) {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No user signed in.")
            return
        }

        user.delete { error in
            if let error = error as NSError? {
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    print("⚠️ Re-authentication required to delete account.")
                    onReauthRequired?()
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
    
    // Verification Email Funcs
    
    func sendVerificationEmail() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }
    
    func createUserDoc(uid: String, fullName: String, emailVerified: Bool) async throws {
        try await Firestore.firestore().collection("users")
            .document(uid)
            .setData([
                "fullName": fullName,
                "emailVerified": emailVerified,
                "createdAt": FieldValue.serverTimestamp()
            ])
    }

    func updateUserDoc(uid: String, verified: Bool) async throws {
        try await Firestore.firestore().collection("users")
            .document(uid)
            .updateData(["emailVerified": verified])
    }
    
    private func refreshState(for user: FirebaseAuth.User?) async {
        userListener?.remove()

        guard let user else {             // signed out
            isAuthenticated = false
            emailVerified   = false
            return
        }

        // 1️⃣  Firestore listener keeps the flag in real-time
        userListener = Firestore.firestore()
            .collection("users").document(user.uid)
            .addSnapshotListener { [weak self] snap, _ in
                let verified = (snap?.data()?["emailVerified"] as? Bool) ?? false
                self?.emailVerified = verified
                if verified { self?.verificationPromptSeen = true }
            }

        // 2️⃣  Make sure Auth and Firestore agree whenever app launches
        try? await user.reload()
        if user.isEmailVerified {
            try? await Firestore.firestore()
                  .collection("users")
                  .document(user.uid)
                  .setData(["emailVerified": true], merge: true)
            verificationPromptSeen = true
        }
    }
    
    @MainActor
    func refreshAuthIfNeeded() async {
        guard let user = Auth.auth().currentUser else { return }
        try? await user.reload()
        userName = user.displayName ?? user.email

        // If the user *just* verified, mirror it to Firestore and the UI
        if user.isEmailVerified {
            verificationPromptSeen = true           // unlock router
            try? await Firestore.firestore()
                  .collection("users")
                  .document(user.uid)
                  .setData(["emailVerified": true], merge: true)
        }
    }

    private func addNotification(_ notification: AppNotification) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Add to local array
        notifications.append(notification)
        notifications.sort { $0.date > $1.date }
        
        // Add to Firebase
        do {
            let notificationData = try Firestore.Encoder().encode(notification)
            db.collection("users").document(userId).collection("notifications").document(notification.id).setData(notificationData)
        } catch {
            print("❌ Error saving notification to Firebase:", error)
        }
    }

    func clearNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Clear local array
        notifications.removeAll()
        
        // Clear from Firebase
        db.collection("users").document(userId).collection("notifications").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error getting notifications:", error)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            for document in documents {
                document.reference.delete { error in
                    if let error = error {
                        print("❌ Error deleting notification:", error)
                    }
                }
            }
        }
    }

    func loadNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("notifications")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error loading notifications:", error)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.notifications = documents.compactMap { document -> AppNotification? in
                    try? document.data(as: AppNotification.self)
                }
            }
    }

    func updateNotificationReadStatus(_ notification: AppNotification) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Update local state
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
        
        // Update Firestore
        db.collection("users").document(userId).collection("notifications").document(notification.id).updateData([
            "isRead": true
        ])
    }

    func deleteNotification(at indexSet: IndexSet) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        for index in indexSet {
            let notification = notifications[index]
            // Delete from Firestore
            db.collection("users").document(userId).collection("notifications").document(notification.id).delete()
        }
        
        // Update local state
        notifications.remove(atOffsets: indexSet)
    }

    func ensureUserDocument() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        userRef.setData([
            "email": user.email ?? "",
            "fullName": user.displayName ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func sendOwnerNotification(tripId: String, message: String) {
        // Fetch the trip to get the ownerId and tripName
        db.collection("trips").document(tripId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let ownerId = data["ownerId"] as? String,
                  let tripName = data["tripName"] as? String else { return }
            // Only send if the current user is NOT the owner
            if ownerId == Auth.auth().currentUser?.uid { return }
            let notification = AppNotification(
                id: UUID().uuidString,
                title: "Collaboration Update",
                message: message,
                date: Date(),
                isRead: false,
                type: "collab-status"
            )
            do {
                let notificationData = try Firestore.Encoder().encode(notification)
                self.db.collection("users").document(ownerId).collection("notifications").document(notification.id).setData(notificationData)
            } catch {
                print("❌ Error sending owner notification: \(error)")
            }
        }
    }

    func acceptTripInvitation(notification: AppNotification) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        let tripQuery = db.collection("trips").whereField("pendingInvites", arrayContains: email)
        tripQuery.getDocuments { snapshot, error in
            guard let tripDoc = snapshot?.documents.first else {
                self.deleteNotificationById(notification.id)
                return
            }
            let tripId = tripDoc.documentID
            let userName = user.displayName ?? email
            let tripRef = self.db.collection("trips").document(tripId)
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let tripSnapshot: DocumentSnapshot
                do {
                    try tripSnapshot = transaction.getDocument(tripRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                guard var pendingInvites = tripSnapshot.get("pendingInvites") as? [String],
                      var collaborators = tripSnapshot.get("collaborators") as? [String],
                      let tripName = tripSnapshot.get("tripName") as? String else {
                    return nil
                }
                // Only proceed if user is still pending and not already a collaborator
                if !pendingInvites.contains(email) || collaborators.contains(email) {
                    return nil
                }
                // Update arrays
                pendingInvites.removeAll { $0 == email }
                collaborators.append(email)
                transaction.updateData([
                    "pendingInvites": pendingInvites,
                    "collaborators": collaborators
                ], forDocument: tripRef)
                // Send notification to owner (outside transaction)
                DispatchQueue.main.async {
                    self.sendOwnerNotification(tripId: tripId, message: "\(userName) accepted your invitation to collaborate on trip '\(tripName)'.")
                    self.deleteNotificationById(notification.id)
                }
                return nil
            }) { (_, error) in
                if let error = error {
                    print("❌ Transaction error (accept):", error)
                }
            }
        }
    }

    func declineTripInvitation(notification: AppNotification) {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        let tripQuery = db.collection("trips").whereField("pendingInvites", arrayContains: email)
        tripQuery.getDocuments { snapshot, error in
            guard let tripDoc = snapshot?.documents.first else {
                self.deleteNotificationById(notification.id)
                return
            }
            let tripId = tripDoc.documentID
            let userName = user.displayName ?? email
            let tripRef = self.db.collection("trips").document(tripId)
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let tripSnapshot: DocumentSnapshot
                do {
                    try tripSnapshot = transaction.getDocument(tripRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                guard var pendingInvites = tripSnapshot.get("pendingInvites") as? [String],
                      let collaborators = tripSnapshot.get("collaborators") as? [String],
                      let tripName = tripSnapshot.get("tripName") as? String else {
                    return nil
                }
                // Only proceed if user is still pending and NOT already a collaborator
                if !pendingInvites.contains(email) || collaborators.contains(email) {
                    return nil
                }
                // Update arrays
                pendingInvites.removeAll { $0 == email }
                transaction.updateData([
                    "pendingInvites": pendingInvites
                ], forDocument: tripRef)
                // Send notification to owner (outside transaction)
                DispatchQueue.main.async {
                    self.sendOwnerNotification(tripId: tripId, message: "\(userName) declined your invitation to collaborate on trip '\(tripName)'.")
                    self.deleteNotificationById(notification.id)
                }
                return nil
            }) { (_, error) in
                if let error = error {
                    print("❌ Transaction error (decline):", error)
                }
            }
        }
    }

    func deleteNotificationById(_ notificationId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).collection("notifications").document(notificationId).delete()
        // Update local state
        notifications.removeAll { $0.id == notificationId }
    }

}

