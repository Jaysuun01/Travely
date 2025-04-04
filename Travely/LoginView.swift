//
//  LoginView.swift
//  Travely
//
//  Created by Ather Ahmed on 2/23/25.
//

import SwiftUI
import AuthenticationServices
import LocalAuthentication

struct LoginView: View {
    @State private var isAuthenticated = false
    @State private var userName: String?
    @State private var biometricAlways = false
    
    var body: some View {
        ZStack{
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 54/255, green: 54/255, blue: 54/255),
                    Color(red: 81/255, green: 81/255, blue: 81/255)
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .edgesIgnoringSafeArea(.all)
            VStack {
                if isAuthenticated {
                    Text("Welcome, \(userName ?? "User")!")
                        .font(.largeTitle)
                        .padding()
                } else {
                    Image("appLogo")
                        .resizable()  // Makes the image resizable
                        .scaledToFit()  // Maintains aspect ratio
                        .cornerRadius(10)
                        .frame(width: 175, height: 200)  // Set image size
                        .padding(.top, -100)
                    // Sign In with Apple Button
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: handleAuthorization)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .frame(maxWidth: 200)
                    .padding(.top, 100)
                    
                    // Button for Face ID / Touch ID login
                    Button(action: {authenticateBiometrics()}) {
                        HStack {
                            Image(systemName: "faceid")
                            .resizable()  // Makes the image resizable
                            .scaledToFit()  // Maintains aspect ratio
                            .cornerRadius(10)
                            .frame(width: 25, height: 20)
                            .padding(.trailing, 1)
                            Text("Sign in with Face ID")
                        }
                    }
                    .font(.system(size: 17, weight: .bold))
                    .padding()
                    .frame(maxWidth: 224)
                    .background(.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Toggle(isOn: $biometricAlways) {
                        Text("Always use FaceID to Sign in")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding()
                }
            }
            .onAppear {
                checkBiometricAvailability()
            }
        }
    }
    
    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                self.userName = appleIDCredential.fullName?.givenName
                self.isAuthenticated = true
            }
        case .failure(let error):
            print("Authorization failed: \(error.localizedDescription)")
        }
    }
    
    private func authenticateBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in with Face ID or Touch ID") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                        self.userName = "Biometric User"
                    } else {
                        print("Biometric authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Biometric authentication is not available.")
        }
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometric authentication is available
        } else {
            print("Biometric authentication is not available.")
        }
    }
    
    struct CheckboxToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {

                RoundedRectangle(cornerRadius: 5.0)
                    .stroke(lineWidth: 2)
                    .frame(width: 25, height: 25)
                    .cornerRadius(5.0)
                    .overlay {
                        Image(systemName: configuration.isOn ? "checkmark" : "")
                    }
                    .onTapGesture {
                        withAnimation(.spring()) {
                            configuration.isOn.toggle()
                        }
                    }

                configuration.label

            }
        }
    }
}

#Preview {
    LoginView()
}
