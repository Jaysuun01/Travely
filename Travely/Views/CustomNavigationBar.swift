import SwiftUI

struct CustomNavigationBar: View {
    @Binding var selectedTab: Int
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.bottom)
            
            // Tab buttons
            HStack {
                Spacer()
                Button(action: { selectedTab = 0 }) {
                    VStack(spacing: 14) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(selectedTab == 0 ? accentColor : .gray)
                }
                
                Spacer()
                Button(action: { selectedTab = 1 }) {
                    VStack(spacing: 14) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(selectedTab == 1 ? accentColor : .gray)
                }
                
                Spacer()
                Button(action: { selectedTab = 2 }) {
                    VStack(spacing: 14) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(selectedTab == 2 ? accentColor : .gray)
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .frame(height: 49)
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
        CustomNavigationBar(selectedTab: .constant(0))
    }
}
