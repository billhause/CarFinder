//
//  Map_ViewModel.swift
//  CarFinder
//
//  Created by William Hause on 10/16/21.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class Map_ViewModel: NSObject, ObservableObject, CLLocationManagerDelegate  {
    // This class
    //   1 - provides data to the view in a way the view can easily consume it
    //   2 - provides 'Intent' functions for the view to change the data
    
    @Published private var theMapModel: Map_Model = Map_Model()
    private var mLocationManager: CLLocationManager?
    
    // Mark: Flag Variables
    var isHybrid: Bool {
        get {
            print("Map_ViewModel.isHybrid GET Called")
            return theMapModel.isHybrid
        }
        set(newValue) {
            print("Map_ViewModel.isHybrid set(\(newValue))")
            theMapModel.isHybrid = newValue
        }
    }
    
    // MARK: Init Functions
    override init() {
        print("Map_ViewModel init() called")

        // Initialize the LocationManager - https://stackoverflow.com/questions/60356182/how-to-invoke-a-method-in-a-view-in-swiftui
        mLocationManager = CLLocationManager()
        super.init() // Call the NSObject init - Must be after member vars are initialized and before 'self' is referenced
        
        mLocationManager?.requestWhenInUseAuthorization()
//        mLocationManager?.requestAlwaysAuthorization() // Request permission even when the app is not in use
        mLocationManager?.delegate = self
        
        // Save battery by not enabling the UpdateLocation and UpdateHeading??? Not sure
//        mLocationManager?.startUpdatingLocation() // Will call the delegate's didUpdateLocations function when locaiton changes
//        mLocationManager?.startUpdatingHeading() // Will call the delegates didUpdateHeading function when heading changes
        
        // Apps that want to receive location updates when suspended must include the UIBackgroundModes key (with the location value) in their app’s Info.plist
        //mLocationManager?.allowsBackgroundLocationUpdates = true //must include the UIBackgroundModes key in the Info.plist
        
    }
    
    // MARK: CLLocationManagerDelegate Functions

    // REQUIRED - Tells the delegate that new location data is available.
    func locationManager(_ locationManager: CLLocationManager, didUpdateLocations: [CLLocation]) {
        print("Called: locationManager(_ locationManager CLLocationManager, didUpdateLocations: [CLLocation])")
    }

//    // Heading - Tells the delegate that the location manager received updated heading information.
//    // Note: Must have previously called mLocationManager?.startUpdatingHeading() for this to be called
//    func locationManager(_ locationManager: CLLocationManager, didUpdateHeading: CLHeading) {}
//
//    // Tells the delegate when the app creates the location manager and when the authorization status changes.
//    func locationManagerDidChangeAuthorization(_ locationManager: CLLocationManager) {}
//
//    // Tells the delegate that the location manager was unable to retrieve a location value.
//    func locationManager(_ locationManager: CLLocationManager, didFailWithError: Error) {}
//
//    // Tells the delegate that updates will no longer be deferred.
//    func locationManager(_ locationManager: CLLocationManager, didFinishDeferredUpdatesWithError: Error?) {}
//
//    // Tells the delegate that location updates were paused.
//    func locationManagerDidPauseLocationUpdates(_ locationManager: CLLocationManager) {}
//
//    // Tells the delegate that the delivery of location updates has resumed.
//    func locationManagerDidResumeLocationUpdates(_ locationManager: CLLocationManager) {}
//
//
//    // Asks the delegate whether the heading calibration alert should be displayed.
//    //func locationManagerShouldDisplayHeadingCalibration(_ locationManager: CLLocationManager) -> Bool {}
//
//    NOTE: There are OTHER CALLBACKs not listed above
    
    
    
    // MARK: Intent Functions
    func updateParkingSpot() {
        // TODO: Update the ParkingSpotEntity to have the current lat/lon
        
    }
    
    
    // MARK: Getters
    
    func getRegionToShow() -> MKCoordinateRegion {
        // TODO: Return a bounding box centered on the current location and containing the ParkingSpot
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.95, longitude: -104.96),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        return region
    }

    
    func getParkingSpot() -> MKPlacemark {
        // TODO: Make this return the current ParkingSpot lat/lon
        // Grandma's House 40.02639828963394, -105.27067477468266
//        return MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40.02639828963394, longitude: -105.27067477468266))
        
        // Apple Headquarters - latitude: 37.33182, longitude: -122.03118
        return MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.33182, longitude: -122.03118))
        
    }
        
    // Flag to signal to the map that the user wants the map re-centered and oriented in his direction
    var orientMapFlag: Bool {
        get {
            return theMapModel.orientMapFlag
        }
        set(orientFlag) {
            theMapModel.orientMapFlag = orientFlag
        }
    }
    
}

