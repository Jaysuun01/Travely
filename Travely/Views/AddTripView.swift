import SwiftUI

struct AddTripView: View {
    @State private var destination = ""
    @State private var date = Date()
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AddTripView()
}
