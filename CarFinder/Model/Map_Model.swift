//
//  Map_Model.swift
//  CarFinder
//
//  Created by William Hause on 10/17/21.
//

import Foundation
import CoreLocation

// MARK: Model
struct Map_Model {
    var orientMapFlag = false  // This flag signals the map to orient it'self maybe it should be in the ViewModel instead
    var isHybrid = false       // Track if the hybrid map or the standard map is displayed
    var updateParkingSpotFlag = false // Set to true if the parking spot should be updated
    var currentHeading = 0.0
    var keepMapCentered = true // Will set to false if the user starts manipulating the map manually
        
//    var currentLocation = CLLocationCoordinate2D(latitude: CLLocationDegrees(40.0), longitude: CLLocationDegrees(-105.0))
    // The parking location is stored in CoreData ParkingSpotEntity
}
