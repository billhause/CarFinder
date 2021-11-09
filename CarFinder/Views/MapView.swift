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
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

struct MapView: UIViewRepresentable {
    
    typealias UIViewType = MKMapView
    
    @ObservedObject var theMap_ViewModel: Map_ViewModel
    let mapView = MKMapView() // TouchDetect - made member var instead of local var in makeUIView
    
    
    func makeCoordinator() -> MapViewCoordinator {
        // This func is required by the UIViewRepresentable protocol
        // It returns an instance of the class MapViewCoordinator which we also made below
        // MapViewCoordinator implements the MKMapViewDelegate protocol and has a method to return
        // a renderer for the polyline layer
        return MapViewCoordinator(self, theMapVM: theMap_ViewModel) // Pass in the view model so that the delegate has access to it
    }
    
    // Required by UIViewRepresentable protocol
    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
        
        // Part of the UIViewRepresentable protocol requirements
        mapView.delegate = context.coordinator // Set delegate to the delegate returned by the 'makeCoordinator' function we added to this class

        // Initialize Map Settings
        // NOTE Was getting runtime error on iPhone: "Style Z is requested for an invisible rect" to fix
        //  From Xcode Menu open Product->Scheme->Edit Scheme and select 'Arguments' then add environment variable "OS_ACTIVITY_MODE" with value "disable"
//        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
//        mapView.isPitchEnabled = true
//        mapView.isRotateEnabled = true
//        mapView.showsBuildings = true
        mapView.showsUserLocation = true // Start map showing the user as a blue dot
        mapView.showsCompass = false
        mapView.showsScale = true  // Show distance scale when zooming
        mapView.showsTraffic = false
        mapView.mapType = .standard // .hybrid or .standard - Start as standard

        // Follow, center, and orient in direction of travel/heading
//        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true) // .followWithHeading, .follow, .none

        // Add the parking spot annotation to the map
        mapView.addAnnotations([theMap_ViewModel.getParkingSpot()])
        theMap_ViewModel.orientMap() // zoom in on the current location and the parking location
        
        return mapView

    }
    
    
    // This gets called when ever the Model changes
    // Required by UIViewRepresentable protocol
    func updateUIView(_ mapView: MKMapView, context: Context) {
        print("MapView.updateUIView() called")
        
        // Set Hybrid/Standard mode if it changed
        if (mapView.mapType != .hybrid) && theMap_ViewModel.isHybrid {
            mapView.mapType = .hybrid
        } else if (mapView.mapType == .hybrid) && !theMap_ViewModel.isHybrid {
            mapView.mapType = .standard
        }
        
        if theMap_ViewModel.parkingSpotMoved {
            theMap_ViewModel.parkingSpotMoved = false
            // Remove theParking Spot annotation and re-add it in case it moved and triggered this update
            // Avoid removing the User Location Annotation
            mapView.annotations.forEach {
                if !($0 is MKUserLocation) {
                    mapView.removeAnnotation($0)
                }
            }
            // Now add the parking spot annotation in it's new location
            mapView.addAnnotations([theMap_ViewModel.getParkingSpot()])
            print("Updated the Parking Spot in MapView")
        }
        
        //Setup our Map View

        // Size and Center the map
        if theMap_ViewModel.isSizingAndCenteringNeeded() { // The use has hit the orient map button
            
            theMap_ViewModel.mapHasBeenResizedAndCentered()
            
            theMap_ViewModel.startCenteringMap() // Set flag to continue to keep the map centered on the current location
            
            // Set the bounding rect to show the current location and the parking spot
            mapView.setRegion(theMap_ViewModel.getBoundingMKCoordinateRegion(), animated: false) // If animated, this gets overwritten when heading is set
            
            // Center the map on the current location
            mapView.setCenter(theMap_ViewModel.getLastKnownLocation(), animated: false) // If animated, this gets overwritten when heading is set

            print("wdh MapView.UpdateUIView: Centering Map on Current Location")
        }

        // Set the HEADING
        mapView.camera.heading=theMap_ViewModel.getCurrentHeading() // Adjustes map direction without affecting zoom level
        
//        withAnimation { Has No Effect on jumpiness
//        mapView.camera.heading=theMap_ViewModel.getCurrentHeading() // Adjustes map direction without affecting zoom level
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
        var parent: MapView // TouchDetect - We'll need to reference the MapView object
        var gRecognizer = UITapGestureRecognizer() // TouchDetect
        
        // We need an init so we can pass in the Map_ViewModel class
        // TODO: Instead of passing the parent struct MapView object, just pass the parent's class mapView since that's all we need and it's a class to no copies are made
        init(_ parent: MapView, theMapVM: Map_ViewModel) { // Pass MapView for TouchDetect
            theMap_ViewModel = theMapVM
            self.parent = parent // TouchDetect will need to reference this
            super.init()
            // wdhx continue here
            self.gRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler)) // TouchDetect
            self.gRecognizer.delegate = self // TouchDetect
            self.parent.mapView.addGestureRecognizer(gRecognizer)
        }
        
        @objc func tapHandler(_gesture: UITapGestureRecognizer) {
            // Position on the screen, CGPoint
            let location = gRecognizer.location(in: self.parent.mapView)
            // postion on map, CLLocationCoordinate2D
            let coordinate = self.parent.mapView.convert(location, toCoordinateFrom: self.parent.mapView)
            print("LatLon Tapped: Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
        }
        
        // Added to render the PolyLine Overlay to draw the route between two points
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            print("wdh Created PolyLine Renderer")
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
            print("Called1 'func mapView(_ mapView: MKMapView, regionWillChangeAnimated: \(regionWillChangeAnimated))'")
        }
        
        // The map view's visible region changed.
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            print("Called2 'func mapViewDidChangeVisibleRegion(_ mapView: MKMapView)'")
        }

        // The map view's visible region changed.
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated: Bool) {
            print("Called3 'func mapView(MKMapView, regionDidChangeAnimated: \(regionDidChangeAnimated))'")
        }
        
        // MARK: Optional - Loading the Map Data
        
        // The specified map view is about to retrieve some map data.
        func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
