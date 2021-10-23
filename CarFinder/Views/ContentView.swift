//
//  ContentView.swift
//  CarFinder
//
//  Created by William Hause on 10/16/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject var theMap_ViewModel: Map_ViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
//Fix the gap at the top of the map or get the orient map button working
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                MapView(theMap_ViewModel: theMap_ViewModel)
            }
            .navigationBarTitle("Car Locator", displayMode: .inline) // inline moves the title to the same line as the buttons
            .navigationBarHidden(false)

            .toolbar {
                
                ToolbarItem(placement: ToolbarItemPlacement.automatic) { // Top Toolbar
                    Button(action: updateParkingSpot) {
                        let theColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
                        let imageString = theMap_ViewModel.getParkingLocationImageName()
                        Label("Update Spot", systemImage: imageString)
                            .foregroundColor(Color(theColor))
                            .padding() // Move the Parking symbol away from right border a little bit
                    } .font(.largeTitle)
                }
                
                // Bottom Toolbar
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: orientMap) {
                        let theColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
                        let imageString = theMap_ViewModel.getOrientMapImageName()
                        Label("", systemImage: imageString)
                            .foregroundColor(Color(theColor))
                    } //.font(.largeTitle)
                    Spacer()
                    
                    // USE EITHER A PICKER or a TOGGLE below comment one out
                    // Picker
                    Picker("What kind of map do you want", selection: $theMap_ViewModel.isHybrid) {
                        Text("Hybrid").tag(true)
                        Text("Standard").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: theMap_ViewModel.isHybrid) { value in
                        print("Hybrid Picker Called \(value)")
                    }
//                    // Toggle
//                    Toggle(isOn: $theMap_ViewModel.isHybrid) {
//                        Text("Hybrid")
//                    }.fixedSize()
//                    .onChange(of: theMap_ViewModel.isHybrid) { value in
//                        print("Hybrid Toggle Called \(value)")
//                    }
                }
            }

        }
    }
    
    private func orientMap() {
        print("orientMap() called")
    }
    
    private func updateParkingSpot() {
        withAnimation {
            print("ContentView.updateParkingSpot() called wdh")
        }
    }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(theMap_ViewModel: Map_ViewModel())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
//        ContentView(theMap_ViewModel: Map_ViewModel())
//            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
