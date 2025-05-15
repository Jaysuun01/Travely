import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    
    @AppStorage("faceIDEnabled") private var faceIDEnabled = false
    
    @State private var newEmail = ""
    @State private var tempEmail = ""
    @State private var showingPasswordChange = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteDataAlert = false
    @State private var showingInvalidEmailAlert = false
    @State private var showingPasswordMismatchAlert = false
    @State private var showingEmailPopup = false
    @State private var showingEditSheet = false
    
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Profile Section
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Image
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(accentColor)
                                .padding(.top, 20)
                            
                            // Username
                            if let userName = viewModel.userName {
                                Text(userName)
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            // Face ID Toggle
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Security")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                Toggle("Enable Face ID", isOn: $faceIDEnabled)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .toggleStyle(SwitchToggleStyle(tint: accentColor))
                            }
                            .frame(maxWidth: .infinity)
                            
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // Bottom Button Section
                    VStack(spacing: 16) {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Log Out Button
                        Button(action: {
                            viewModel.signOut()
                        }) {
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .background(Color.black)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                List {
                    Section(header: Text("Account Settings")) {
                        Button("Change Email") {
                            showingEditSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                tempEmail = ""
                                showingEmailPopup = true
                            }
                        }
                        
                        Button("Change Password") {
                            showingEditSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                newPassword = ""
                                confirmPassword = ""
                                showingPasswordChange = true
                            }
                        }
                    }
                    
                    Section(header: Text("Danger Zone")) {
                        Button("Delete User Data") {
                            showingEditSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showingDeleteDataAlert = true
                            }
                        }
                        .foregroundColor(.red)
                        
                        Button("Delete Account") {
                            showingEditSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showingDeleteAccountAlert = true
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Edit Profile")
                .navigationBarItems(trailing: Button("Done") {
                    showingEditSheet = false
                })
            }
        }
        .sheet(isPresented: $showingPasswordChange) {
            VStack(spacing: 20) {
                Text("Change Password")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top)
                
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityIdentifier("newPasswordField")
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityIdentifier("confirmPasswordField")
                
                Button("Confirm Password Change") {
                    if newPassword == confirmPassword {
                        viewModel.changePassword(new: newPassword, confirm: confirmPassword)
                        showingPasswordChange = false
                    } else {
                        showingPasswordMismatchAlert = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: accentColor))
                .padding(.bottom)
                
                Button("Cancel") {
                    showingPasswordChange = false
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.bottom)
            }
            .padding()
            .background(Color.black)
            .cornerRadius(15)
        }
        .sheet(isPresented: $showingEmailPopup) {
            VStack(spacing: 20) {
                Text("Enter New Email")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)

                TextField("New Email", text: $tempEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding(.horizontal)

                HStack(spacing: 10) {
                    Button("Confirm") {
                        if isValidEmail(tempEmail) {
                            viewModel.changeEmail(to: tempEmail)
                            newEmail = tempEmail
                            showingEmailPopup = false
                        } else {
                            showingInvalidEmailAlert = true
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: accentColor))

                    Button("Cancel") {
                        tempEmail = ""
                        showingEmailPopup = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding()
            .background(Color.black)
            .cornerRadius(15)
        }
        .alert("Invalid Email", isPresented: $showingInvalidEmailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid email address.")
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
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppViewModel())
            .preferredColorScheme(.dark)
    }
}
