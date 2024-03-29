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
import StoreKit
import Network


//Next create a new app library to write a debug file to the app folder
//https://www.hackingwithswift.com/books/ios-swiftui/writing-data-to-the-documents-directory
//https://www.hackingwithswift.com/example-code/strings/how-to-save-a-string-to-a-file-on-disk-with-writeto

//Test Logger io.log2phys
//https://www.avanderlee.com/workflow/oslog-unified-logging/

let FOR_RELEASE = true // Set to true if releasing the app.

class Map_ViewModel: NSObject, ObservableObject, CLLocationManagerDelegate  {
    // This class
    //   1 - provides data to the view in a way the view can easily consume it
    //   2 - provides 'Intent' functions for the view to change the data
    
    // MARK: Constants
//    static let MIN_MAP_WIDTH = 25.0 // In MapPoints units
//    static let MIN_MAP_HEIGHT = 150.0 // In MapPoints units
//    static let MIN_MAP_WIDTH = 100.0 // In MapPoints units
//    static let MIN_MAP_HEIGHT = 600.0 // In MapPoints units

    // MARK: Member Vars
    @Published private var theMapModel: Map_Model = Map_Model()
    @Published public var parkingSpotMoved = false // Signal when the parking spot moves so the map knows to move the parking icon
    @Published public var theDistance = 123
    
//    var theMapCamera = MKMapCamera()
    private var mStillNeedToOrientMap = true // Set to true when the map needs to be oriented

    private var mLocationManager: CLLocationManager?
    
    
    // MARK: Flag Variables
    var isHybrid: Bool { // Expose this so the View can modify it indirectily through the ViewModel
        get {
            return theMapModel.isHybrid
        }
        set(newValue) {
            theMapModel.isHybrid = newValue
        }
    }

    // Flag to signal to the map that the user wants the map re-centered and oriented in his direction
    private var orientMapFlag: Bool {
        get {
            return theMapModel.orientMapFlag
        }
        set(orientFlag) {
            theMapModel.orientMapFlag = orientFlag
        }
    }


    
    // MARK: Init Functions
    override init() {
//        MyLog.debug("Map_ViewModel init() called")

        // Initialize the LocationManager - https://stackoverflow.com/questions/60356182/how-to-invoke-a-method-in-a-view-in-swiftui
        mLocationManager = CLLocationManager()
        super.init() // Call the NSObject init - Must be after member vars are initialized and before 'self' is referenced
        
        mLocationManager?.requestWhenInUseAuthorization()
//        mLocationManager?.requestAlwaysAuthorization() // Request permission even when the app is not in use
        mLocationManager?.delegate = self
        
        // Save battery by not enabling the UpdateLocation and UpdateHeading??? Not sure
        mLocationManager?.startUpdatingLocation() // Will call the delegate's didUpdateLocations function when locaiton changes
        mLocationManager?.startUpdatingHeading() // Will call the delegates didUpdateHeading function when heading changes
        
        // Apps that want to receive location updates when suspended must include the UIBackgroundModes key (with the location value) in their app’s Info.plist
        //mLocationManager?.allowsBackgroundLocationUpdates = true //must include the UIBackgroundModes key in the Info.plist
        
    }

    // View should call this to inform the ViewModel that the map no longer needs to be oriented
    func mapHasBeenResizedAndCentered() {
        mStillNeedToOrientMap = false
    }
    // View should call this to find out if the map needs to be oriented
    func isSizingAndCenteringNeeded() -> Bool {
        return mStillNeedToOrientMap
    }
    
    
    
    func getLastKnownLocation() -> CLLocationCoordinate2D {
        // Get current location.  IF none, then use the parking spot location as the current location
        let parkingLocation = getParkingSpotLocation() // Defalt to parking spot location if we don't have a last known location
        var lastKnownLocation = parkingLocation
        
        if (mLocationManager != nil) {
            let tmpLoc = mLocationManager!.location // CLLocation - Center Point
            if tmpLoc != nil {
                lastKnownLocation = CLLocationCoordinate2D(latitude: (tmpLoc!.coordinate.latitude), longitude: (tmpLoc!.coordinate.longitude))
            }
        }
        return lastKnownLocation
    }
    

    // Find the distance between the parking spot and the current location.
    // Make the map width/height be double that distance minus some buffer percentage
    // make sure the center stays in the center after subtracting the buffer
    func getBoundingMKCoordinateRegion() -> MKCoordinateRegion {
        let parkingLocation = getParkingSpotLocation()
        let lastKnownLocation = getLastKnownLocation()

        // Convert from lat/lon to points so we can do distance math
        let parkLoc = MKMapPoint(parkingLocation)
        let centLoc = MKMapPoint(lastKnownLocation)

        // Pathagorean Theorem to find distance
        let dx = Double(parkLoc.x-centLoc.x)
        let dy = Double(parkLoc.y-centLoc.y)
        var distance = pow((pow(dx,2) + pow(dy,2)), 0.5) // square root of A Squared plus B Squard
        distance = distance * 1.1 // Add buffer around the map so the parking location stays on the map
        
        // The Left and Right sides will be the center +/- the distance between the points
        let left = centLoc.y - distance
//        let right = centLoc.x + distance
        let bottom = centLoc.y - distance
//        let top = centLoc.y + distance
        let width = distance * 2
        let height = distance * 2
        
        let theMKMapRect = MKMapRect.init(x: left, y: bottom, width: width, height: height) // Lower Left origin
        let theMKCoordinateRegion = MKCoordinateRegion(theMKMapRect)
        return theMKCoordinateRegion
    }

    
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

