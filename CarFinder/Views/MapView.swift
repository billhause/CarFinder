//
//  MapView.swift
//  CarFinder
//
//  Created by William Hause on 10/19/21.
//

import Foundation
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    
    typealias UIViewType = MKMapView
    
    @ObservedObject var theMap_ViewModel: Map_ViewModel
    
    func makeCoordinator() -> MapViewCoordinator {
        // This func is required by the UIViewRepresentable protocol
        // It returns an instance of the class MapViewCoordinator which we also made below
        // MapViewCoordinator implements the MKMapViewDelegate protocol and has a method to return
        // a renderer for the polyline layer
        return MapViewCoordinator(theMap_ViewModel)
    }
    
    // Required by UIViewRepresentable protocol
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // Part of the UIViewRepresentable protocol requirements
        mapView.delegate = context.coordinator // Set delegate to the delegate returned by the 'makeCoordinator' function we added to this class

        // Region to show
        let region = theMap_ViewModel.getRegionToShow()
        mapView.setRegion(region, animated: true)

        // Set the region that will be visible showing NYC and Boston
//        mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)


        // Initialize Map Settings
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        mapView.showsUserLocation = true // Start map showing the user as a blue dot
//        mapView.isPitchEnabled = true
//        mapView.isRotateEnabled = true
//        mapView.showsBuildings = true
//        mapView.showsCompass = true
        mapView.showsScale = true  // Show distance scale when zooming
        mapView.showsTraffic = false
        mapView.mapType = .standard // .hybrid or .standard - Start as standard

        // Follow, center, and orient in direction of travel/heading
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true) // .followWithHeading, .follow, .none

        return mapView

    }
    

    // This gets called when ever the Model changes
    // Required by UIViewRepresentable protocol
    func updateUIView(_ mapView: MKMapView, context: Context) {
                
        // If the OrientMap flag is on, then the user just touched OrientMap.
        // Set Map to Follow, center map, oriented in facing direction with Radar bloop, zoom to bounding rect, set the flag back to false and return
        if theMap_ViewModel.orientMapFlag {
            theMap_ViewModel.orientMapFlag = false
            
            // Follow, center, and orient in direction of travel/heading
            mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true) // .followWithHeading, .follow, .none
//            mapView.showsUserLocation = true
            
            // Zoom to bounding rect
            let boundingRect = theMap_ViewModel.getBoundingRect()
//            mapView.setVisibleMapRect(boundingRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
            mapView.setVisibleMapRect(boundingRect, animated: true)
//            func setVisibleMapRect(_ mapRect: MKMapRect, edgePadding insets: UIEdgeInsets, animated animate: Bool)
                        
           // wdhs
            print("MapView.updateUIView() - Orient The Map wdhx")
            return
        }
        
        // Remove theParking Spot annotation and re-add it in case it moved and triggered this update
        // Avoid removing the User Location Annotation
        mapView.annotations.forEach {
            if !($0 is MKUserLocation) {
                mapView.removeAnnotation($0)
            }
        }
        // Now add the parking spot annotation
        mapView.addAnnotations([theMap_ViewModel.getParkingSpot()])
        
        print("updateUIView() called")
    }
    

    
    
    // Delegate created by Bill to handle various call-backs from the MapView class.
    // This handles things like
    //   - drawing the generated poly-lines layers on the map,
    //   - returning Annotation views to render the annotation points
    //   - Draging and Selecting Annotations
    //   - Respond to map position changes etc.
    // This class is defined INSIDE the MapView Struct
    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        var theMap_ViewModel: Map_ViewModel
        
        // We need an init so we can pass in the Map_ViewModel class
        init(_ theMapVM: Map_ViewModel) {
            theMap_ViewModel = theMapVM
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
            print("Called 'func mapView(_ mapView: MKMapView, regionWillChangeAnimated: \(regionWillChangeAnimated))'")
        }
        
        // The map view's visible region changed.
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//            print("Called 'func mapViewDidChangeVisibleRegion(_ mapView: MKMapView)'")
        }

        // The map view's visible region changed.
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated: Bool) {
            print("Called 'func mapView(MKMapView, regionDidChangeAnimated: \(regionDidChangeAnimated))'")
        }
        
        // MARK: Optional - Loading the Map Data
        
        // The specified map view is about to retrieve some map data.
        func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
            print("Called 'func mapViewWillStartLoadingMap(_ mapView: MKMapView)'")
        }
        
        // The specified map view successfully loaded the needed map data.
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("Called 'func mapViewDidFinishLoadingMap(_ mapView: MKMapView)'")
        }
        
        // The specified view was unable to load the map data.
        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError: Error) {
            print("Called 'func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError: Error)'")
        }
        
        // The map view is about to start rendering some of its tiles.
        func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
            print("Called 'func mapViewWillStartRenderingMap(_ mapView: MKMapView)'")
        }
        
        // The map view has finished rendering all visible tiles.
        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            print("Called 'func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: \(fullyRendered))'")
        }

        // MARK: Optional - Tracking the User Location
        
        // The map view will start tracking the user’s position.
        func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
            print("Called: 'func mapViewWillStartLocatingUser(_ mapView: MKMapView)'")
        }
        
        // The map view stopped tracking the user’s location.
        func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
            print("Called: 'func mapViewDidStopLocatingUser(_ mapView: MKMapView)'")
        }
        
        // The location of the user was updated.
        func mapView(_ mapView: MKMapView, didUpdate: MKUserLocation) {
//            print("Called: 'func mapView(_ mapView: MKMapView, didUpdate: MKUserLocation)'")
        }
        
        // An attempt to locate the user’s position failed.
        func mapView(_ mapView: MKMapView, didFailToLocateUserWithError: Error) {
            print("Called: 'func mapView(_ mapView: MKMapView, didFailToLocateUserWithError: Error)'")
        }
        
        // The user tracking mode changed.
        func mapView(_ mapView: MKMapView, didChange: MKUserTrackingMode, animated: Bool) {
            print("Called: 'func mapView(_ mapView: MKMapView, didChange: MKUserTrackingMode, animated: \(animated)'")
        }
        
        // MARK: Optional - Managing Annotation Views

        // Return the annotation view to display for the specified annotation or
        // nil if you want to display a standard annotation view.
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            print("Called: 'func mapView(_ mapView: MKMapView, viewFor: MKAnnotation) -> MKAnnotationView?'")

            if (annotation is MKUserLocation) {
                // This is the User Location (Blue Dot) so just use the default annotation icon by returning nil
                return nil
            }
            
            let Identifier = "Pin"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: Identifier)

            annotationView.canShowCallout = true
            
            let dotSize = 25
              
            let theColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
  
            let dotImage = UIImage(systemName: theMap_ViewModel.getParkingLocationImageName())!.withTintColor(theColor)

            let size = CGSize(width: dotSize, height: dotSize)

            // Create Annotation Image and return it
            annotationView.image = UIGraphicsImageRenderer(size:size).image {
                _ in dotImage.draw(in:CGRect(origin:.zero, size:size))
            }
            
            // Print all Annotations in the map
            for annotation in mapView.annotations {
                print("Annotation: \(annotation.coordinate)")
            }
            
            
            return annotationView
        }
        
        
        // One or more annotation views were added to the map.
        func mapView(_ mapView: MKMapView, didAdd: [MKAnnotationView]) {
            print("Called: 'func mapView(_ mapView: MKMapView, didAdd: [MKAnnotationView])'")
        }

        // The user tapped one of the annotation view’s accessory buttons.
        func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped: UIControl) {
            print("Called: 'func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped: UIControl)'")
        }
        
        // Asks the delegate to provide a cluster annotation object for the specified annotations.
        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            print("THIS IS WRONG wdh Called: 'func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations: [MKAnnotation]) -> MKClusterAnnotation'")
            return MKClusterAnnotation(memberAnnotations: clusterAnnotationForMemberAnnotations) // THIS IS WRONG
        }

        
        // MARK: Optional - Dragging an Annotation View

        // The drag state of one of its annotation views changed.
        func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, didChange: MKAnnotationView.DragState, fromOldState: MKAnnotationView.DragState) {
            print("Called: 'func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, didChange: MKAnnotationView.DragState, fromOldState: MKAnnotationView.DragState)'")
        }

        // MARK: Optional - Selecting Annotation Views
        
        // One of its annotation views was selected.
        func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView) {
            print("Called: 'func mapView(_ mapView: MKMapView, didSelect: MKAnnotationView)'")
        }

        // One of its annotation views was deselected.
        func mapView(_ mapView: MKMapView, didDeselect: MKAnnotationView) {
            print("Called: 'func mapView(_ mapView: MKMapView, didDeselect: MKAnnotationView)'")
        }

        // MARK: Optional - Managing the Display of Overlays
        
        
        // Tells the delegate that one or more renderer objects were added to the map.
        func mapView(_ mapView: MKMapView, didAdd: [MKOverlayRenderer]) {
            print("Called: 'func mapView(MKMapView, didAdd: [MKOverlayRenderer])'")
        }
            
        
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    }
    
    
    
}

