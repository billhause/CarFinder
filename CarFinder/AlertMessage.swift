//
//  AlertMessage.swift
//  CarFinder
//
//  Created by William Hause on 11/4/21.
//

import Foundation

// Example Call:
//   AlertDialog.shared.Alert("This is the message to display with an OK button")
//
// NOTE: The ContentView must have a view that is setup to show an alert message like this:
//   @ObservedObject var theAlert = AlertDialog.shared
// AND a View (like a Spacer) with a .alert property
//if #available(iOS 15.0, *) {
//    Spacer()
//        .alert(theAlert.theMessage, isPresented: $theAlert.showAlert) {
//            Button("OK", role: .cancel) { }
//        }
//} else {
//    // Fallback on earlier versions
//    Spacer()
//}


class AlertDialog: ObservableObject {
    static var shared = AlertDialog()
    
    // To show an alert, set theMessage and set the showAlert bool to true
    var theMessage = "Confirm"
    var showAlert = false
    
    func Alert(_ message: String) {
        theMessage = message
        showAlert = true
    }
    
}
