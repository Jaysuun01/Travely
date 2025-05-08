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

        var body: some View {
            VStack {
                Text("Travely")
                    .font(.custom("Inter-Regular", size: 64))
                    .fontWeight(.black)
                    .foregroundColor(Color(red: 244/255, green: 144/255, blue: 82/255))
                    .padding(.top, -100)

                Text("Sign Up Your Account")
                    .font(.title)
                    .bold()

                VStack(spacing: 24) {
                    InputView(text: $email,
                              title: "Email Address",
                              placeholder: "name@example.com")
                        .autocapitalization(.none)

                    InputView(text: $fullName,
                              title: "Full Name",
                              placeholder: "Enter your name")

                    InputView(text: $password,
                              title: "Password",
                              placeholder: "Enter your password",
                              isSecureField: true)

                    InputView(text: $confirmPassword,
                              title: "Confirm Password",
                              placeholder: "Re-enter your password",
                              isSecureField: true)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign Up button
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
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                }
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.top, 24)

                Button("Cancel") {
                    dismiss()
                }
                .padding(.top, 5)
            }
            .padding()
        }

        private func handleSignUp() {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    print("✅ Signed Up Account: ", authResult?.user.uid ?? "")
                    viewModel.signIn(with: fullName)
                    dismiss()
                }
            }
        }
    }
