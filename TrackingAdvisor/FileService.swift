//
//  FileService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/2/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import Alamofire

class FileService : NSObject {
    static let shared = FileService()
    var dir: URL?
    
    override init() {
        self.dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func getFilePath(for file: String) -> URL? {
        guard let dir = self.dir else { return nil }
        let pathComponent = dir.appendingPathComponent(file)
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            return pathComponent
        }
        return nil
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
    
    func delete(file: String) {
        guard let dir = dir else { return }
        let path = dir.appendingPathComponent(file)
        do {
            try FileManager.default.removeItem(at: path)
        } catch {
            print("Could not delete file: \(path.path)")
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
    
    class func upload(file: URL, callback: @escaping (DataResponse<Any>) -> Void) {
        NSLog("upload file \(file)")
        let id: String = Settings.getUserId() ?? ""
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(file,
                                         withName: "trace",
                                         fileName: "\(id)_\(file.lastPathComponent)",
                                         mimeType: "text/csv")
            },
            to: Constants.urls.locationUploadURL,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        callback(response)
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            })
    }
    
    func log(_ text: String, classname: String) {
        let date = DateHandler.dateToDayString(from: Date())
        let time = DateHandler.dateToHourString(from: Date())
        
        let filename = "log-\(date).log"
        let logText = "\(time) [\(classname)] \(text)\n"
        createOrAppend(logText, in: filename)
        
        NSLog("[\(classname)] \(text)")
    }
    
}
