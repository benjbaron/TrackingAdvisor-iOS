//
//  LocationManager.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 10/31/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//
// From
// https://stackoverflow.com/questions/41524922/how-to-get-periodicaly-new-location-when-app-is-in-background-or-killed
// https://github.com/pmwisdom/cordova-background-geolocation-services/blob/master/src/ios/CDVBackgroundLocationServices.swift
//

import Foundation
import CoreLocation
import CoreMotion
import CoreData
import UIKit

protocol LocationUpdateProtocol {
    func locationDidUpdate(location: UserLocation)
}

class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    var delegate:LocationUpdateProtocol!
    
    var locationManager:CLLocationManager?
    var dataService:DataStoreService?
//    var motionManager: CMMotionManager?
//    var activityService: ActivityService?

    
    var stationaryTimeout = (Double)(5 * 60)
    var standardTimeout = (Double)(10)
    var syncSeconds:TimeInterval = 1
    var timer = Timer()
    var stopUpdateTimer = Timer()
    var bgTask = UIBackgroundTaskInvalid

    var lowPower = false
    var enabled = false
    var background = false
    var updating = false

    var locations:[UserLocation] = []
    let id: String = Settings.getUserId() ?? ""
    
    let uclCoords = CLLocationCoordinate2D(latitude: 51.524657746824921, longitude: -0.13423115015042408)
    let homeCoords = CLLocationCoordinate2D(latitude: 51.513596047066898, longitude: -0.093435771182253588)
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(LocationService.onResume),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil);
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(LocationService.onSuspend),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil);
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(LocationService.willResign),
            name: NSNotification.Name.UIApplicationWillResignActive,
            object: nil);
        
        self.locationManager = CLLocationManager()
        self.dataService = DataStoreService()
