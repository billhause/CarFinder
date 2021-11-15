//
//  AppInfoEntity.swift
//  CarFinder
//
//  Created by William Hause on 11/12/21.
//

import Foundation
import CoreData

extension AppInfoEntity {
    
    static let REVIEW_THRESHOLD = 10 // Number of app activations needed to trigger a review request
    
    // Get ONE and ONLY AppInfoEntity or create it if it doesn't exist yet
    public static func getAppInfoEntity() -> AppInfoEntity {
        // see https://www.youtube.com/watch?v=yOhyOpXvaec at 39:30
        
        let viewContext = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<AppInfoEntity>(entityName: "AppInfoEntity")
        
        // SortDescriptor and Predicate not needed since I'm retriveing the one and only record and not filtering the results
        //request.predicate = NSPredicate(format: "score > %@ AND score <%@", NSNumber(value: 3), NSNumber(value: 100))
        //let sortDesc = NSSortDescriptor(key: "score", ascending: true)
        //request.sortDescriptors = [sortDesc] // array of sort descriptors to use
        
        // Get array of results
        let results = try? viewContext.fetch(request) // should never fail
        
        // If we found one return it, otherwise create one and return it
        if let theAppInfoEntity = results!.first {
            // Found one so return it
            return theAppInfoEntity
        } else {
            // No AppInfoEntity was found so create one, save it and return it
            let theAppInfoEntity = AppInfoEntity(context: viewContext)
            theAppInfoEntity.updateUsageCount(theCount: 0) // Must be the first run so set to 0
            return theAppInfoEntity
        }
    }
    
    // Update the AppInfo usageCount and save it
    public func updateUsageCount(theCount: Int32) {
        usageCount = theCount
        saveAppInfoEntity()
    }
    
    // Increment Usage Count
    public func incrementUsageCount() {
        usageCount += 1
//        print("Count: \(usageCount) - AppInfoEntity.incrementUsageCount()")
        saveAppInfoEntity()
    }
    
    private func saveAppInfoEntity() {
        let viewContext = PersistenceController.shared.container.viewContext
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("wdh Error while saving AppInfoEntity in saveAppInfoEntity() \(nsError.userInfo)")
        }
    }
    
}
