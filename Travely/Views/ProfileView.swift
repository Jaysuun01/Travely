import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var faceIDEnabled = false
    @State private var newEmail = ""
    @State private var showingPasswordChange = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingDeleteAccountAlert = false // Added state for the alert
    @State private var showingDeleteDataAlert = false // Added state for the alert

    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    // Background color
                    Color.black.edgesIgnoringSafeArea(.all)

                    VStack {
                        Spacer()

                        // Profile icon
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(accentColor)
                            .padding(.top, 20)

                        // Username if available
                        if let userName = viewModel.userName {
                            Text(userName)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }

                        // Face ID
                        Toggle("Enable Face ID", isOn: $faceIDEnabled)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .toggleStyle(SwitchToggleStyle(tint: accentColor))

                        // Change Email Section
                        VStack(alignment: .leading) {
                            Text("Change Email")
                                .foregroundColor(.white)
                            TextField("New Email", text: $newEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            Button("Confirm Email Change") {
                                viewModel.changeEmail(to: newEmail)
                            }
                            .buttonStyle(PrimaryButtonStyle(color: accentColor))
                        }.padding()

                        // Change Password
                        Button("Change Password") {
                            showingPasswordChange = true // Show the pop-up
                        }
                        .buttonStyle(PrimaryButtonStyle(color: accentColor))
                        .padding(.bottom)

                        // Delete Data
                        Button("Delete My Data") {
                            showingDeleteDataAlert = true // Show delete data alert
                        }
                        .buttonStyle(DestructiveButtonStyle())
                        .alert(isPresented: $showingDeleteDataAlert) {
                            Alert(
                                title: Text("Delete My Data"),
                                message: Text("Are you sure you want to delete all your data? This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete")) {
                                    viewModel.deleteUserData()
                                },
                                secondaryButton: .cancel()
                            )
                        }

                        // Delete Account
                        Button("Delete Account") {
                            showingDeleteAccountAlert = true // Show the alert
                        }
                        .buttonStyle(DestructiveButtonStyle())
                        .alert(isPresented: $showingDeleteAccountAlert) {
                            Alert(
                                title: Text("Delete Account"),
                                message: Text("Are you sure you want to permanently delete your account? This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete")) {
                                    viewModel.deleteAccount()
                                },
                                secondaryButton: .cancel()
                            )
                        }

                        // Logout button
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
                    // The pop-up
                    VStack(spacing: 20) {
                        Text("Change Password")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.top)

                        SecureField("New Password", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white) // text is visible on background
                            .padding(.horizontal)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white) // text is visible on background
                            .padding(.horizontal)

                        Button("Confirm Password Change") {
                            viewModel.changePassword(new: newPassword, confirm: confirmPassword)
                            showingPasswordChange = false // Close the pop-up - completed changePassword
                        }
                        .buttonStyle(PrimaryButtonStyle(color: accentColor))
                        .padding(.bottom)

                        Button("Cancel") {
                            showingPasswordChange = false // Cancel changePassword
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.bottom)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.2)) // Background for the pop-up changePassword
                    .cornerRadius(15)
                }
            }
        }
    }
}