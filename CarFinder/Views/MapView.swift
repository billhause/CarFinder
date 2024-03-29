//
//  MapView.swift
//  CarFinder
//
//  Created by William Hause on 10/19/21.
//

import Foundation
import SwiftUI
import MapKit
import UIKit
import CoreLocation
import os

// ======= Adding Touch Detection =======
// https://stackoverflow.com/questions/63110673/tapping-an-mkmapview-in-swiftui
// Code marked with TouchDetect
// Note the sample code passes the init a struct copy of the parent but only needs to pass a reference to the class mapView
//
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//var globalHeadingLocked = false // For debugging and making videos.  Normally this should always be false for release version

struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    
    @ObservedObject var theMap_ViewModel: Map_ViewModel
    @State var mMapView = MKMapView() // TouchDetect - made member var instead of local var in makeUIView NOTE: MUST BE @State or duplicate instances will be created
    
    func isParkingSpotShownOnMap() -> Bool {
        // NOTE: There seems to be some buffer off the side of the map so sometimes it says it's shown when it isn't really
        let parkingSpotLatLon = theMap_ViewModel.getParkingSpotLocation()
        let parkingSpotMKMapPoint = MKMapPoint(parkingSpotLatLon)
        let theVisibleMKMapRect = self.mMapView.visibleMapRect
        let result = theVisibleMKMapRect.contains(parkingSpotMKMapPoint)
        return result
    }
    
    func makeCoordinator() -> MapViewCoordinator {
        // This func is required by the UIViewRepresentable protocol
        // It returns an instance of the class MapViewCoordinator which we also made below
        // MapViewCoordinator implements the MKMapViewDelegate protocol and has a method to return
        // a renderer for the polyline layer
//        return MapViewCoordinator(mMapView, theMapVM: theMap_ViewModel) // Pass in the view model so that the delegate has access to it
        return MapViewCoordinator(self, theMapVM: theMap_ViewModel) // Pass in the view model so that the delegate has access to it
    }
    
    // Required by UIViewRepresentable protocol
    func makeUIView(context: Context) -> MKMapView {

        // Part of the UIViewRepresentable protocol requirements
        mMapView.delegate = context.coordinator // Set delegate to the delegate returned by the 'makeCoordinator' function we added to this class

        // Initialize Map Settings
        // NOTE Was getting runtime error on iPhone: "Style Z is requested for an invisible rect" to fix
        //  From Xcode Menu open Product->Scheme->Edit Scheme and select 'Arguments' then add environment variable "OS_ACTIVITY_MODE" with value "disable"
//        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
//        mapView.isPitchEnabled = true
//        mapView.showsBuildings = true
        mMapView.isRotateEnabled = false // Don't let the user manually rotate the map.
        mMapView.showsUserLocation = true // Start map showing the user as a blue dot
        mMapView.showsCompass = false
        mMapView.showsScale = true  // Show distance scale when zooming
        mMapView.showsTraffic = false
        mMapView.mapType = .standard // .hybrid or .standard - Start as standard

        // Follow, center, and orient in direction of travel/heading
//        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true) // .followWithHeading, .follow, .none

        // Add the parking spot annotation to the map
        mMapView.addAnnotations([theMap_ViewModel.getParkingSpot()])
        theMap_ViewModel.orientMap() // zoom in on the current location and the parking location
        
        return mMapView

    }
    
