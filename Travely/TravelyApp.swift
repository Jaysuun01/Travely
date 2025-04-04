//
//  TravelyApp.swift
//  Travely
//
//  Created by Ather Ahmed on 3/26/25.
//

import SwiftUI

@main
struct TravelyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
