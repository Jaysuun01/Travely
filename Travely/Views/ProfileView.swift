import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
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
                
                // Username if available
                if let userName = viewModel.userName {
                    Text(userName)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
                
                Spacer()
                
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
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
}