//    mutating func updateMapViewReference(newMapView: MKMapView) {
//        mMapView = newMapView
//        MyLog.debug("updated mMapView wdh002")
//    }
    
    // This gets called when ever the Model changes
    // Required by UIViewRepresentable protocol
    func updateUIView(_ mapView: MKMapView, context: Context) {
//        MyLog.debug("MapView.updateUIView() called")
        let theMapView = mapView
        var bShouldSizeAndCenter = theMap_ViewModel.isSizingAndCenteringNeeded() 
        
        // Set Hybrid/Standard mode if it changed
        if (theMapView.mapType != .hybrid) && theMap_ViewModel.isHybrid {
            theMapView.mapType = .hybrid
        } else if (theMapView.mapType == .hybrid) && !theMap_ViewModel.isHybrid {
            theMapView.mapType = .standard
        }
        
        
        if theMap_ViewModel.parkingSpotMoved { // The user updated the parking spot so move the annotation
            theMap_ViewModel.parkingSpotMoved = false
            // Remove theParking Spot annotation and re-add it in case it moved and triggered this update
            // Avoid removing the User Location Annotation
            theMapView.annotations.forEach {
                if !($0 is MKUserLocation) {
                    theMapView.removeAnnotation($0)
                }
            }
            // Now add the parking spot annotation in it's new location
            theMapView.addAnnotations([theMap_ViewModel.getParkingSpot()])
//            MyLog.debug("Updated the Parking Spot in MapView")
            
            // Now orient the map for the new parking spot location
            bShouldSizeAndCenter = true // set flag that will Size and Center the map a few lines down from here
        }
        
        // If the parking spot is not on the map AND the user is not Messing with the Map then recenter it
        // It could be the parking spot drifted off the map OR we came back from background without knowing our location accurately
        if theMap_ViewModel.shouldKeepMapCentered() {
            if !isParkingSpotShownOnMap() {
                theMap_ViewModel.orientMap()
            }
        }

        // Size and Center the map Because the user hit the Orient Map Button
        if bShouldSizeAndCenter { // The use has hit the orient map button or did something requireing the map to be re-oriented
            
            theMap_ViewModel.mapHasBeenResizedAndCentered()
            
            theMap_ViewModel.startCenteringMap() // Switch to 'Centered Map Mode' to keep the map centered on the current location
            
            // Set the bounding rect to show the current location and the parking spot
            theMapView.setRegion(theMap_ViewModel.getBoundingMKCoordinateRegion(), animated: false) // If animated, this gets overwritten when heading is set
            
            // Center the map on the current location
            theMapView.setCenter(theMap_ViewModel.getLastKnownLocation(), animated: false) // If animated, this gets overwritten when heading is set

//            MyLog.debug("wdh MapView.UpdateUIView: Centering Map on Current Location")
        }

        // Set the HEADING
        theMapView.camera.heading=theMap_ViewModel.getCurrentHeading() // Adjustes map direction without affecting zoom level
//        if !globalHeadingLocked { // For debugging and recording videos.  Normally this will always be false wdhx
//            theMapView.camera.heading=theMap_ViewModel.getCurrentHeading() // Adjustes map direction without affecting zoom level
//        }
        
    }
    
//    Make map so that user can't drag map or rotate map manually
    
    // Delegate created by Bill to handle various call-backs from the MapView class.
    // This handles things like
    //   - drawing the generated poly-lines layers on the map,
    //   - returning Annotation views to render the annotation points
    //   - Draging and Selecting Annotations
    //   - Respond to map position changes etc.
    // This class is defined INSIDE the MapView Struct
    class MapViewCoordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate { // TouchDetect: added Gesture Delegate protocol
        var theMap_ViewModel: Map_ViewModel
        var parent: MapView // TouchDetect - Will need to access the parent MapView object
        var mTapGestureRecognizer = UITapGestureRecognizer() // TouchDetect - This also gets passed into the callbacks
        var mPinchGestureRecognizer = UIPinchGestureRecognizer() // TouchDetect - This also gets passed into the callbacks
//        var mPanGestureRecognizer = UIPanGestureRecognizer() // TouchDetect - This also gets passed into the callbacks

        // We need an init so we can pass in the Map_ViewModel class

//        init(_ theMKMapView: MKMapView, theMapVM: Map_ViewModel) { // Pass MKMapView for TouchDetect to convert pixels to lat/lon
        init(_ theMapView: MapView, theMapVM: Map_ViewModel) { // Pass MKMapView for TouchDetect to convert pixels to lat/lon
            theMap_ViewModel = theMapVM
//            self.mapView = theMKMapView // TouchDetect will need to reference this
            self.parent = theMapView // TouchDetect will need to reference this
            self.parent.mMapView.isUserInteractionEnabled = true
            super.init()

//            self.mapView.isUserInteractionEnabled = true
                        
            let thePanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panHandler(_:))) // TouchDetect
            thePanGestureRecognizer.delegate = self // TouchDetect
            thePanGestureRecognizer.minimumNumberOfTouches = 1
            thePanGestureRecognizer.maximumNumberOfTouches = 1
//            self.mapView.addGestureRecognizer(thePanGestureRecognizer) // TouchDetect
            self.parent.mMapView.addGestureRecognizer(thePanGestureRecognizer) // TouchDetect
            
            self.mTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler)) // TouchDetect
            self.mTapGestureRecognizer.delegate = self // TouchDetect
