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

//    Add 'Orient Map' button to center on current CLLocation
//    Add 'Update Spot' button to move the parking spot to the current location
    
    var body: some View {
        NavigationView {
            VStack {
                MapView(theMap_ViewModel: theMap_ViewModel)
                HStack {
                    Spacer()
                    Button("Orient Map") {
                        print("Orient Map Pressed")
                    }
                    Spacer()
                    Toggle("Hybrid", isOn: $theMap_ViewModel.isHybrid)
                        .onChange(of: theMap_ViewModel.isHybrid) { value in
                            print("Hybrid Button Toggled to \(value)")
                        }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem {
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
                    Button(action: addItem) {
                        let theColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
//                        Label("Update Spot", systemImage: "car")
                        Label("Update Spot", systemImage: "parkingsign.circle")
                            .foregroundColor(Color(theColor))
                            .padding() // Move the Parking symbol away from right border a little bit
                    }
                }
            }

        }
    }

    
    
    
    private func addItem() {
        withAnimation {
            print("addItem() called wdh")
        }
    }

}

//private let itemFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    formatter.timeStyle = .medium
//    return formatter
//}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(theMap_ViewModel: Map_ViewModel())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
//        ContentView(theMap_ViewModel: Map_ViewModel())
//            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
