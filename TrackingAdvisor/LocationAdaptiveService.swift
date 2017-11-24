//
//  LocationActivityService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/9/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationAdaptiveUpdateProtocol {
    func locationDidUpdate(location: UserLocation)
}

class LocationAdaptiveService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationAdaptiveService()
    var delegate:LocationAdaptiveUpdateProtocol!
    
    let locationManager = CLLocationManager()
    let activityService = ActivityService.shared
    
    var currentLocation:UserLocation? = nil
    var locations:[CLLocation] = []
    
    var accuracy = kCLLocationAccuracyBestForNavigation
    var distanceFilter = kCLDistanceFilterNone
    
    var timer = Timer()
    var delayTimer = Timer()
    var activityTimeout = (Double)(60)
    var timeout = (Double)(2*60)
    var minTimeout = (Double)(2*60)
    var maxTimeout = (Double)(30*60)
    
    var updating = false
    var isStationary = false
    var id: String = UIDevice.current.identifierForVendor!.uuidString
    var bgTask = UIBackgroundTaskInvalid
    
    override init() {
        super.init()
    }
    
    @objc func startMonitoringLocation() {
        FileService.shared.log("Start location monitoring", classname: "LocationAdaptiveService")
        startUpdatingLocation()
        checkIfUserHasMoved()
    }
    
    @objc func checkIfUserHasMoved() {
        // Check whether the user has moved in the past X minutes
        FileService.shared.log("Check if user has moved", classname: "LocationAdaptiveService")
        ActivityService.shared.hasUserMoved(interval: timeout) { hasMoved in
            if hasMoved {
                FileService.shared.log("User has moved in the past \(Int(self.timeout)) minutes",
                    classname: "LocationAdaptiveService")
                self.accuracy = kCLLocationAccuracyBest
                self.distanceFilter = kCLDistanceFilterNone
                self.timeout = self.minTimeout
                self.isStationary = false
                self.startUpdatingLocation()
            } else {
                self.isStationary = true
            }
        }
    }
    
    func startUpdatingLocation() {
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        })
        
        FileService.shared.log("Start updating location", classname: "LocationAdaptiveService")
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = accuracy
        locationManager.distanceFilter = distanceFilter
        
        locationManager.startUpdatingLocation()
        updating = true
    }
    
    @objc func restartUpdatingLocation() {
        FileService.shared.log("Restart updating location", classname: "LocationAdaptiveService")
        stopUpdatingLocation()
        startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        bgTask = UIBackgroundTaskInvalid
        timer.invalidate()
        locationManager.stopUpdatingLocation()
        updating = false
    }
    
    @objc func stopUpdatingLocationAfterXSeconds() {
        if locations.count == 0 { return }
        
        FileService.shared.log("stopUpdatingLocationAfterXSeconds", classname: "LocationAdaptiveService")
        var bestLocation:CLLocation?
        var bestAccuracy = 3000.0
        
        for loc in locations {
            if(bestLocation == nil) {
                bestAccuracy = loc.horizontalAccuracy;
                bestLocation = loc;
            } else if(loc.horizontalAccuracy < bestAccuracy) {
                bestAccuracy = loc.horizontalAccuracy;
                bestLocation = loc;
            } else if (loc.horizontalAccuracy == bestAccuracy) &&
                (loc.timestamp.compare(bestLocation!.timestamp) == ComparisonResult.orderedDescending) {
                bestAccuracy = loc.horizontalAccuracy;
                bestLocation = loc;
            }
        }
        
        guard let newLocation = bestLocation else { return }
        
        if let cur = currentLocation {
            let previousLocation = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
            let distanceMoved = previousLocation.distance(from: newLocation)
            FileService.shared.log("Distance moved: \(distanceMoved), prev: \(previousLocation), new: \(newLocation)", classname: "LocationAdaptiveService")
            if distanceMoved > 25 {
                self.isStationary = false
            } else {
                self.isStationary = true
            }
        }
        
        let loc = UserLocation(id: self.id, location: newLocation, targetAccuracy: locationManager.desiredAccuracy)
        self.currentLocation = loc
        
        let filename = loc.dateString() + ".csv"
        FileService.shared.recordLocations([loc], in: filename)
        FileService.shared.log("added location to \(filename)", classname: "LocationAdaptiveService")
        
        DispatchQueue.main.async { () -> Void in
            NSLog("call delegate method for location handler")
            if self.delegate != nil {
                self.delegate.locationDidUpdate(location: loc)
            }
        }
        
        locations.removeAll()
        locationManager.stopUpdatingLocation()
        updating = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        })
        
        FileService.shared.log("didUpdateLocations, updating: \(updating), timer: \(timer.isValid)", classname: "LocationAdaptiveService")
        if !updating {
            return
        }
        
        FileService.shared.log("didUpdateLocations -- 1", classname: "LocationAdaptiveService")
        
        let location = locations.last!
        let timeSinceUpdate = location.timestamp.timeIntervalSinceNow as Double
        if location.horizontalAccuracy < 0 || abs(timeSinceUpdate) > 2.0 {
            FileService.shared.log("didUpdateLocations -- 1a", classname: "LocationAdaptiveService")
            return  // continue polling the location (get the next one)
        }
        
        FileService.shared.log("didUpdateLocations -- 2", classname: "LocationAdaptiveService")
        
        self.locations.append(location)
        
        // if the timer is still valid, the code below is not executed
        if timer.isValid { return }
        
        FileService.shared.log("didUpdateLocations -- 3", classname: "LocationAdaptiveService")
        
        // determine the new timeout
//        if self.isStationary {
//            self.timeout = min(self.timeout+self.minTimeout, self.maxTimeout)
//            self.accuracy = kCLLocationAccuracyThreeKilometers
//        }
        
        FileService.shared.log("Next location update in \(timeout) seconds", classname: "LocationAdaptiveService")
        // Restart the locationManager after "timeout" seconds
        timer = Timer.scheduledTimer(timeInterval: timeout,
                                     target: self,
                                     selector: #selector(LocationAdaptiveService.restartUpdatingLocation),
                                     userInfo: nil,
                                     repeats: false)
        
        // Will only stop the locationManager after 1 seconds, so that we can get some accurate locations
        // The location manager will only operate for 1 seconds to save battery
        delayTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                          target: self,
                                          selector: #selector(LocationAdaptiveService.stopUpdatingLocationAfterXSeconds),
                                          userInfo: nil,
                                          repeats: false)
    }
}