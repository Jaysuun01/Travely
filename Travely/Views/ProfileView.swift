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
    
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(accentColor)
                            .padding(.top, 20)
                        
                        if let userName = viewModel.userName {
                            Text(userName)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                        
                        Toggle("Enable Face ID", isOn: $faceIDEnabled)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .toggleStyle(SwitchToggleStyle(tint: accentColor))
                        
                        VStack(alignment: .leading) {
                            HStack(spacing: 10) {
                                Button("Change Email") {
                                    showingEmailPopup = true
                                }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(PrimaryButtonStyle(color: accentColor))
                                
                                Button("Change Password") {
                                    showingPasswordChange = true
                                }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(PrimaryButtonStyle(color: accentColor))
                            }
                            .padding(.top, 8)
                            
                            Button("Delete User Data") {
                                showingDeleteDataAlert = true
                            }
                            .buttonStyle(DestructiveButtonStyle())
                            .alert("Delete All Data", isPresented: $showingDeleteDataAlert) {
                                Button("Delete", role: .destructive) {
                                    viewModel.deleteUserData()
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("This action cannot be undone.")
                            }
                            
                            Button("Delete Account") {
                                showingDeleteAccountAlert = true
                            }
                            .buttonStyle(DestructiveButtonStyle())
                            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                                Button("Delete", role: .destructive) {
                                    viewModel.deleteAccount()
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("Permanently delete your account? This action cannot be undone.")
                            }
                            
                            Button(action: {
                                viewModel.signOut()
                            }) {
                                Text("Log Out")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(accentColor)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 50)
                            .padding(.bottom, 100)
                        }
                    }
                    .navigationBarBackButtonHidden(true)
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
                }
            }
        }
    }
    
    // Email validation
    func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    struct ProfileView_Previews: PreviewProvider {
        static var previews: some View {
            ProfileView()
                .environmentObject(AppViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
