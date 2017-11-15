//
//  FileService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/2/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import Alamofire

class Networking {
    static let shared = Networking()
    public var sessionManager: Alamofire.SessionManager // most of your web service clients will call through sessionManager
    public var backgroundSessionManager: Alamofire.SessionManager // your web services you intend to keep running when the system backgrounds your app will use this
    private init() {
        self.sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        self.backgroundSessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.background(withIdentifier: "com.trackingadvisor.backgroundtransfer"))
    }
}

class FileService : NSObject {
    static let shared = FileService()
    var dir: URL?
    
    override init() {
        self.dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func listFiles() -> [URL] {
        guard let dir = dir else { return [] }
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
            return directoryContents
        } catch {
            print(error.localizedDescription)
        }
        
        return []
    }
    
    func delete(file: URL) {
        do {
            try FileManager.default.removeItem(at: file)
        } catch {
            print("Could not delete file: \(file.path)")
        }
    }
    
    func read(from file: URL) -> String {
        do {
            let text = try String(contentsOf: file, encoding: .utf8)
            return text
        } catch {
            NSLog("Error when reading file \(file)")
        }
        return ""
    }
    
    func fileExists(file: String) -> Bool {
        guard let dir = dir else { return false }
        let path = dir.appendingPathComponent(file).path
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path)
    }
    
    func createOrAppend(_ string: String, in file: String) {
        if fileExists(file: file) {
            append(string, in: file)
        } else {
            write(string, in: file)
        }
    }
    
    func append(_ string: String, in file: String) {
        guard let dir = dir else { return }
        let path = dir.appendingPathComponent(file)
        let fileHandle = FileHandle(forUpdatingAtPath: path.path)
        if let fileHandle = fileHandle {
            fileHandle.seekToEndOfFile()
            fileHandle.write(string.data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            NSLog("could not write in file \(file)")
        }
    }
    
    func write(_ string: String, in file: String) {
        guard let dir = dir else { return }
        let path = dir.appendingPathComponent(file)
        do {
            try string.write(to: path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            NSLog("could not write in file \(file)")
        }
    }
    
    func recordLocations(_ locations: [UserLocation], in file: String) {
        if fileExists(file: file) {
            var text = ""
            for loc in locations {
                let line = "\(loc.userID),\(loc.latitude),\(loc.longitude),\(loc.timestamp),\(loc.accuracy),\(loc.targetAccuracy),\(loc.speed)\n"
                text.append(line)
            }
            append(text, in: file)
        } else  {
            var text = "User,Lat,Lon,Timestamp,Accuracy,TargetAccuracy,Speed\n"
            for loc in locations {
                let line = "\(loc.userID),\(loc.latitude),\(loc.longitude),\(loc.timestamp),\(loc.accuracy),\(loc.targetAccuracy),\(loc.speed)\n"
                text.append(line)
            }
            write(text, in: file)
        }
    }
    
    func upload(file: URL) {
        Networking.shared.backgroundSessionManager.upload(file,
                                                          to: "https://tracemap.herokuapp.com/upload").responseJSON { 
                                                            response in
            debugPrint(response)
        }
    }
    
    func log(_ text: String, classname: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "log-" + formatter.string(from: date) + ".log"
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: date)
        
        let logText = "\(time) [\(classname)] \(text)\n"
        createOrAppend(logText, in: filename)
        
        NSLog("[\(classname)] \(text)")
    }
    
}
