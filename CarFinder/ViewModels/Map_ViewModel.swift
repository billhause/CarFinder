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
    var isHybrid: Bool { // Expose this so the View can modify it indirectily through the ViewModel
        get {
            return theMapModel.isHybrid
        }
        set(newValue) {
            theMapModel.isHybrid = newValue
        }
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

    func orientMap() {
        orientMapFlag = true //  Trigger map update
    }
    
    // Return a rect that has the current location as the center and the parking spot at the edge
//wdhx    func getBoundingRect() -> MKMapRect {
//        mLocationManager.get last known location
//    }
    
    // Sometimes the device will not have the first choice symbol so check first
    // Return a default that is always present
    func getParkingLocationImageName() -> String {
        //    systemName:"parkingsign.circle.fill"
        //    systemName:"parkingsign.circle"
        //    systemName:"car"
        //    systemName:"car.fill"
        //    systemName:"circle.fill")
        //    systemName:"note.text"
        //    systemName:"parkingsign"
        //    systemName:"parkingsign.circle.fill"
        //    systemName:"parkingsign.circle"
        //    systemName:"figure.walk"
        //    systemName:"figure.stand"
        //    systemName:"dot.arrowtriangles.up.right.down.left.circle"
        //    systemName:"doc.richtext"

        // Check symbols in order of preference
        if UIImage(systemName: "parkingsign.circle") != nil { return "parkingsign.circle" }
        if UIImage(systemName: "parkingsign") != nil { return "parkingsign" }
        if UIImage(systemName: "car") != nil { return "car" }
        return "triangle" // default that is always there on all devices
    }

    // Sometimes the device will not have the first choice symbol so check first
    // Return a default that is always present
    func getOrientMapImageName() -> String {
        //    systemName:"parkingsign.circle.fill"
        //    systemName:"parkingsign.circle"
        //    systemName:"car"
        //    systemName:"car.fill"
        //    systemName:"circle.fill")
        //    systemName:"note.text"
        //    systemName:"parkingsign"
        //    systemName:"parkingsign.circle.fill"
        //    systemName:"parkingsign.circle"
        //    systemName:"figure.walk"
        //    systemName:"figure.stand"
        //    systemName:"dot.arrowtriangles.up.right.down.left.circle"
        //    systemName:"doc.richtext"

        // Check symbols in order of preference
        
        if UIImage(systemName: "dot.circle.viewfinder") != nil { return "dot.circle.viewfinder" }
        if UIImage(systemName: "dot.arrowtriangles.up.right.down.left.circle") != nil { return "dot.arrowtriangles.up.right.down.left.circle" }
        return "triangle" // default that is always there on all devices
    }

    
    // MARK: CLLocationManagerDelegate Functions

    // REQUIRED - Tells the delegate that new location data is available.
    // The MOST RECENT location is the last one in the array
    func locationManager(_ locationManager: CLLocationManager, didUpdateLocations: [CLLocation]) {
        print("**Called: locationManager(_ locationManager CLLocationManager, didUpdateLocations: [CLLocation]), updateParkingSpotFlag=\(theMapModel.updateParkingSpotFlag)")
        
        if theMapModel.updateParkingSpotFlag == true {
            // Update the parking spot location and set the flag back to false
            theMapModel.updateParkingSpotFlag = false
            let currentLocation = didUpdateLocations.last!.coordinate // The array is guananteed to have at least one element
            ParkingSpotEntity.getParkingSpotEntity().updateLocation(lat: currentLocation.latitude, lon: currentLocation.longitude, andSave: true) // wdhx
            print("** Updated the parking spot in Map_ViewModel.locationManager(didUpdateLocations)")
        }
    }

    // REQUIRED
    // This must be implemented or you'll get a runtime error when requesting a map location update
    // Tells the delegate that the location manager was unable to retrieve a location value.
    func locationManager(_ locationManager: CLLocationManager, didFailWithError: Error) {
        print("wdh ERROR Map_ViewModel.locationManager(didFailWithError) Error: \(didFailWithError.localizedDescription)")
    }
    

    
//    // Heading - Tells the delegate that the location manager received updated heading information.
//    // Note: Must have previously called mLocationManager?.startUpdatingHeading() for this to be called
//    func locationManager(_ locationManager: CLLocationManager, didUpdateHeading: CLHeading) {}
//
//    // Tells the delegate when the app creates the location manager and when the authorization status changes.
//    func locationManagerDidChangeAuthorization(_ locationManager: CLLocationManager) {}
//
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
        print("Map_ViewModel.updateParkingSpot() wdh Intent Function")
        
        // Set the Flag to tell the callback to upate the parking spot location SEE: locationManager(didUpdateLocations:) in this same class
        theMapModel.updateParkingSpotFlag = true
        
        // Tell the location manager to upate the location and call the locationManager(didUpdateLocations:) function above.
        mLocationManager?.requestLocation()
    }
    
        
    // MARK: Getters
    
    func getRegionToShow() -> MKCoordinateRegion {
        // TODO: Return a bounding box centered on the current location and containing the ParkingSpot
        print("Map_ViewMode.getRegionToShow() called but not implemented yet")
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.95, longitude: -104.96),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        return region
    }

    
    func getParkingSpot() -> MKPlacemark {
        let theCoord = CLLocationCoordinate2D(latitude: ParkingSpotEntity.getParkingSpotEntity().lat, longitude: ParkingSpotEntity.getParkingSpotEntity().lon)
        return MKPlacemark(coordinate: theCoord)
        // Grandma's House 40.02639828963394, -105.27067477468266
        // Apple Headquarters - latitude: 37.33182, longitude: -122.03118
    }
        
    
}