//            self.mapView.addGestureRecognizer(mTapGestureRecognizer) // TouchDetect
            self.parent.mMapView.addGestureRecognizer(mTapGestureRecognizer) // TouchDetect

            self.mPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchHandler)) // TouchDetect
            self.mPinchGestureRecognizer.delegate = self // TouchDetect
//            self.mapView.addGestureRecognizer(mPinchGestureRecognizer) // TouchDetect
            self.parent.mMapView.addGestureRecognizer(mPinchGestureRecognizer) // TouchDetect

        }

        // MARK: GestureRecognizer Delegate callback functions
        // GestureRecognizer Delegate function (optional)
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool { // TouchDetect - Called after every gesture starts
            // This function was called because the user is messing with the map.
            theMap_ViewModel.stopCenteringMap() // Tell view model user wants to stop auto-centering map
            return true
        }

        // MARK: Custom GestureRecognizer Handler functions that I created
        @objc func tapHandler(_ sender: UITapGestureRecognizer) { // TouchDetect: detect single tap and convert to lat/lon
//            var theMapView = sender.view as MapView
            
            if sender.state != .ended {
                return // Only need to process at the end of the gesture
            }
                
            // Position on the screen, CGPoint
            let location = mTapGestureRecognizer.location(in: self.parent.mMapView)
            // postion on map, CLLocationCoordinate2D
            let coordinate = self.parent.mMapView.convert(location, toCoordinateFrom: self.parent.mMapView)
            MyLog.debug("LatLon Tapped: Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
//            AlertMessage.shared.Alert("wdhx LatLon Tapped: Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
            
//            globalHeadingLocked = !globalHeadingLocked // Toggle when screen is tapped.  Comment this line out for relase version wdhx
        }

        // NOTE: FOR SOME REASON the panHandler and pinchHandler call-backs don't ever get called
        @objc func panHandler(_ sender: UIPanGestureRecognizer) { // TouchDetect
            MyLog.debug("panHandler Called in MapViewCoordinator class")
        }
        @objc func pinchHandler(_ sender: UIPinchGestureRecognizer) { // TouchDetect: detect pinch
            MyLog.debug("pinchHandler Called in MapViewCoordinator class")
        }

        
        // Added to render the PolyLine Overlay to draw the route between two points
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            MyLog.debug("wdh Created PolyLine Renderer")
            renderer.strokeColor = .blue
            renderer.lineWidth = 5
            return renderer
        }
        
        
        // VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
        // VVVVVVV Optional MKMapViewDelegate protocol functions that I added for demo/testing purposes VVVVV
        // VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

        // MARK: Optional - Responding to Map Position Changes
        // The region displayed by the map view is about to change.
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated: Bool) {
//            MyLog.debug("Called1 'func mapView(_ mapView: MKMapView, regionWillChangeAnimated: \(regionWillChangeAnimated))'")
        }
        
        // The map view's visible region changed.
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//            MyLog.debug("Called2 'func mapViewDidChangeVisibleRegion(_ mapView: MKMapView)'")
        }

        // The map view's visible region changed.
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated: Bool) {
//            MyLog.debug("Called3 'func mapView(MKMapView, regionDidChangeAnimated: \(regionDidChangeAnimated))'")
        }
        
        // MARK: Optional - Loading the Map Data
        
        // The specified map view is about to retrieve some map data.
        func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
//            MyLog.debug("Called4 'func mapViewWillStartLoadingMap(_ mapView: MKMapView)'")
        }
        
        // The specified map view successfully loaded the needed map data.
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//            MyLog.debug("wdh Finished Loading Map 'func mapViewDidFinishLoadingMap(_ mapView: MKMapView)'")
        }
        
        // The specified view was unable to load the map data.
        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError: Error) {
//            MyLog.debug("Called6 'func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError: Error)'")
        }
        
        // The map view is about to start rendering some of its tiles.
        func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
//            MyLog.debug("Called7 'func mapViewWillStartRenderingMap(_ mapView: MKMapView)'")
        }
        
        // The map view has finished rendering all visible tiles.
        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
//            MyLog.debug("Called7.5 func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: \(fullyRendered))'")
        }

        // MARK: Optional - Tracking the User Location
        
        // The map view will start tracking the user’s position.
        func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
//            MyLog.debug("Called8: 'func mapViewWillStartLocatingUser(_ mapView: MKMapView)'")
        }
        
        // The map view stopped tracking the user’s location.
        func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
