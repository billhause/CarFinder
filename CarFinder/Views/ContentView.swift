//
//  ContentView.swift
//  CarFinder
//
//  Created by William Hause on 10/16/21.
//

import SwiftUI
import CoreData
import os.log
import StoreKit

struct ContentView: View {
    @ObservedObject var theMap_ViewModel: Map_ViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var theAlert = AlertDialog.shared // Alert
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                // vvvvvvv ALERT MESSAGE vvvvvvvvv
                if #available(iOS 15.0, *) {
                    Spacer()
                        .alert(theAlert.theMessage, isPresented: $theAlert.showAlert) {
                            Button("OK", role: .cancel) { }
                        }
                } else {
                    // Fallback on earlier versions
                    Spacer()
                }
                // ^^^^^^^^^ ALERT MESSAGE ^^^^^^^^^^^^^
                HStack {
                    Spacer()
                    Text("Distance: \(theMap_ViewModel.theDistance) Feet")
                    Spacer()
                    Spacer()
                    Button(action: updateParkingSpot) {
                        let theColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
                        let imageString = theMap_ViewModel.getParkingLocationImageName()
                        Label("Update Parking Spot", systemImage: imageString)
                            .foregroundColor(Color(theColor))
                            .padding() // Move the Parking symbol away from right border a little bit
                    } //.font(.largeTitle)
                        .labelStyle(HorizontalLabelStyle())
                }
                MapView(theMap_ViewModel: theMap_ViewModel)
//                    .gesture(
//                        DragGesture()
//                            .onChanged({ value in print("DragGesture.onChanged: \(value)") })
//                            .onEnded({ _ in print("End")})
//                    )
//                    .gesture(TapGesture()
//                                .onEnded({
//                        print("Tapped! wdhx")
//                    }))
            } // VStack

//            .navigationBarTitle("Car Locator", displayMode: .inline) // inline moves the title to the same line as the buttons
            .navigationBarHidden(true)

            .toolbar {
                
//                ToolbarItem(placement: ToolbarItemPlacement.automatic) { // Top Toolbar
//                    Button(action: updateParkingSpot) {
//                        let theColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
//                        let imageString = theMap_ViewModel.getParkingLocationImageName()
//                        Label("Save Spot", systemImage: imageString)
//                            .foregroundColor(Color(theColor))
//                            .padding() // Move the Parking symbol away from right border a little bit
//                    } .font(.largeTitle)
//                }
                
                // Bottom Toolbar
                ToolbarItemGroup(placement: .bottomBar) {
                    // USE EITHER A PICKER or a TOGGLE below comment one out
                    // Picker
                    Picker("What kind of map do you want", selection: $theMap_ViewModel.isHybrid) {
                        Text("Hybrid").tag(true)
                        Text("Standard").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: theMap_ViewModel.isHybrid) { value in
//                        print("Hybrid Picker Called \(value)")
                    }
                    .padding()
//                    // Toggle
//                    Toggle(isOn: $theMap_ViewModel.isHybrid) {
//                        Text("Hybrid")
//                    }.fixedSize()
//                    .onChange(of: theMap_ViewModel.isHybrid) { value in
//                        print("Hybrid Toggle Called \(value)")
//                    }

                    Button(action: orientMap) {
                        let theColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                        let imageString = theMap_ViewModel.getOrientMapImageName()
                        Label("Center Map", systemImage: imageString)
                            .foregroundColor(Color(theColor))
                    } //.font(.largeTitle) .padding()
                        .labelStyle(HorizontalLabelStyle())
                    Spacer()
                }
            }
        } // VStack
        // Detect moving back to foreground
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            theMap_ViewModel.orientMap() // Re-orient map when app moves back to the foreground
            AppInfoEntity.getAppInfoEntity().incrementUsageCount() // Count usage to know when to display the request for a review
        } // navigation view
    } // body
    
    

    private func orientMap() {
        withAnimation {
            Haptic.shared.impact(style: .heavy)
            theMap_ViewModel.orientMap() // Call intent function
        }
    }
    
    private func updateParkingSpot() {
        theMap_ViewModel.requestReview()
        Haptic.shared.impact(style: .heavy)
        withAnimation {
            theMap_ViewModel.updateParkingSpot() // Call intent function
        }
//        // Delay and then orient the map wdhx
//        let DELEAY_IN_SECONDS = 1.0 // Give the map a moment to update the parking spot before orienting
//        DispatchQueue.main.asyncAfter(deadline: .now() + DELEAY_IN_SECONDS) {
//            theMap_ViewModel.orientMap() // Zoom in after updationg the parking spot
//            print("DispatchQueue.main.asyncAfter(deadline: .now() + 1)")
//        }
    }

} // ContentView Struct

// MARK: Custom Label Styles
struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon.font(.headline)
            configuration.title.font(.subheadline)
        }
    }
}
struct HorizontalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title.font(.subheadline)
            configuration.icon.font(.system(size: 24)) // .headline, .largeTitle, .subheadline,
        }
    }
}

// MARK: Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(theMap_ViewModel: Map_ViewModel())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