    // REQUIRED - Called EVERY TIME the location data is updated
    // The MOST RECENT location is the last one in the array
    func locationManager(_ locationManager: CLLocationManager, didUpdateLocations: [CLLocation]) {
//        MyLog.debug("Called: Map_ViewModel.locationManager(_ locationManager CLLocationManager, didUpdateLocations: [CLLocation])")
        
        let currentLocation = didUpdateLocations.last!.coordinate // The array is guananteed to have at least one element wdh!

        if theMapModel.updateParkingSpotFlag == true {
            // Update the parking spot location and set the flag back to false
            theMapModel.updateParkingSpotFlag = false
            ParkingSpotEntity.getParkingSpotEntity().updateLocation(lat: currentLocation.latitude, lon: currentLocation.longitude, andSave: true) 
//            MyLog.debug("** Updated the parking spot in Map_ViewModel.locationManager(didUpdateLocations)")
            
            // Now that the parking spot has been updated, let the map know to move the marker
            parkingSpotMoved = true
        }
        
        // Update the distance
        let parkingSpot = getParkingSpotLocation()
        theDistance = getDistanceInFeet(p1: parkingSpot, p2: currentLocation)
    }

    func getDistanceInFeet(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D) -> Int {
        // Calculate Distance
        
        let source = CLLocation(latitude: p1.latitude, longitude: p1.longitude)
        let destination = CLLocation(latitude: p2.latitude, longitude: p2.longitude)
        
        let distanceInMeters = source.distance(from: destination)
        let distanceInFeet = Int(distanceInMeters * 3.28084) // Convert to Feet
        return distanceInFeet
    }
    
    // REQUIRED
    // This must be implemented or you'll get a runtime error when requesting a map location update
    // Tells the delegate that the location manager was unable to retrieve a location value.
    func locationManager(_ locationManager: CLLocationManager, didFailWithError: Error) {
        MyLog.debug("wdh Due to looking for location before user approved Allow Once ERROR Map_ViewModel.locationManager(didFailWithError) Error: \(didFailWithError.localizedDescription)")
    }
    

    
    // Heading - Tells the delegate that the location manager received updated heading information.
    // Note: Must have previously called mLocationManager?.startUpdatingHeading() for this to be called
    func locationManager(_ locationManager: CLLocationManager, didUpdateHeading: CLHeading) {
//        MyLog.debug("Map_ViewModel.LocaitonManager didUpdateHeading: \(didUpdateHeading)")
        theMapModel.currentHeading = didUpdateHeading.trueHeading
    }
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
    
    
    func orientMap() {
        orientMapFlag = true // Trigger map update
        mStillNeedToOrientMap = true // True until the map tells us it's been oriented using the mapHasBeenOriented() intent func
//        AlertMessage.shared.Alert("Test Alert: Called from ViewModel orientMap()")
    }

    
    func updateParkingSpot() {
        // Set the Flag to tell the callback to upate the parking spot location SEE: locationManager(didUpdateLocations:) in this same class
        theMapModel.updateParkingSpotFlag = true
        
        // Tell the location manager to upate the location and call the locationManager(didUpdateLocations:) function above.
        mLocationManager?.requestLocation()
    }
        
    func requestReview() {
        if !FOR_RELEASE { return } // Don't show review request when I'm testing the app.
        
        if AppInfoEntity.getAppInfoEntity().usageCount > AppInfoEntity.REVIEW_THRESHOLD {
        // NOTE: If not connected to Internet, then requestReview will lock the interface
            let reachability = try? Reachability() // Return nil if throws an error
            if reachability?.connection == .wifi {
//                MyLog.debug("Reachable via WiFi")
                if let windowScene = UIApplication.shared.windows.first?.windowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            } else if reachability?.connection == .cellular {
//                MyLog.debug("Reachable via Cellular")
                if let windowScene = UIApplication.shared.windows.first?.windowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
        }
    }
    
    func stopCenteringMap() {
        // Call this when the user is manipulating the map by hand to stop the map from recentering
        theMapModel.keepMapCentered = false
    }
    func startCenteringMap() {
        // Call this if the user wants the map to stay centered on the current location
        theMapModel.keepMapCentered = true
    }
    func shouldKeepMapCentered() -> Bool {
        // This tells the caller if the map should be centered or not
        return theMapModel.keepMapCentered
    }
    
    
    // MARK: Getters
        
    func getCurrentHeading() -> Double {
        return theMapModel.currentHeading
    }
    
    func getParkingSpotLocation() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: ParkingSpotEntity.getParkingSpotEntity().lat, longitude: ParkingSpotEntity.getParkingSpotEntity().lon)
    }
    
    func getParkingSpot() -> MKPlacemark {
        return MKPlacemark(coordinate: getParkingSpotLocation())
    }
        
    
}

