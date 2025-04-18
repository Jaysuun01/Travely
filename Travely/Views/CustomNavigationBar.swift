import SwiftUI

struct CustomNavigationBar: View {
    @State private var selectedTab = 0
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        HStack {
            Spacer()
            Spacer()
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20))
                    Text("Home")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(selectedTab == 0 ? accentColor : .gray)
            
            Spacer()
            Spacer()
            Spacer()
            
            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(selectedTab == 1 ? accentColor : .gray)
            
            Spacer()
            Spacer()
            Spacer()
            
            Button(action: { selectedTab = 2 }) {
                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                    Text("Profile")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(selectedTab == 2 ? accentColor : .gray)
            
            Spacer()
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.bottom, 8) // Additional padding for bottom safe area
        .background(Color.black)
    }
}
