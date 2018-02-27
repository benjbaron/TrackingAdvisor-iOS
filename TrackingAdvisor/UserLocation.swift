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
    let accuracy: Double
    let targetAccuracy: Double
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
    
    init(id: String, location: CLLocation, targetAccuracy: Double) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        self.userid = id
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = location.speed
        self.accuracy = location.horizontalAccuracy
        self.targetAccuracy = targetAccuracy
    }
    
    func dumps(to file: String, callback: @escaping (Bool) -> Void) {
        // get the last location update
        if let lastLocationUpdate = Settings.getLastLocationUpdate() {
            // get the most likely activity since the last location update
            ActivityService.shared.getActivity(from: lastLocationUpdate, to: self.timestamp) { [weak self] activities in
                guard let strongSelf = self else { return }
                
                let (mostLikelyActivity, activityConfidence) = ActivityService.mostLikelyActivity(activities: activities)
                
                // get the number of steps and the
                ActivityService.shared.getSteps(from: lastLocationUpdate, to: strongSelf.timestamp) { (nbSteps:Int) in
                    
                    let line = "\(strongSelf.userid),\(strongSelf.latitude),\(strongSelf.longitude),\(strongSelf.timestamp.localTime),\(strongSelf.accuracy),\(strongSelf.targetAccuracy),\(strongSelf.speed),\(nbSteps),\(mostLikelyActivity),\(activityConfidence),\(strongSelf.ssid),\(strongSelf.batteryLevel),\(strongSelf.batteryState)\n"
                    let header = "User,Lat,Lon,Timestamp,Accuracy,TargetAccuracy,Speed,nbSteps,activity,activityConfidence,ssid,batteryLevel,batteryCharge\n"
                    
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
    
    class func upload(force: Bool = false, callback: ((DataResponse<Any>) -> Void)?) {
        // See if the data needs to be uploaded to the server
        if let lastFileUpdate = Settings.getLastFileUpdate() {
            if force || (!force && abs(lastFileUpdate.timeIntervalSinceNow) > Constants.variables.minimumDurationBetweenLocationFileUploads) {
                FileService.shared.log("upload file \(Constants.filenames.locationFile) in the background", classname: "UserLocation")
                
                guard let path = FileService.shared.getFilePath(for: Constants.filenames.locationFile) else { return }
                
                let date = Date()
                
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
                            upload.responseJSON { response in
                                FileService.shared.log("response received from server: \(response.result.isSuccess)", classname: "UserLocation")
                                // update the last file update
                                
                                Settings.saveLastFileUpdate(with: date)
                                
                                // delete the file if success
                                if response.result.isSuccess {
                                    FileService.shared.delete(file: path)
                                }
                            }
                        case .failure(let encodingError):
                            FileService.shared.log("failed to send to server", classname: "UserLocation")
                            print(encodingError)
                        }
                })
            }
        }
    }
}
