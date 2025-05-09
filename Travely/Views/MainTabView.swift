import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                AddTripView(selectedTab: $selectedTab)
                    .tag(1)
                
                ProfileView()
                    .tag(2)
            }
            
            VStack {
                Spacer()
                CustomNavigationBar(selectedTab: $selectedTab)
                    .background(Color.black)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppViewModel())

}
