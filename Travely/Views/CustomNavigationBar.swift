import SwiftUI

struct CustomNavigationBar: View {
    @Binding var selectedTab: Int
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(
                    imageName: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0,
                    accentColor: accentColor
                ) {
                    selectedTab = 0
                }
                .frame(maxWidth: .infinity)
                TabButton(
                    imageName: "plus.circle.fill",
                    title: "Add",
                    isSelected: selectedTab == 1,
                    accentColor: accentColor
                ) {
                    selectedTab = 1
                }
                .frame(maxWidth: .infinity)
                TabButton(
                    imageName: "bell.fill",
                    title: "Notifications",
                    isSelected: selectedTab == 2,
                    accentColor: accentColor
                ) {
                    selectedTab = 2
                }
                .frame(maxWidth: .infinity)
                TabButton(
                    imageName: "person.fill",
                    title: "Profile",
                    isSelected: selectedTab == 3,
                    accentColor: accentColor
                ) {
                    selectedTab = 3
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 8)
            .padding(.bottom, 1)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct TabButton: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: imageName)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? accentColor : .gray)
        }
    }
}

#Preview {
    NavigationStack {
        CustomNavigationBar(selectedTab: .constant(0))
    }
}
