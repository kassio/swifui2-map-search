//
//  mapsearchApp.swift
//  mapsearch
//
//  Created by Kassio Borges on 23/01/2021.
//

import SwiftUI

@main
struct mapsearchApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
