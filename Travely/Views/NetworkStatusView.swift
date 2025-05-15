import SwiftUI

struct NetworkStatusView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showReconnectedMessage = false
    @State private var previousConnectionState = true

    var body: some View {
        Group {
            if !viewModel.isConnected {
                banner(text: "No Internet Connection", systemImage: "wifi.slash", color: .red)
            } else if showReconnectedMessage {
                banner(text: "Connected", systemImage: "wifi", color: .green)
            }
        }
        .animation(.easeInOut, value: viewModel.isConnected)
        .animation(.easeInOut, value: showReconnectedMessage)
        .onReceive(viewModel.$isConnected) { isConnected in
            if isConnected && !previousConnectionState {
                showReconnectedMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showReconnectedMessage = false
                    }
                }
            }
            previousConnectionState = isConnected
        }
    }

    private func banner(text: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.white)
            Text(text)
                .font(.subheadline).bold()
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.95))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    VStack {
        NetworkStatusView()
            .environmentObject(AppViewModel())
        Spacer()
    }
} 