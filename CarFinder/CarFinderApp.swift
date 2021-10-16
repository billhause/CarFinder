//
//  CarFinderApp.swift
//  CarFinder
//
//  Created by William Hause on 10/16/21.
//

import SwiftUI

@main
struct CarFinderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
