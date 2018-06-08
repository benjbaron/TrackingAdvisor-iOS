//
//  UserLocation.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/7/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import UIKit
import Sentry

enum BatteryState {
    case unknown
    case charging
    case full
    case unplugged
}

class UserLocation {
    let userid: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let accuracy: CLLocationAccuracy
    let targetAccuracy: CLLocationAccuracy
    let speed: Double
    
    var batteryLevel: Float {
        return UIDevice.current.batteryLevel
    }
    
    var batteryState: BatteryState {
        var state: BatteryState
        switch UIDevice.current.batteryState {
        case .charging:
            state = .charging
        case .full:
            state = .full
        case .unplugged:
            state = .unplugged
        default:
            state = .unknown
        }
        return state
    }
    
    var ssid: String {
        return NetworkService.shared.getSSID() ?? "none"
    }
    
    var lowPower: String {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return "lp"
        }
        return "none"
    }
    
    init(id: String, location: CLLocation, targetAccuracy: CLLocationAccuracy ) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        self.userid = id
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = location.speed
        self.accuracy = location.horizontalAccuracy
        self.targetAccuracy = targetAccuracy
    }
    
    init(id: String, visit: CLVisit, targetAccuracy: CLLocationAccuracy, timestamp: Date) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        self.userid = id
        self.latitude = visit.coordinate.latitude
        self.longitude = visit.coordinate.longitude
        self.timestamp = timestamp
        self.speed = -1
        self.accuracy = visit.horizontalAccuracy
        self.targetAccuracy = targetAccuracy
    }
    
    func dumps(to file: String, callback: @escaping (Bool) -> Void) {
        // get the last location update
        if let lastLocationUpdate = Settings.getLastLocationUpdate() {
            // get the most likely activity since the last location update
            ActivityService.shared.getActivity(from: lastLocationUpdate, to: self.timestamp) { [weak self] activities in
                guard let strongSelf = self else { return }
                
                let (mostLikelyActivity, activityConfidence) = ActivityService.mostLikelyActivity(activities: activities)
                
                // get the number of steps
                ActivityService.shared.getSteps(from: lastLocationUpdate, to: strongSelf.timestamp) { (nbSteps:Int) in
                    
                    let line = "\(strongSelf.userid),\(strongSelf.latitude),\(strongSelf.longitude),\(strongSelf.timestamp.localTime),\(strongSelf.accuracy),\(strongSelf.targetAccuracy),\(strongSelf.speed),\(nbSteps),\(mostLikelyActivity),\(activityConfidence),\(strongSelf.ssid),\(strongSelf.batteryLevel),\(strongSelf.batteryState),\(strongSelf.lowPower)\n"
                    let header = "User,Lat,Lon,Timestamp,Accuracy,TargetAccuracy,Speed,nbSteps,activity,activityConfidence,ssid,batteryLevel,batteryCharge,lowPower\n"
                    
                    if !FileService.shared.fileExists(file: file) {
                        FileService.shared.write(header, in: file)
                    }
                    FileService.shared.append(line, in: file)
                    
                    // update the temporary file
                    if !FileService.shared.fileExists(file: Constants.filenames.locationFile) {
                        FileService.shared.write(header, in: Constants.filenames.locationFile)
                    }
                    FileService.shared.append(line, in: Constants.filenames.locationFile)
                    Settings.saveLastLocationUpdate(with: strongSelf.timestamp)
                    
                    callback(true)
                }
            }
        }
    }
    
    class func uploadLocationFile(callback: (() -> Void)? = nil) {
        guard let path = FileService.shared.getFilePath(for: Constants.filenames.locationFile) else { return }
        
        let date = Date()
        
        print("send the location file")
        Networking.shared.backgroundSessionManager.upload(
            multipartFormData: { multipartFormData in
                let id: String = Settings.getUserId() ?? ""
                let day = DateHandler.dateToDayString(from: date)
                let time = DateHandler.dateToHourString(from: date)
                let filename = "\(id)_\(day)_\(time).csv"
                multipartFormData.append(path,
                                         withName: "trace",
                                         fileName: filename,
                                         mimeType: "text/csv")
        },
            to: Constants.urls.locationUploadURL,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.uploadProgress { progress in
                        print("Progress: \(progress.fractionCompleted)")
                        }.responseJSON { response in
                            LogService.shared.log(LogService.types.serverResponse,
                                                  args: [LogService.args.responseMethod: "post",
                                                         LogService.args.responseUrl: Constants.urls.locationUploadURL,
                                                         LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                            
                            // delete the file if success
                            switch (response.result) {
                            case .success(_):
                                Settings.saveLastFileUpdate(with: date)
                                FileService.shared.delete(file: path)
                                callback?()
                                
                            case .failure(let error):
                                if let error = error as? AFError {
                                    let msg = "Error when sending the location update to the server [2]"
                                    let event = Event(level: .error)
                                    event.message = msg
                                    event.extra = ["error": "\(error.errorDescription)",
                                                   "function": "UserLocation.uploadLocationFile"]
                                    Client.shared?.send(event: event)
                                }
                            }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
        })
    }
    
    class func upload(force: Bool = false, callback: (() -> Void)? = nil) {
        // See if the data needs to be uploaded to the server
        
        let force = Settings.getForceUploadLocation() || force
        if let lastFileUpdate = Settings.getLastFileUpdate() {
            if force || (!force && abs(lastFileUpdate.timeIntervalSinceNow) > Constants.variables.minimumDurationBetweenLocationFileUploads) {
                LogService.shared.log(LogService.types.serverRequest,
                                      args: [LogService.args.requestMethod: "post",
                                             LogService.args.requestUrl: Constants.urls.locationUploadURL])
                
                guard let path = FileService.shared.getFilePath(for: Constants.filenames.locationFile),
                      let logPath = FileService.shared.getFilePath(for: Constants.filenames.logFile) else { return }
                
                let date = Date()
                Networking.shared.backgroundSessionManager.upload(
                    multipartFormData: { multipartFormData in
                        let id: String = Settings.getUserId() ?? ""
                        let day = DateHandler.dateToDayString(from: date)
                        let time = DateHandler.dateToHourString(from: date)
                        let filename = "\(id)_\(day)_\(time).csv"
                        let logFilename = "\(id)_\(day)_\(time)_log.csv"
                        multipartFormData.append(path,
                                                 withName: "trace",
                                                 fileName: filename,
                                                 mimeType: "text/csv")
                        multipartFormData.append(logPath,
                                                 withName: "log",
                                                 fileName: logFilename,
                                                 mimeType: "text/csv")
                    },
                    to: Constants.urls.locationUploadURL,
                    encodingCompletion: { encodingResult in
                        switch encodingResult {
                        case .success(let upload, _, _):
                            upload.uploadProgress { progress in
                                print("Progress: \(progress.fractionCompleted)")
                            }.responseJSON { response in
                                LogService.shared.log(LogService.types.serverResponse,
                                                      args: [LogService.args.responseMethod: "post",
                                                             LogService.args.responseUrl: Constants.urls.locationUploadURL,
                                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                                
                                // delete the file if success
                                switch (response.result) {
                                case .success(_):
                                    Settings.saveLastFileUpdate(with: date)
                                    FileService.shared.delete(file: path)
                                    FileService.shared.delete(file: logPath)
                                    callback?()
                                    
                                case .failure(let error):
                                    var errorStr = "Error\n"
                                    // getting more information about the error
                                    // https://github.com/Alamofire/Alamofire/blob/master/Documentation/Alamofire%204.0%20Migration%20Guide.md#errors
                                    if let error = error as? AFError {
                                        switch error {
                                        case .invalidURL(let url):
                                            errorStr += "Invalid URL: \(url) - \(error.localizedDescription)\n"
                                        case .parameterEncodingFailed(let reason):
                                            errorStr += "Parameter encoding failed: \(error.localizedDescription)\n"
                                            errorStr += "Failure Reason: \(reason)\n"
                                        case .multipartEncodingFailed(let reason):
                                            errorStr += "Multipart encoding failed: \(error.localizedDescription)\n"
                                            errorStr += "Failure Reason: \(reason)\n"
                                        case .responseValidationFailed(let reason):
                                            errorStr += "Response validation failed: \(error.localizedDescription)\n"
                                            errorStr += "Failure Reason: \(reason)\n"
                                            
                                            switch reason {
                                            case .dataFileNil, .dataFileReadFailed:
                                                errorStr += "Downloaded file could not be read\n"
                                            case .missingContentType(let acceptableContentTypes):
                                                errorStr += "Content Type Missing: \(acceptableContentTypes)\n"
                                            case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                                                errorStr += "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)\n"
                                            case .unacceptableStatusCode(let code):
                                                errorStr += "Response status code was unacceptable: \(code)\n"
                                            }
                                        case .responseSerializationFailed(let reason):
                                            errorStr += "Response serialization failed: \(error.localizedDescription)\n"
                                            errorStr += "Failure Reason: \(reason)\n"
                                        }
                                        
                                    } else if let error = error as? URLError {
                                        errorStr += "URLError occurred: \(error)\n"
                                    } else {
                                        errorStr += "Unknown error: \(error)\n"
                                    }
                                    
                                    let msg = "Error when sending the location update to the server [1]"
                                    let event = Event(level: .error)
                                    event.message = msg
                                    event.extra = ["error": errorStr, "function": "UserLocation.upload"]
                                    Client.shared?.send(event: event)
                                    
                                    // try again, just with the location file
                                    uploadLocationFile {
                                        // delete the log path
                                        FileService.shared.delete(file: logPath)
                                        
                                        callback?()
                                    }
                                }
                            }
                        case .failure(let encodingError):
                            print(encodingError)
                        }
                })
            }
        }
    }
}
