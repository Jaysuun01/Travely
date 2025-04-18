//
//  ContentView.swift
//  Travely
//
//  Created by Ather Ahmed on 2/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(.dark)
            } else {
                LoginView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

#Preview {
    ContentView()
}