//        self.motionManager = CMMotionManager()
//        self.activityService = ActivityService.shared

        
        guard let locationManager = self.locationManager else {
            return
        }
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        // configure the activity manager
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .fitness
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        locationManager.delegate = self
    }
    
    func sync() {
        NSLog("sync() called")
        var bestLocation: UserLocation?
        var bestAccuracy = 3000.0
        
        if locations.count == 0 {
            NSLog("no locations recorded")
            return
        }
        
        for loc in locations {
            if bestLocation == nil {
                bestAccuracy = loc.accuracy
                bestLocation = loc
            } else if loc.accuracy < bestAccuracy {
                bestAccuracy = loc.accuracy
                bestLocation = loc
            } else if (loc.accuracy == bestAccuracy) &&
                (loc.timestamp.compare(bestLocation!.timestamp) == ComparisonResult.orderedDescending) {
                bestAccuracy = loc.accuracy
                bestLocation = loc
            }
        }
        
        if let bestLocation = bestLocation {
            NSLog("bestLocation: {\(bestLocation)}")
            DispatchQueue.main.async { () -> Void in
                NSLog("call delegate method for location handler")
                if self.delegate != nil {
                    self.delegate.locationDidUpdate(location: bestLocation)
                }
            }
            let filename = DateHandler.dateToDayString(from: bestLocation.timestamp) + ".csv"
            
            bestLocation.dumps(to: filename) { [weak self] done in
                guard let strongSelf = self else { return }
                if done {
                    NSLog("added location to \(filename)")
                    strongSelf.locations.removeAll(keepingCapacity: false)
                }
            }
        }
    }
    
    func startUpdatingLocation(_ force: Bool) {
        NSLog("startUpdatingLocation called")
        if !updating || force {
            updating = true
            
            self.locationManager?.desiredAccuracy = lowPower ? kCLLocationAccuracyThreeKilometers : kCLLocationAccuracyNearestTenMeters
            self.locationManager?.distanceFilter = lowPower ? 10.0 : kCLDistanceFilterNone
            
            locationManager?.startUpdatingLocation()
//            motionManager?.startMagnetometerUpdates()
//            activityService?.startMonitoringActivity()

//            bgTask = UIApplication.shared.beginBackgroundTask(withName: "location update") {
//                print("end background task")
//                UIApplication.shared.endBackgroundTask(self.bgTask)
//                self.bgTask = UIBackgroundTaskInvalid
//            }
            
            let uclRegion = CLCircularRegion(center: uclCoords, radius: 100, identifier: "UCL")
            let homeRegion = CLCircularRegion(center: homeCoords, radius: 100, identifier: "Home")
            locationManager?.startMonitoring(for: uclRegion)
            locationManager?.startMonitoring(for: homeRegion)
            
            NSLog("Start location updates with lowPower \(lowPower)")
        } else {
            NSLog("A query was made to update")
        }
    }
    
    func stopUpdatingLocation() {
        updating = false
        
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
//        motionManager?.stopMagnetometerUpdates()
//        activityService?.stopMonitoringActivity()
        
        timer.invalidate()
        stopUpdateTimer.invalidate()
    }
    
    @objc func restartUpdatingLocation() {
        NSLog("restartUpdatingLocation called")
        timer.invalidate()
        lowPower = false
        
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager?.distanceFilter = kCLDistanceFilterNone
        
        startUpdatingLocation(true)
    }
    
    @objc func syncAfterXSeconds() {
        NSLog("syncAfterXSeconds called")
        lowPower = true
        startUpdatingLocation(true)
        sync()
    }

    
    // MARK - State methods
    //State Methods
    @objc func onResume() {
        NSLog("App Resumed")
        background = false
        if(enabled) {
            startUpdatingLocation(true)
        }
    }
    
    @objc func onSuspend() {
        NSLog("App Suspended. Enabled? \(enabled)")
        background = true
        if(enabled) {
            startUpdatingLocation(true)
        }
    }
    
    @objc func willResign() {
        NSLog("App Will Resign. Enabled? \(enabled)")
        background = true
        if(enabled) {
            startUpdatingLocation(false)
        }
    }

    // MARK - Delegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !updating { return }
        
        guard let locationManager = locationManager else { return }
        NSLog("location updated with \(locationManager.desiredAccuracy)")
        
        let location = locations.last!
        let timeSinceUpdate = location.timestamp.timeIntervalSinceNow as Double
        if abs(timeSinceUpdate) < 2.0 {
//            guard let mf = motionManager?.magnetometerData?.magneticField,
//                let (activity, confidence) = activityService?.mostLikelyActivity() else {
//                return
//            }

//            let loc = UserLocation(id: self.id,
//                                   type: self.locationType,
//                                   location: location,
//                                   magneticField: mf,
//                                   activity: activity,
//                                   activityConfidence: confidence)
            let loc = UserLocation(id: self.id, location: location, targetAccuracy: locationManager.desiredAccuracy)
            self.locations.append(loc)
        }
        
        if timer.isValid { return }
        
        let isStationary = false
//        if let activityService = activityService {
//            NSLog("isStationary: \(activityService.isStationary), activities: \(activityService.activities)")
//            isStationary = activityService.isStationary
//        }
        
        print("start background task")
//        bgTask = UIApplication.shared.beginBackgroundTask(withName: "location update") {
//            print("end background task")
//            UIApplication.shared.endBackgroundTask(self.bgTask)
//            self.bgTask = UIBackgroundTaskInvalid
//        }
        
        timer = Timer.scheduledTimer(timeInterval: isStationary ? stationaryTimeout : standardTimeout,
                                     target: self,
                                     selector: #selector(LocationService.restartUpdatingLocation),
                                     userInfo: nil,
                                     repeats: false)
        
        stopUpdateTimer.invalidate()
        stopUpdateTimer = Timer.scheduledTimer(timeInterval: syncSeconds,
                                               target: self,
                                               selector: #selector(LocationService.syncAfterXSeconds),
                                               userInfo: nil,
                                               repeats: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NotificationService.shared.sendLocalNotificationNow(title: "Entered region \(region.identifier)", body: "You just entered the monitored region")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NotificationService.shared.sendLocalNotificationNow(title: "Left region \(region.identifier)", body: "You just left the monitored region")
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        if let error = error {
            NSLog("Location Manager FAILED deferred \((error as NSError).description)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Location Manager Resumed Location Updates")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        NSLog("Location Manager Paused Location Updates")
    }

}
