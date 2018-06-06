//
//  Pedometer.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/9/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreMotion

enum ActivityType {
    case automotive
    case cycling
    case running
    case stationary
    case unknown
    case walking
}

struct PedometerData : Codable {
    let start: Date
    let end: Date
    let numberOfSteps: Int
    let distance: Double
    let day: String
}

class ActivityService {
    static let shared = ActivityService()
    
    var pedometer = CMPedometer()
    var activityManager = CMMotionActivityManager()
    
    class func isServiceActivated() -> Bool {
        if #available(iOS 11.0, *) {
            return CMPedometer.authorizationStatus() == .authorized
        } else {
            // Fallback on earlier versions
            return CMSensorRecorder.isAuthorizedForRecording()
        }
    }
    
    func getSteps(from start: Date, to end: Date, callback: @escaping (Int) -> Void) {
        pedometer.queryPedometerData(from: start, to: end) {
            (pedometerData, error) in
            if let data = pedometerData {
                callback(Int(truncating: data.numberOfSteps))
            } else {
                callback(-1)
            }
        }
    }
    
    func getAllSteps(from start: Date, to end: Date, interval: TimeInterval, callback: @escaping ([PedometerData]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var res:[PedometerData] = []
            let group = DispatchGroup()
            
            let numberOfIntervals = Int(ceil(end.timeIntervalSince(start) / interval))
            for i in 0..<numberOfIntervals {
                let from = start.addingTimeInterval(Double(i) * interval)
                let to = start.addingTimeInterval(Double(i+1) * interval)
                group.enter()
                self.pedometer.queryPedometerData(from: from, to: to) { (data, error) in
                    if let data = data {
                        let numberOfSteps = Int(truncating: data.numberOfSteps)
                        let pd = PedometerData(start: from,
                                               end: to,
                                               numberOfSteps: numberOfSteps,
                                               distance: data.distance as! Double,
                                               day: DateHandler.dateToDayString(from: to))
                        res.append(pd)
                        group.leave()
                    }
                }
            }
            group.wait()
            
            DispatchQueue.main.sync {
                callback(res)
            }
        }
    }
    
    
    func getActivity(from start: Date, to end: Date, callback: @escaping ([ActivityType:Int]?) -> Void) {
        activityManager.queryActivityStarting(from: start, to: end, to: OperationQueue.main) {
            (arr, err) -> Void in
            if let activities = arr {
                callback(self.activitiesToDict(activities))
            } else {
                callback(nil)
            }
        }
    }
    
    func hasUserMoved(interval: TimeInterval, callback: @escaping (Bool) -> Void) {
        let end = Date()
        let start = end.addingTimeInterval(interval)
        
        getSteps(from: start, to: end) { nbSteps in
            if nbSteps > 50 {
                self.getActivity(from: start, to: end) { arr in
                    guard let activities = arr else {
                        callback(false)
                        return
                    }
                    let (activity, _) = ActivityService.mostLikelyActivity(activities: activities)
                    if activity != .stationary {
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            } else {
                callback(false)
            }
        }
    }
    
    func getType(of activity: CMMotionActivity) -> ActivityType {
        if(activity.automotive) { return .automotive }
        if(activity.cycling)    { return .cycling }
        if(activity.running)    { return .running }
        if(activity.stationary) { return .stationary }
        if(activity.unknown)    { return .unknown }
        if(activity.walking)    { return .walking }
        return .unknown
    }
    
    func hasActivityType(activity: CMMotionActivity, type: ActivityType) -> Bool {
        switch type {
        case .automotive:
            return activity.automotive
        case .cycling:
            return activity.cycling
        case .running:
            return activity.running
        case .stationary:
            return activity.stationary
        case .unknown:
            return activity.unknown
        case .walking:
            return activity.walking
        }
    }
    
    func confidenceToInt(_ confidence: CMMotionActivityConfidence) -> Int {
        var confidenceMult = 0
        
        switch(confidence) {
        case .high:
            confidenceMult = 100
        case .medium:
            confidenceMult = 50
        case .low:
            confidenceMult = 0
        }
        
        return confidenceMult
    }
    
    func activityConfidence(_ detectedActivity: Bool, _ multiplier: Int) -> Int {
        return (detectedActivity ? 1 : 0) * multiplier;
    }
    
    func activitiesToDict(_ activities: [CMMotionActivity]) -> [ActivityType:Int] {
        var res = [
            ActivityType.unknown :   0,
            ActivityType.automotive: 0,
            ActivityType.stationary: 0,
            ActivityType.walking:    0,
            ActivityType.running:    0,
            ActivityType.cycling:    0
        ]
        
        for activity in activities {
            let confidenceMult = confidenceToInt(activity.confidence)
            for (k,v) in res {
                res[k] = v + activityConfidence(hasActivityType(activity: activity, type: k), confidenceMult)
            }
        }
        return res
    }
    
    class func mostLikelyActivity(activities: [ActivityType:Int]?) -> (ActivityType,Int) {
        guard let act = activities, act.count > 0 else {
            return (ActivityType.unknown, -1)
        }
        var bestActivity = ActivityType.unknown
        var bestConfidence = 0
        for (activity, confidence) in act {
            if confidence > bestConfidence {
                bestActivity = activity
                bestConfidence = confidence
            }
        }
        return (bestActivity, bestConfidence)
    }
    
    
}
