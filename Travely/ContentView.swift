//
//  ContentView.swift
//  Travely
//
//  Created by Ather Ahmed on 2/26/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showOfflineAlert = false
    @State private var wasConnected = true

    var body: some View {
        VStack(spacing: 0) {
            NetworkStatusView()
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .animation(.easeInOut, value: viewModel.isConnected)
        .onChange(of: viewModel.isConnected) { isConnected in
            if !isConnected && wasConnected {
                showOfflineAlert = true
            }
            wasConnected = isConnected
        }
        .alert("No Internet Connection", isPresented: $showOfflineAlert) {
            Button("Close", role: .cancel) {
                showOfflineAlert = false
            }
            Button("Settings") {
                showOfflineAlert = false
                // Open Wi-Fi settings
                if let url = URL(string: "App-Prefs:root=WIFI"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("You are currently offline. Your data may not be up to date.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
