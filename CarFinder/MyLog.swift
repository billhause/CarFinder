//
//  MyLog.swift
//  CarFinder
//
//  Created by William Hause on 11/23/21.
//
//  Based on code from Mahmud Ahsan https://thinkdiff.net/swift-how-to-write-a-complete-logger-c538f34cc687
//
// Example:
//  let myArray = ["a","b","c"]
//  MyLog.debug("Button Pressed NOW")
//  MyLog.debug(myArray)
//  MyLog.prettyPrint(myArray)
//
// To Turn On FILE LOGGING hard code the FILE_LOGGING_ENABLED flag to true
//
// TO VIEW THE LOG FILE saved on your phone DO THE FOLLOWING
// - In XCode select window->devices and simulators
// - select your device
// - click on your app (displayed in the 'installed apps' section
// - click the gear icon and select 'download container' and save it
// - RIGHT click on the file and select 'Show Package Contents'
// - Drill down "AppData->Documents->log.txt" and open the file
//


import Foundation


class MyLog {
    static private let NO_LOG = false // Set to true to remove ALL logging via optimizing compiler
    static private let FILE_LOGGING_ENABLED = false // Hard code to True or False to turn on/off
    
    static private var disabledFlag = false // This is changed programatically to turn logging on/off
    static private var textLog = TextLog() // File Logger - Only call this once per app execution
    static func disable() {disabledFlag = true}
    static func enable() {disabledFlag = false}

    
    static func debug(
        _ message: Any, // Anything that can be printed
        fileNm: String = #file, // Default to the filename where the func was called
        funcNm: String = #function, // Default val - The function calling debug
        lineNum: Int = #line // Default val - the line number in the calling file
    ) {
        if NO_LOG || disabledFlag {return}
        let fileName = (fileNm as NSString).lastPathComponent
        
        let outPut = "\(message) \(fileName) Line:\(lineNum)"
        print(outPut) // write to stdio
        if FILE_LOGGING_ENABLED {
            textLog.write("\(outPut)\n") // write to file
        }
    }
    
    // Print objects like arrays or JSON Data
    static func prettyPrint(_ message: Any) {
        if NO_LOG || disabledFlag {return}
        dump(message)
    }
}


// FILE LOGER from Rajat Jain
// https://stackoverflow.com/questions/44537133/how-to-write-application-logs-to-file-and-get-them
//
// TO VIEW THE LOG DO THE FOLLOWING
// - In XCode select window->devices and simulators
// - select your device
// - click on your app (displayed in the 'installed apps' section
// - click the gear icon and select 'download container' and save it
// - RIGHT click on the file and select 'Show Package Contents'
// - Drill down "AppData->Documents->log.txt" and open the file
//
// How to use:
//    var textLog = TextLog() // File Logger - make this a global or static somewhere
//    textLog.write(outPut)
//
struct TextLog: TextOutputStream {
    
    // Delete the previous log file.  Call this when your program starts
    func deleteLogFile() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
        let documentDirectoryPath = paths.first!
        let log = documentDirectoryPath.appendingPathComponent("log.txt")

        do {
            try FileManager.default.removeItem(at: log)
        } catch let error as NSError {
            print("FAILURE: TextLog deleteLogFile() FAILED to delet old log file")
            print("Error: \(error.domain)")
        }
    }
    
    
    // Delete the previous log file when this class is created
    init() {
        deleteLogFile()
    }
    
    /// Appends the given string to the stream.
    func write(_ string: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
        let documentDirectoryPath = paths.first!
        let log = documentDirectoryPath.appendingPathComponent("log.txt")

        do {
            let handle = try FileHandle(forWritingTo: log)
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } catch {
            print(error.localizedDescription)
            do {
                try string.data(using: .utf8)?.write(to: log)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
