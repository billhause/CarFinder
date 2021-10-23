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
    
    var body: some View {
        NavigationView {
            VStack {
                MapView(theMap_ViewModel: theMap_ViewModel)
                HStack {
                    Button("Orient Map") {
                        print("Orient Map Pressed")
                    } .padding()
                    
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
                    Button(action: orientMap) {
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
    
    private func orientMap() {
        withAnimation {
            print("ContentView.orientMap() called wdh")
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