//            MyLog.debug("Called9: 'func mapViewDidStopLocatingUser(_ mapView: MKMapView)'")
        }
        
        // The location of the user was updated.
        func mapView(_ mapView: MKMapView, didUpdate: MKUserLocation) {
//            MyLog.debug("Called10: 'func mapView(_ mapView: MKMapView, didUpdate: MKUserLocation)'")
            // Center the map on the current location
            if theMap_ViewModel.shouldKeepMapCentered() { // Only do this if the user wants the map to stay centered
                mapView.setCenter(theMap_ViewModel.getLastKnownLocation(), animated: true)
            }

        }
        
        // An attempt to locate the user’s position failed.
        func mapView(_ mapView: MKMapView, didFailToLocateUserWithError: Error) {
//            MyLog.debug("Called11: 'func mapView(_ mapView: MKMapView, didFailToLocateUserWithError: Error)'")
        }
        
        // The user tracking mode changed.
        func mapView(_ mapView: MKMapView, didChange: MKUserTrackingMode, animated: Bool) {
            MyLog.debug("wdh MKUserTrackingMode: \(didChange.rawValue)")
//            MyLog.debug("Called12: 'func mapView(_ mapView: MKMapView, didChange: MKUserTrackingMode, animated: \(animated)'")
        }
        
        // MARK: Optional - Managing Annotation Views

        // Return the annotation view to display for the specified annotation or
        // nil if you want to display a standard annotation view.
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            MyLog.debug("Called13: 'func mapView(_ mapView: MKMapView, viewFor: MKAnnotation) -> MKAnnotationView?'")

            if (annotation is MKUserLocation) {
                // This is the User Location (Blue Dot) so just use the default annotation icon by returning nil
                return nil
            }
            
            let Identifier = "Pin"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: Identifier)

            annotationView.canShowCallout = true
            
            let dotSize = 35 // Size for Parking Symbol
              
            let theColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
  
            let dotImage = UIImage(systemName: theMap_ViewModel.getParkingLocationImageName())!.withTintColor(theColor) // wdh!

            let size = CGSize(width: dotSize, height: dotSize)

            // Create Annotation Image and return it
            annotationView.image = UIGraphicsImageRenderer(size:size).image {
                _ in dotImage.draw(in:CGRect(origin:.zero, size:size))
            }
            
            return annotationView
        }
        
        
        // One or more annotation views were added to the map.
        func mapView(_ mapView: MKMapView, didAdd: [MKAnnotationView]) {
//            MyLog.debug("Called14: 'func mapView(_ mapView: MKMapView, didAdd: [MKAnnotationView])'")
        }

        // The user tapped one of the annotation view’s accessory buttons.
        func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped: UIControl) {
            MyLog.debug("Called15: 'func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped: UIControl)'")
        }
        
        // Asks the delegate to provide a cluster annotation object for the specified annotations.
        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            MyLog.debug("THIS IS WRONG wdh Called: 'func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations: [MKAnnotation]) -> MKClusterAnnotation'")
            return MKClusterAnnotation(memberAnnotations: clusterAnnotationForMemberAnnotations) // THIS IS WRONG
        }

        
        // MARK: Optional - Dragging an Annotation View

        // The drag state of one of its annotation views changed.
        func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, didChange: MKAnnotationView.DragState, fromOldState: MKAnnotationView.DragState) {
            MyLog.debug("Called16: 'func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, didChange: MKAnnotationView.DragState, fromOldState: MKAnnotationView.DragState)'")
        }

        // MARK: Optional - Selecting Annotation Views
        
        // One of its annotation views was selected.
        func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
            MyLog.debug("Called17: 'func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView)'")
        }

        // One of its annotation views was deselected.
        func mapView(_ mapView: MKMapView, didDeselect: MKAnnotationView) {
            MyLog.debug("Called18: 'func mapView(_ mapView: MKMapView, didDeselect: MKAnnotationView)'")
        }

        // MARK: Optional - Managing the Display of Overlays
        
        
        // Tells the delegate that one or more renderer objects were added to the map.
        func mapView(_ mapView: MKMapView, didAdd: [MKOverlayRenderer]) {
            MyLog.debug("Called19: 'func mapView(MKMapView, didAdd: [MKOverlayRenderer])'")
        }
            
        
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    }
    
    
    
}

