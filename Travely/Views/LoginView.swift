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
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var errorMessage: String?
    @State private var keyboardShown = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("loginBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .ignoresSafeArea(.keyboard)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black, location: 0.0),
                                .init(color: .black, location: 0.80),
                                .init(color: .clear, location: 1.0)
                                
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            
                VStack {
                    if !viewModel.isAuthenticated {
                        Text("Travely")
                            .font(.custom("Inter-Regular", size: 64))
                            .fontWeight(.black)
                            .foregroundColor(Color(red: 244/255, green: 144/255, blue: 82/255))
                            .padding(.top, -50)

                        // Email & Password Sign-in
                        VStack(spacing: 24) {
                            InputView(text: $email,
                                      title: "Email Address",
                                      placeholder: "example@gmail.com")
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)

                            InputView(text: $password,
                                      title: "Password",
                                      placeholder: "Enter your password",
                                      isSecureField: true)
                        }
                        .frame(width: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .padding()
                        
                        if biometricsAvailable {
                            Toggle(isOn: $viewModel.biometricEnabled) {
                                HStack {
                                    Image(systemName: "faceid")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 20)
                                        .padding(.trailing, 1)
                                    Text("Require Face ID to Enter")
                                }
                                .font(.custom("Inter-Regular", size: 17))
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            .frame(width: UIScreen.main.bounds.width - 32)
                            .frame(height: 32)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        // Sign In button
                        Button {
                            handleEmailSignIn()
                        } label: {
                            HStack {
                                Text("SIGN IN")
                                    .font(.custom("Inter-Regular", size: 20))
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                        }
                        .background(Color(red: 244/255, green: 144/255, blue: 82/255))
                        .cornerRadius(10)
                        .padding(.top, 24)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.horizontal)
                        }

                        GoogleSignInButton(action: handleGoogleSignIn)
                            .buttonStyle(.borderedProminent)
                            .frame(width: 200, height: 50)
                            .padding()

                        // Sign Up Navigation
                        NavigationLink(destination: SignUpView().environmentObject(viewModel)) {
                            HStack(spacing: 3) {
                                Text("Don't have an account?")
                                Text("Sign Up")
                                    .fontWeight(.bold)
                            }
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color(red: 244/255, green: 144/255, blue: 82/255))
                        }
                    }
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onAppear {
                    checkBiometricAvailability()
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(viewModel)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func handleEmailSignIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                    print("❌ Email sign-in failed:", error.localizedDescription)
                } else {
                    print("✅ Signed in with email:", authResult?.user.uid ?? "")
                    viewModel.signIn(with: authResult?.user.displayName)
                }
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
                        self.viewModel.isBioAuth = true
                    } else {
                        print("❌ Biometric auth failed:", error?.localizedDescription ?? "Unknown error")
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

        biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if !biometricsAvailable {
            print("❌ Biometric auth not available:", error?.localizedDescription ?? "Unknown error")
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
            if let error = error {
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

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("❌ Firebase sign‑in failed:", error.localizedDescription)
                    return
                }
                print("✅ Firebase sign‑in OK for", authResult?.user.uid ?? "")
                viewModel.signIn(with: authResult?.user.displayName)
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(.gray)

            configuration.label               // “Require Face ID …”
        }
        .contentShape(Rectangle())             // ⇠ expands the tap area
        .onTapGesture {
            withAnimation { configuration.isOn.toggle() }
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppViewModel())
    }
}
