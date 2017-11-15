//
//  ActivityService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/2/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreMotion

protocol ActivityOldUpdateProtocol {
    func activityDidUpdate(activities: [String:Int])
}

class ActivityServiceOld: NSObject {
    static let shared = ActivityServiceOld()
    
    var activityFrequency = (Double)(60)
    var activityTimeout = (Double)(10)
    var activityTimer = Timer()
    var stopActivityTimer = Timer()
    
    var manager: CMMotionActivityManager?
    var delegate: ActivityOldUpdateProtocol!
    var available = false
    var updating = false
    
    var isStationary = false
    var activities:[[String:Int]] = [[:]]
    
    override init() {
        super.init()
        
        if(CMMotionActivityManager.isActivityAvailable()) {
            NSLog("Activity Manager is available")
            self.manager = CMMotionActivityManager()
            self.available = true
        } else {
            NSLog("Activity Manager is not available")
        }
    }
    
    func mostLikelyActivity(activities: [String:Int]) -> (String,Int) {
        if activities.count == 0 { return ("unknown",0) }
        var bestActivity = "unknown"
        var bestConfidence = 0
        for (activity, confidence) in activities {
            if confidence > bestConfidence {
                bestActivity = activity
                bestConfidence = confidence
            }
        }
        return (bestActivity, bestConfidence)
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
    
    func activityToString(_ activity: CMMotionActivity) -> String {
        if(activity.automotive) { return "automotive" }
        if(activity.cycling)    { return "cycling" }
        if(activity.running)    { return "running" }
        if(activity.stationary) { return "stationary" }
        if(activity.unknown)    { return "unknown" }
        if(activity.walking)    { return "walking" }
        return "unknown"
    }
    
    func activitiesToDict(_ activity: CMMotionActivity) -> [String:Int] {
        let confidenceMult = confidenceToInt(activity.confidence)
        let activities = [
            "unknown":    activityConfidence(activity.unknown, confidenceMult),
            "automotive": activityConfidence(activity.automotive, confidenceMult),
            "stationary": activityConfidence(activity.stationary, confidenceMult),
            "walking":    activityConfidence(activity.walking, confidenceMult),
            "running":    activityConfidence(activity.running, confidenceMult),
            "cycling":    activityConfidence(activity.cycling, confidenceMult)
        ]
        NSLog("activities: \(activities)")
        return activities
    }
    
    @objc func startMonitoringActivity() {
        if !self.available {
            NSLog("Activity service is not available on the device")
            return
        }
        
        guard let manager = self.manager else { return }
        
        FileService.shared.log("Start monitoring activity", classname: "ActivityService")
        self.updating = true
        manager.startActivityUpdates(to: OperationQueue()) { data in
            guard let activity = data else { return }
            DispatchQueue.main.async {
                self.isStationary = activity.stationary
                self.activities.append(self.activitiesToDict(activity))
                FileService.shared.log("Received Activity Update: \(activity)", classname: "ActivityService")
            }
        }
        
        activityTimer = Timer.scheduledTimer(timeInterval: activityFrequency,
                                             target: self,
                                             selector: #selector(ActivityServiceOld.startMonitoringActivity),
                                             userInfo: nil,
                                             repeats: false)
        
        stopActivityTimer.invalidate()
        stopActivityTimer = Timer.scheduledTimer(timeInterval: activityTimeout,
                                               target: self,
                                               selector: #selector(ActivityServiceOld.syncAfterXSeconds),
                                               userInfo: nil,
                                               repeats: false)
    }
    
    @objc func syncAfterXSeconds() {
        NSLog("syncAfterXSeconds called")
        FileService.shared.log("Number of activites recorded: \(activities.count)", classname: "ActivityService")
        if self.delegate != nil {
            self.delegate.activityDidUpdate(activities: self.activities.first!)
        }
        stopMonitoringActivity()
    }
    
    func stopMonitoringActivity() {
        if self.available && self.updating {
            self.updating = false
            self.manager?.stopActivityUpdates()
            self.activities = [[:]]
        }
    }
}

