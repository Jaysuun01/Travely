import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import LocalAuthentication
import FirebaseCore

struct LoginView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var biometricsAvailable = false
    @State private var biometricTriggered = false

    var body: some View {
        ZStack {
            Image("loginBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 54/255, green: 54/255, blue: 54/255), location: 0.0),
                            .init(color: .clear, location: 0.5)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .edgesIgnoringSafeArea(.all)

            VStack {
                if !viewModel.isAuthenticated {
                    Text("Travely")
                        .font(.custom("Inter-Regular", size: 64))
                        .fontWeight(.black)
                        .foregroundColor(Color(red: 244/255, green: 144/255, blue: 82/255))
                        .padding(.top, -200)

                    if biometricsAvailable {
                        Button(action: {
                            if viewModel.biometricEnabled {
                                // Disable Face ID
                                viewModel.biometricEnabled = false
                                viewModel.isBioAuth = false
                                print("✅ Face ID disabled")
                            } else {
                                // Just enable Face ID for next sign-in
                                viewModel.biometricEnabled = true
                                print("✅ Face ID enabled for next sign-in")
                            }
                        }) {
                            HStack {
                                Image(systemName: "faceid")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 20)
                                    .padding(.trailing, 1)
                                Text("Require Face ID to Enter")
                                Toggle(isOn: $viewModel.biometricEnabled) {}
                                    .toggleStyle(CheckboxToggleStyle())
                                    .disabled(true)
                                    .padding()
                            }
                            
                            .font(.custom("Inter-Regular", size: 17))
                            .frame(maxWidth: 224)
                            .background(.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    /*
                    Toggle(isOn: $viewModel.biometricEnabled) {
                        Text("Always use FaceID to Sign in")
                            .font(.custom("Inter-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
                        .toggleStyle(CheckboxToggleStyle())
                        .disabled(true)
                        .padding()
                     */
                    GoogleSignInButton(action: handleGoogleSignIn)
                        .buttonStyle(.borderedProminent)
                        .frame(width: 200, height: 50)
                        .padding()
                }
            }
            .onAppear {
                
                checkBiometricAvailability()

                // Only check biometric availability
                checkBiometricAvailability()
            }

        }
    }

    private func authenticateBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to sign in securely."
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Biometric auth success")
                        // Don't set biometricEnabled here, it's a user preference
                        self.viewModel.isBioAuth = true
                    } else {
                        print("❌ Biometric auth failed:", error?.localizedDescription ?? "Unknown error")
                        // On failure, reset the state
                        self.viewModel.isBioAuth = false
                    }
                }
            }
        } else {
            print("❌ Biometrics not available:", error?.localizedDescription ?? "Unknown error")
            viewModel.biometricEnabled = false
            viewModel.isBioAuth = false
        }
    }

    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsAvailable = true
        } else {
            biometricsAvailable = false
            print("Biometric auth not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    private func handleGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ No clientID in Firebase options")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presenter = UIApplication.topViewController else {
            print("❌ No presenter found")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
            if let error {
                print("❌ Google sign‑in failed:", error.localizedDescription)
                return
            }

            guard
                let user = result?.user,
                let idTok = user.idToken?.tokenString
            else {
                print("❌ Missing user or idToken")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idTok,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { [self] authResult, error in
                if let error {
                    print("❌ Firebase sign‑in failed:", error.localizedDescription)
                    return
                }
                print("✅ Firebase sign‑in OK for", authResult?.user.uid ?? "")
                viewModel.signIn(with: authResult?.user.displayName)
                
                // Don't prompt for Face ID here - RootView will handle it
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.gray)
                .onTapGesture {
                    withAnimation {
                        configuration.isOn.toggle()
                    }
                }

            configuration.label
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppViewModel())
}
