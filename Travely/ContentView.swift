//
//  ContentView.swift
//  Travely
//
//  Created by Ather Ahmed on 2/26/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