//            print("Called4 'func mapViewWillStartLoadingMap(_ mapView: MKMapView)'")
        }
        
        // The specified map view successfully loaded the needed map data.
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//            print("wdh Finished Loading Map 'func mapViewDidFinishLoadingMap(_ mapView: MKMapView)'")
        }
        
        // The specified view was unable to load the map data.
        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError: Error) {
//            print("Called6 'func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError: Error)'")
        }
        
        // The map view is about to start rendering some of its tiles.
        func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
//            print("Called7 'func mapViewWillStartRenderingMap(_ mapView: MKMapView)'")
        }
        
        // The map view has finished rendering all visible tiles.
        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
//            print("Called7.5 func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: \(fullyRendered))'")
        }

        // MARK: Optional - Tracking the User Location
        
        // The map view will start tracking the user’s position.
        func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
//            print("Called8: 'func mapViewWillStartLocatingUser(_ mapView: MKMapView)'")
        }
        
        // The map view stopped tracking the user’s location.
        func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
//            print("Called9: 'func mapViewDidStopLocatingUser(_ mapView: MKMapView)'")
        }
        
        // The location of the user was updated.
        func mapView(_ mapView: MKMapView, didUpdate: MKUserLocation) {
            print("Called10: 'func mapView(_ mapView: MKMapView, didUpdate: MKUserLocation)'")
            // Center the map on the current location
            if theMap_ViewModel.shouldKeepMapCentered() { // Only do this if the user wants the map to stay centered
                mapView.setCenter(theMap_ViewModel.getLastKnownLocation(), animated: true)
            }

        }
        
        // An attempt to locate the user’s position failed.
        func mapView(_ mapView: MKMapView, didFailToLocateUserWithError: Error) {
//            print("Called11: 'func mapView(_ mapView: MKMapView, didFailToLocateUserWithError: Error)'")
        }
        
        // The user tracking mode changed.
        func mapView(_ mapView: MKMapView, didChange: MKUserTrackingMode, animated: Bool) {
            print("wdh MKUserTrackingMode: \(didChange.rawValue)")
//            print("Called12: 'func mapView(_ mapView: MKMapView, didChange: MKUserTrackingMode, animated: \(animated)'")
        }
        
        // MARK: Optional - Managing Annotation Views

        // Return the annotation view to display for the specified annotation or
        // nil if you want to display a standard annotation view.
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            print("Called13: 'func mapView(_ mapView: MKMapView, viewFor: MKAnnotation) -> MKAnnotationView?'")

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
            print("Called14: 'func mapView(_ mapView: MKMapView, didAdd: [MKAnnotationView])'")
        }

        // The user tapped one of the annotation view’s accessory buttons.
        func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped: UIControl) {
            print("Called15: 'func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped: UIControl)'")
        }
        
        // Asks the delegate to provide a cluster annotation object for the specified annotations.
        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            print("THIS IS WRONG wdh Called: 'func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations: [MKAnnotation]) -> MKClusterAnnotation'")
            return MKClusterAnnotation(memberAnnotations: clusterAnnotationForMemberAnnotations) // THIS IS WRONG
        }

        
        // MARK: Optional - Dragging an Annotation View

        // The drag state of one of its annotation views changed.
        func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, didChange: MKAnnotationView.DragState, fromOldState: MKAnnotationView.DragState) {
            print("Called16: 'func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, didChange: MKAnnotationView.DragState, fromOldState: MKAnnotationView.DragState)'")
        }

        // MARK: Optional - Selecting Annotation Views
        
        // One of its annotation views was selected.
        func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
            print("Called17: 'func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView)'")
        }

        // One of its annotation views was deselected.
        func mapView(_ mapView: MKMapView, didDeselect: MKAnnotationView) {
            print("Called18: 'func mapView(_ mapView: MKMapView, didDeselect: MKAnnotationView)'")
        }

        // MARK: Optional - Managing the Display of Overlays
        
        
        // Tells the delegate that one or more renderer objects were added to the map.
        func mapView(_ mapView: MKMapView, didAdd: [MKOverlayRenderer]) {
            print("Called19: 'func mapView(MKMapView, didAdd: [MKOverlayRenderer])'")
        }
            
        
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    }
    
    
    
}

