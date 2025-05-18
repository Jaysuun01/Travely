//
//  SignUpView.swift
//  Travely
//
//  Created by Phat is here on 5/2/25.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showVerifySheet = false
    @State private var isBusy = false
    @State private var verificationSent  = false
    
    // App theme accent color
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)

    // Password requirements
    private let passwordRequirements: [(String, (String) -> Bool)] = [
        ("At least 8 characters", { $0.count >= 8 }),
        ("At least one uppercase letter", { $0.range(of: "[A-Z]", options: .regularExpression) != nil }),
        ("At least one lowercase letter", { $0.range(of: "[a-z]", options: .regularExpression) != nil }),
        ("At least one number", { $0.range(of: "[0-9]", options: .regularExpression) != nil }),
        ("At least one special character", { $0.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil })
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isBusy { ProgressView().tint(accentColor) }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // App title and headline
                    VStack(spacing: 4) {
                        Text("Travely")
                            .font(.custom("Inter-Regular", size: 64))
                            .fontWeight(.black)
                            .foregroundColor(accentColor)
                        Text("Create Your Account")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)

                    // Form fields
                    VStack(spacing: 16) {
                        // Email
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email Address")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("name@example.com", text: $email)
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)

                        // Full Name
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Full Name")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("Enter your name", text: $fullName)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)

                        // Password
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                SecureField("Enter your password", text: $password)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)

                        // Password requirements
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(passwordRequirements.enumerated()), id: \.offset) { idx, req in
                                let met = req.1(password)
                                HStack(spacing: 8) {
                                    Image(systemName: met ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(met ? .green : .gray)
                                    Text(req.0)
                                        .font(.caption)
                                        .foregroundColor(met ? .green : .gray)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)

                        // Confirm Password
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Confirm Password")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                SecureField("Re-enter your password", text: $confirmPassword)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                    }

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            handleSignUp()
                        } label: {
                            HStack {
                                Text("SIGN UP")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                        }
                        .background(accentColor)
                        .cornerRadius(12)
                        .shadow(color: accentColor.opacity(0.5), radius: 5, x: 0, y: 2)

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .background(Color.gray.opacity(0.25))
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showVerifySheet) {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 70, height: 70)
                    Image(systemName: verificationSent ? "envelope.open.fill" : "envelope.badge.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .foregroundColor(accentColor)
                }
                .padding(.top, 16)
                // Title
                Text("Verify your e-mail")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .padding(.top, 4)

                // Message
                if verificationSent {
                    Text("Check your inbox for the link to\n\(email).\nTap it, then hit Continue.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Would you like to verify your address now?\nYou can skip and do it later in Settings.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    if verificationSent {
                        Button {
                            Task { await refreshAndDismissIfVerified() }
                        } label: {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button {
                            Task {
                                try? await viewModel.sendVerificationEmail()
                                verificationSent = true
                            }
                        } label: {
                            Text("Send verification e-mail")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    Button("Skip for now") {
                        viewModel.verificationPromptSeen = true
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemGray6).opacity(0.98))
                    .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 12)
            .presentationDetents([.medium, .large])
        }
    }
    
    private func checkEmailVerifiedAndDismiss() async {
        isBusy = true
        defer { isBusy = false }

        do {
            // 1️⃣  sign back in with the same creds you just collected
            //_ = try await Auth.auth().signIn(withEmail: email, password: password)

            guard let user = Auth.auth().currentUser else { return }

            // 2️⃣  pull the latest Auth record
            try await user.reload()

            if user.isEmailVerified {
                try await viewModel.updateUserDoc(uid: user.uid, verified: true)
                dismiss()                                // close SignUpView
            } else {
                errorMessage = "Still unverified — give it a second?"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func refreshAndDismissIfVerified() async {
        guard let user = Auth.auth().currentUser else { return }
        try? await user.reload()
        if user.isEmailVerified {
            try? await viewModel.updateUserDoc(uid: user.uid, verified: true)
            viewModel.verificationPromptSeen = true
            dismiss()               // leave SignUpView → RootView shows Home
        } else {
            errorMessage = "Still unverified — give it a sec."
        }
    }


    private func handleSignUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isBusy = true
        Auth.auth().createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                errorMessage = err.localizedDescription
                isBusy = false               // <- add this line
                return
            }
            Task {
                defer { isBusy = false }
                guard let user = result?.user else { return }
                let change = user.createProfileChangeRequest()
                change.displayName = fullName
                try? await change.commitChanges()
                viewModel.userName = fullName
                try await viewModel.createUserDoc(uid: result!.user.uid,
                                                  fullName: fullName,
                                                  emailVerified: false)
                showVerifySheet = true
            }
        }
    }
}
