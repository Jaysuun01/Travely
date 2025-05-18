import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    
    @State private var newEmail = ""
    @State private var tempEmail = ""
    @State private var tempFullName = ""
    @State private var showingPasswordChange = false
    @State private var showingFullNamePopup = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteDataAlert = false
    @State private var showingInvalidEmailAlert = false
    @State private var showingInvalidNameAlert = false
    @State private var showingPasswordMismatchAlert = false
    @State private var showingEmailPopup = false
    @State private var showingEditSheet = false
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    
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
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Section
                    ScrollView {
                        VStack(spacing: 32) {
                            // Profile Image
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(accentColor)
                                .padding(.top, 20)
                            
                            // User Information Section
                            VStack(spacing: 16) {
                                // Full Name
                                if let userName = viewModel.userName {
                                    Text(userName)
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                                
                                // Email (partially hidden)
                                if let email = Auth.auth().currentUser?.email {
                                    HStack {
                                        Text("Email:")
                                            .foregroundColor(.gray)
                                        
                                        Text(maskEmail(email))
                                            .foregroundColor(.white)
                                    }
                                    .font(.subheadline)
                                }
                                
                                // Account Status
                                HStack {
                                    Text("Account Status:")
                                        .foregroundColor(.gray)
                                    
                                    if let isVerified = Auth.auth().currentUser?.isEmailVerified, isVerified {
                                        Label("Verified", systemImage: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Label("Unverified", systemImage: "exclamationmark.triangle.fill")
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .font(.subheadline)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Security Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Security")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 16) {
                                    Toggle("Enable Face ID", isOn: Binding(
                                        get: { viewModel.biometricEnabled },
                                        set: { newValue in
                                            if newValue {
                                                // Verify device supports Face ID before enabling
                                                checkAndEnableBiometrics()
                                            } else {
                                                viewModel.biometricEnabled = false
                                            }
                                        }
                                    ))
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .toggleStyle(SwitchToggleStyle(tint: accentColor))
                                    
                                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .toggleStyle(SwitchToggleStyle(tint: accentColor))
                                    
                                    Button(action: {
                                        showingPasswordChange = true
                                    }) {
                                        HStack {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(accentColor)
                                            Text("Change Password")
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        tempEmail = ""
                                        showingEmailPopup = true
                                    }) {
                                        HStack {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(accentColor)
                                            Text("Change Email")
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    
                                    VerifyEmailButton(accentColor: accentColor)
                                        .environmentObject(viewModel)
                                    
                                    Button(action: {
                                        tempFullName = viewModel.userName ?? ""
                                        showingFullNamePopup = true
                                    }) {
                                        HStack {
                                            Image(systemName: "person.text.rectangle.fill")
                                                .foregroundColor(accentColor)
                                            Text("Change Full Name")
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Danger Zone
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Danger Zone")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 16) {
                                    Button(action: {
                                        showingDeleteDataAlert = true
                                    }) {
                                        HStack {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                            Text("Delete User Data")
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        showingDeleteAccountAlert = true
                                    }) {
                                        HStack {
                                            Image(systemName: "person.crop.circle.badge.xmark")
                                                .foregroundColor(.red)
                                            Text("Delete Account")
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Log Out Button (Moved here from bottom)
                            Button(action: {
                                viewModel.signOut()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .imageScale(.large)
                                    Text("Log Out")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .padding(.top, 20)
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingPasswordChange) {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(accentColor)
                        
                        Text("Change Password")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    // Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            SecureField("", text: $newPassword)
                                .padding()
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("newPasswordField")
                        }
                        
                        // Password requirements tracker
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(passwordRequirements.enumerated()), id: \.offset) { idx, req in
                                let met = req.1(newPassword)
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            SecureField("", text: $confirmPassword)
                                .padding()
                                .background(Color.white.opacity(0.07))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("confirmPasswordField")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Password match indicator
                    if !confirmPassword.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: newPassword == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(newPassword == confirmPassword ? .green : .red)
                            Text(newPassword == confirmPassword ? "Passwords match" : "Passwords don't match")
                                .font(.caption)
                                .foregroundColor(newPassword == confirmPassword ? .green : .red)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            if newPassword == confirmPassword {
                                viewModel.changePassword(new: newPassword, confirm: confirmPassword)
                                showingPasswordChange = false
                            } else {
                                showingPasswordMismatchAlert = true
                            }
                        }) {
                            Text("Update Password")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(12)
                        }
                        .disabled(!passwordRequirementsMet() || newPassword != confirmPassword)
                        .opacity(passwordRequirementsMet() && newPassword == confirmPassword ? 1.0 : 0.5)
                        
                        Button("Cancel") {
                            showingPasswordChange = false
                        }
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingEmailPopup) {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.badge.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(accentColor)
                        
                        Text("Update Email Address")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Email Address")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextField("", text: $tempEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Explanation text
                    Text("A verification will be sent to this email. You'll need to verify it before the change is complete.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            if isValidEmail(tempEmail) {
                                viewModel.changeEmail(to: tempEmail)
                                newEmail = tempEmail
                                showingEmailPopup = false
                            } else {
                                showingInvalidEmailAlert = true
                            }
                        }) {
                            Text("Update Email")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(12)
                        }
                        
                        Button("Cancel") {
                            tempEmail = ""
                            showingEmailPopup = false
                        }
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingFullNamePopup) {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(accentColor)
                        
                        Text("Update Full Name")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Full Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextField("", text: $tempFullName)
                            .padding()
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Information text
                    Text("This is how your name will appear throughout the app.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            if isValidName(tempFullName) {
                                viewModel.updateFullName(to: tempFullName)
                                showingFullNamePopup = false
                            } else {
                                showingInvalidNameAlert = true
                            }
                        }) {
                            Text("Update Name")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(12)
                        }
                        
                        Button("Cancel") {
                            showingFullNamePopup = false
                        }
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .alert("Invalid Email", isPresented: $showingInvalidEmailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid email address.")
        }
        .alert("Invalid Name", isPresented: $showingInvalidNameAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid name (at least 2 characters).")
        }
        .alert("Password Mismatch", isPresented: $showingPasswordMismatchAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The passwords do not match.")
        }
        .alert("Delete User Data", isPresented: $showingDeleteDataAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteUserData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Permanently delete your account? This action cannot be undone.")
        }
    }
    
    // Email validation
    func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    // Name validation
    func isValidName(_ name: String) -> Bool {
        // Basic validation to ensure name isn't empty and has minimum length
        return name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    // Check if all password requirements are met
    func passwordRequirementsMet() -> Bool {
        return passwordRequirements.allSatisfy { $0.1(newPassword) }
    }
    
    // Function to mask email for security
    func maskEmail(_ email: String) -> String {
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return email }
        
        let username = components[0]
        let domain = components[1]
        
        if username.count <= 3 {
            return username + "@" + domain
        } else {
            let visibleChars = min(3, username.count)
            let prefix = String(username.prefix(visibleChars))
            return prefix + String(repeating: "•", count: username.count - visibleChars) + "@" + domain
        }
    }
    
    // New function to check and enable biometric authentication
    private func checkAndEnableBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        // Check if the device can use Face ID
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            viewModel.isBioAuth = true
            viewModel.biometricEnabled = true
            
            let reason = "Confirm your identity to enable Face ID login"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Face ID authentication successful - enabling Face ID login")
                    } else {
                        print("❌ Face ID authentication failed:", error?.localizedDescription ?? "Unknown error")
                        self.viewModel.biometricEnabled = false
                        self.viewModel.isBioAuth = false
                    }
                }
            }
        } else {
            print("⚠️ Face ID not available:", error?.localizedDescription ?? "Unknown error")
            viewModel.biometricEnabled = false
        }
    }
}

struct VerifyEmailButton: View {
    @EnvironmentObject private var vm: AppViewModel
    let accentColor: Color

    var body: some View {
        let verified = vm.emailVerified       // 1️⃣ pull into a local

        Button {
            Task { try? await vm.sendVerificationEmail() }
        } label: {
            label(forVerified: verified)
        }
        .disabled(verified)
        .buttonStyle(PressableStyle())
    }

    @ViewBuilder
    private func label(forVerified verified: Bool) -> some View {
        HStack {
            Image(systemName: verified ? "checkmark.seal.fill"
                                        : "envelope.badge.fill")
                .foregroundColor(accentColor)
            Text(verified ? "Verified" : "Verify Email")
                .foregroundColor(.white)
            Spacer()
            Image(systemName: verified ? "checkmark"
                                       : "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray
            .opacity(verified ? 0.1 : 0.2))   // 2️⃣ still a ternary, but short
        .cornerRadius(12)
        .opacity(verified ? 0.5 : 1)
    }
}

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.94
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}


struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppViewModel())
            .preferredColorScheme(.dark)
    }
}
