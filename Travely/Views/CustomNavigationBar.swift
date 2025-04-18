import SwiftUI

struct CustomNavigationBar: View {
    @State private var selectedTab = 0
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        HStack {
            Spacer()
            NavigationLink(destination: HomeView()) {
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20))
                    Text("Home")
                        .font(.system(size: 10))
                }
                .foregroundColor(selectedTab == 0 ? accentColor : .gray)
            }
            .simultaneousGesture(TapGesture().onEnded { selectedTab = 0 })
            
            Spacer()
            NavigationLink(destination: Text("Add Trip")) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add")
                        .font(.system(size: 10))
                }
                .foregroundColor(selectedTab == 1 ? accentColor : .gray)
            }
            .simultaneousGesture(TapGesture().onEnded { selectedTab = 1 })
            
            Spacer()
            NavigationLink(destination: ProfileView()) {
                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                    Text("Profile")
                        .font(.system(size: 10))
                }
                .foregroundColor(selectedTab == 2 ? accentColor : .gray)
            }
            .simultaneousGesture(TapGesture().onEnded { selectedTab = 2 })
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
        .overlay(
            Rectangle()
                .fill(accentColor)
                .frame(height: 1),
            alignment: .top
        )
    }
}

#Preview {
    NavigationStack {
        CustomNavigationBar()
    }
}