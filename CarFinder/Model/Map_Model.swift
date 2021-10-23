//
//  Map_Model.swift
//  CarFinder
//
//  Created by William Hause on 10/17/21.
//

import Foundation

// MARK: Model
struct Map_Model {
    var orientMapFlag = false  // This flag signals the map to orient it'self maybe it should be in the ViewModel instead
    var isHybrid = false       // Track if the hybrid map or the standard map is displayed
    // The parking location is stored in CoreData ParkingSpotEntity
}