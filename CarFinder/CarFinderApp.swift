//
//  CarFinderApp.swift
//  CarFinder
//
//  Created by William Hause on 10/16/21.
//
//  Localization Internationalization
//    - I followed the video here to localize this app: https://www.youtube.com/watch?v=oXa4en79CHg
//    - Chinese is the number one language to localize your iOS app into, followed by Japanese, Korean, German, French, Spanish, Italian and Malay
//
// DIRECTIONS: How to create an app preview with iMovie
//    https://developer.apple.com/support/imovie/
//
// Icon Builder Website:
//  https://appicon.co
//
// Screen Shots
//   - 4 shots using iPhone "8 Plus" simulator
//   - 4 shots using iPhone "11 Pro Max" simulator
//


import SwiftUI

@main
struct CarFinderApp: App {
    let persistenceController = PersistenceController.shared

    init() { // Added by Bill to put any start up code 
        AppInfoEntity.getAppInfoEntity().incrementUsageCount() // Count usage to know when to display the request for a review
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(theMap_ViewModel: Map_ViewModel())
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
