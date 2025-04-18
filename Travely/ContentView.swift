//
//  ContentView.swift
//  Travely
//
//  Created by Ather Ahmed on 2/26/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        MainTabView()
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
