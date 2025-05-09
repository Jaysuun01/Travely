import SwiftUI

struct CustomNavigationBar: View {
    @Binding var selectedTab: Int
    private let accentColor = Color(red: 0.97, green: 0.44, blue: 0.11)
    
    var body: some View {
        VStack(spacing: 2) {
            // Top border
            Rectangle()
                .fill(accentColor)
                .frame(height: 1)
            
            // Tab buttons
            HStack {
                Spacer()
                Button(action: { selectedTab = 0 }) {
                    VStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(selectedTab == 0 ? accentColor : .gray)
                }
                
                Spacer()
                Button(action: { selectedTab = 1 }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(selectedTab == 1 ? accentColor : .gray)
                }
                
                Spacer()
                Button(action: { selectedTab = 2 }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(selectedTab == 2 ? accentColor : .gray)
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.bottom, 0)
            .background(Color.black)
        }
        .background(Color.black)
        .frame(height: 15)
    }
}

#Preview {
    NavigationStack {
        CustomNavigationBar(selectedTab: .constant(0))
    }
}
