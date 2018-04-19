//
//  LocationActivityService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/9/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

protocol LocationAdaptiveUpdateProtocol {
    func locationDidUpdate(location: UserLocation)
}

class LocationAdaptiveService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationAdaptiveService()
    var delegate: LocationAdaptiveUpdateProtocol!
    
    let locationManager = CLLocationManager()
    let activityService = ActivityService.shared
    
    var currentLocation:UserLocation? = nil
    var locations:[CLLocation] = []
    
    var accuracy = kCLLocationAccuracyNearestTenMeters
    var distanceFilter = kCLDistanceFilterNone
    
    var timer = Timer()
    var delayTimer = Timer()
    var activityTimeout = (Double)(60)
    var timeout = (Double)(2*60)
    var minTimeout = (Double)(2*60)
    var maxTimeout = (Double)(30*60)
    
    var updating = false
    var isStationary = false
    var id: String = Settings.getUserId() ?? ""
    var bgTask = UIBackgroundTaskInvalid
    
    override init() {
        super.init()
    }
    
    @objc func startMonitoringLocation() {
        startUpdatingLocation()
        checkIfUserHasMoved()
    }
    
    @objc func checkIfUserHasMoved() {
        // Check whether the user has moved in the past X minutes
        ActivityService.shared.hasUserMoved(interval: timeout) { hasMoved in
            if hasMoved {
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
        
        LogService.shared.log(LogService.types.locationAdaptiveStart)
        
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
        stopUpdatingLocation()
        startUpdatingLocation()
        LogService.shared.log(LogService.types.locationAdaptiveRestart)
    }
    
    func stopUpdatingLocation() {
        bgTask = UIBackgroundTaskInvalid
        timer.invalidate()
        locationManager.stopUpdatingLocation()
        updating = false
        LogService.shared.log(LogService.types.locationAdaptiveStop)
    }
    
    @objc func stopUpdatingLocationAfterXSeconds() {
        DispatchQueue.global(qos: .background).async {
            if self.locations.count == 0 { return }
            
            var bestLocation:CLLocation?
            var bestAccuracy = 3000.0
            
            for loc in self.locations {
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
            
            if let previousLocation = Settings.getLastKnownLocation() {
                let distanceMoved = previousLocation.distance(from: newLocation)
                if distanceMoved > 25 {
                    self.isStationary = false
                } else {
                    self.isStationary = true
                }
            }
            
            Settings.saveLastKnownLocation(with: newLocation)
            let loc = UserLocation(id: self.id, location: newLocation, targetAccuracy: self.locationManager.desiredAccuracy)
            self.currentLocation = loc
            
            let filename = DateHandler.dateToDayString(from: loc.timestamp) + ".csv"
            loc.dumps(to: filename) { [weak self] done in
                print("dumped \(loc) in \(filename)")
                guard let strongSelf = self else { return }
                if done {
                    // upload to server
                    UserLocation.upload {
                        // stop forcing location file upload
                        if Settings.getForceUploadLocation() {
                            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                                UserUpdateHandler.retrieveLatestUserUpdates(for: DateHandler.dateToDayString(from: Date()))
                            }
                            Settings.saveForceUploadLocation(with: false)
                        }
                    }
                    
                    DispatchQueue.main.async { () -> Void in
                        if strongSelf.delegate != nil {
                            strongSelf.delegate.locationDidUpdate(location: loc)
                        }
                    }
                    
                    strongSelf.locations.removeAll()
                    strongSelf.locationManager.stopUpdatingLocation()
                    strongSelf.updating = false
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        })
        
        if !updating {
            return
        }
        
        let location = locations.last!
        let timeSinceUpdate = location.timestamp.timeIntervalSinceNow as Double
        if location.horizontalAccuracy < 0 || abs(timeSinceUpdate) > 2.0 {
            return  // continue polling the location (get the next one)
        }
        
        self.locations.append(location)
        
        // if the timer is still valid, the code below is not executed
        if timer.isValid { return }
                        
        // Restart the locationManager after "timeout" seconds
        timer = Timer.scheduledTimer(timeInterval: timeout,
                                     target: self,
                                     selector: #selector(timeoutLocationMonitoring),
                                     userInfo: nil,
                                     repeats: false)
        
        // Will only stop the locationManager after 0.5 seconds, so that we can get some accurate locations
        // The location manager will only operate for 0.5 seconds to save battery
        delayTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                          target: self,
                                          selector: #selector(timeoutLocationUpdate),
                                          userInfo: nil,
                                          repeats: false)
    }
    
    @objc func timeoutLocationMonitoring() {
        restartUpdatingLocation()
    }
    
    @objc func timeoutLocationUpdate() {
        stopUpdatingLocationAfterXSeconds()
    }
    
}
