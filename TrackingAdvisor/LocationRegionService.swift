//
//  LocationServiceRegions.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/7/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import CoreData
import UIKit

enum LocationRegionUpdateType {
    case region
    case visit
    case significant
}

protocol LocationRegionUpdateProtocol {
    func locationDidUpdate(location: UserLocation, type: LocationRegionUpdateType)
}

class LocationRegionService: NSObject, CLLocationManagerDelegate, LocationAdaptiveUpdateProtocol {
    
    static let shared = LocationRegionService()
    var delegate:LocationRegionUpdateProtocol!
    
    let locationManager = CLLocationManager()
    var adaptiveLocationManager = LocationAdaptiveService.shared
    
    var currentLocation:UserLocation? = nil
    var currentRegions: [CLCircularRegion] = []
    var id: String = Settings.getUserId() ?? ""
    var locationUpdateType: LocationRegionUpdateType = .significant
    
    var regions:[CLCircularRegion] = []
    var regionLocations:[String:CLLocation] = [:]
    let numberOfRegions = 6
    let distanceOfRegionToCenterLocation = 200.0
    let regionRadius = 150.0
    var previousLocation:CLLocation?
    
    let regionRadiuses = [25.0, 50.0, 100.0, 250.0, 500.0, 750.0, 1000.0]

    var updating = false
    
    override init() {
        super.init()
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        // configure the location manager
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        locationManager.delegate = self
        adaptiveLocationManager.delegate = self
    }
    
    func requestPermission() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    class func getLocationServiceStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    func startUpdatingLocation() {
        requestPermission()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone

        locationManager.delegate = self
        adaptiveLocationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        deleteRegions()

        locationManager.startMonitoringSignificantLocationChanges()
        LogService.shared.log(LogService.types.locationSignificantStart)
        locationManager.startMonitoringVisits()
        LogService.shared.log(LogService.types.locationVisitStart)
        
        if !ProcessInfo.processInfo.isLowPowerModeEnabled {
            adaptiveLocationManager = LocationAdaptiveService.shared
            adaptiveLocationManager.startUpdatingLocation()
            LogService.shared.log(LogService.types.locationStart)
        }
    }
    
    func stopUpdatingLocation() {
        
        locationManager.stopUpdatingLocation()
        adaptiveLocationManager = LocationAdaptiveService.shared
        adaptiveLocationManager.stopUpdatingLocation()
        LogService.shared.log(LogService.types.locationStop)
    }
    
    func restartUpdatingLocation() {
        stopUpdatingLocation()
        startUpdatingLocation()
        LogService.shared.log(LogService.types.locationRestart)
    }
    
    func deleteRegions() {
        for case let region as CLCircularRegion in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
            LogService.shared.log(LogService.types.locationRegionDelete,
                                  args: [LogService.args.regionId: region.identifier,
                                         LogService.args.regionLat: String(region.center.latitude),
                                         LogService.args.regionLon: String(region.center.longitude),
                                         LogService.args.regionRadius: String(region.radius)])
        }
        usleep(1000)
        currentRegions.removeAll()
        regions.removeAll()
    }
    
    func updateRegions(for location: CLLocation) {
        // Stop monitoring the current regions
        deleteRegions()
    
        // update the surrounding region
        var radius: CLLocationDistance = 100.0
        if let prev = previousLocation {
            let s = location.speed(with: prev)
            if s > 5.0 {
                radius = max(100.0, min(100.0 * sqrt(s), 1000.0))
            }
        }
        
        let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: "currentRegion")
        let regionDefault = CLCircularRegion(center: location.coordinate, radius: 1250, identifier: "currentRegionDefault")
        currentRegions.append(region)
        currentRegions.append(regionDefault)
        
        locationManager.startMonitoring(for: region)
        locationManager.startMonitoring(for: regionDefault)
        
        LogService.shared.log(LogService.types.locationRegionCreate,
                              args: [LogService.args.regionId: region.identifier,
                                     LogService.args.regionLat: String(region.center.latitude),
                                     LogService.args.regionLon: String(region.center.longitude),
                                     LogService.args.regionRadius: String(region.radius)])
        
        LogService.shared.log(LogService.types.locationRegionCreate,
                              args: [LogService.args.regionId: regionDefault.identifier,
                                     LogService.args.regionLat: String(regionDefault.center.latitude),
                                     LogService.args.regionLon: String(regionDefault.center.longitude),
                                     LogService.args.regionRadius: String(regionDefault.radius)])
        
        previousLocation = location
        
    }
    
    
    func updateRegionsOld(for location: CLLocation) {
        // Stop monitoring the current regions
        deleteRegions()
        
        // update the current regions
        for radius in regionRadiuses {
            let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: "currentRegion-\(Int(radius))")
            currentRegions.append(region)
            locationManager.startMonitoring(for: region)
        }
        
        // update the surrounding regions
        let theta = 2 * Double.pi / Double(numberOfRegions)
        for i in 0..<numberOfRegions {
            let identifier = "regionIdentifier.\(i)"
            let bearing = theta * Double(i)
            let coordinate = location.coordinate.location(for: bearing, and: distanceOfRegionToCenterLocation)
            
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                         longitude: coordinate.longitude),
                                          radius: regionRadius,
                                          identifier: identifier)
            
            regions.append(region)
            
            let intersect = location.coordinate.location(for: bearing, and: distanceOfRegionToCenterLocation-regionRadius)
            let loc = CLLocation(latitude: intersect.latitude, longitude: intersect.longitude)
            regionLocations[identifier] = loc
            locationManager.startMonitoring(for: region)
        }
    }
    
    // MARK - Delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        
        if !ProcessInfo.processInfo.isLowPowerModeEnabled {
            DispatchQueue.global(qos: .background).async {
                self.updateRegions(for: location)
            }
        } else {
            saveLocationToFile(location)
        }
        
        restartUpdatingLocation()
        locationUpdateType = .significant
        
        LogService.shared.log(LogService.types.locationUpdate,
                              args: [LogService.args.locationLat: String(location.coordinate.latitude),
                                     LogService.args.locationLon: String(location.coordinate.longitude),
                                     LogService.args.locationAccuracy: String(location.horizontalAccuracy),
                                     LogService.args.locationTimestamp: location.timestamp.localTime])
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        restartUpdatingLocation()

        updating = true
        locationUpdateType = .region
        
        if let region = region as? CLCircularRegion {
            LogService.shared.log(LogService.types.locationRegionExit,
                                  args: [LogService.args.regionId: region.identifier,
                                         LogService.args.regionLat: String(region.center.latitude),
                                         LogService.args.regionLon: String(region.center.longitude),
                                         LogService.args.regionRadius: String(region.radius)])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let location = regionLocations[region.identifier]
        guard let loc = location else { return }

        DispatchQueue.global(qos: .background).async {
            self.updateRegions(for: loc)
        }
        restartUpdatingLocation()
        locationUpdateType = .region
        
        if let region = region as? CLCircularRegion {
            LogService.shared.log(LogService.types.locationRegionEnter,
                                  args: [LogService.args.regionId: region.identifier,
                                         LogService.args.regionLat: String(region.center.latitude),
                                         LogService.args.regionLon: String(region.center.longitude),
                                         LogService.args.regionRadius: String(region.radius)])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        restartUpdatingLocation()
        locationUpdateType = .visit
        
//        UserUpdateHandler.getClosestPlace(coordinate: visit.coordinate) { place in
//            if let emoji = place?.emoji, let name = place?.name {
//                var text = "\(emoji) Are you at \(name)?"
//                if visit.departureDate != Date.distantFuture {
//                    text = "\(emoji) Were you at \(name)?"
//                }
//                NotificationService.shared.sendLocalNotificationNow(body: text)
//            }
//        }
        
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            saveVisitToFile(visit, timestamp: visit.arrivalDate)
            
            if visit.departureDate != Date.distantFuture {
                saveVisitToFile(visit, timestamp: visit.departureDate)
            }
        }
        
        LogService.shared.log(LogService.types.locationVisitUpdate,
                              args: [LogService.args.visitStart: visit.arrivalDate.localTime,
                                     LogService.args.visitEnd: visit.departureDate.localTime,
                                     LogService.args.visitLat: String(visit.coordinate.latitude),
                                     LogService.args.visitLon: String(visit.coordinate.longitude),
                                     LogService.args.visitAccuracy: String(visit.horizontalAccuracy)])
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let region = region as? CLCircularRegion {
            locationManager.startMonitoring(for: region)
            LogService.shared.log(LogService.types.locationRegionFailed,
                                  args: [LogService.args.regionId: region.identifier,
                                         LogService.args.regionLat: String(region.center.latitude),
                                         LogService.args.regionLon: String(region.center.longitude),
                                         LogService.args.regionRadius: String(region.radius)])
        }
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
    
    
    // MARK - Delegate method for LocationAdaptiveUpdateProtocol
    func locationDidUpdate(location: UserLocation) {
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        updateRegions(for: loc)
                
        LogService.shared.log(LogService.types.locationUpdateBest,
                              args: [LogService.args.locationLat: String(location.latitude),
                                     LogService.args.locationLon: String(location.longitude),
                                     LogService.args.locationAccuracy: String(location.accuracy),
                                     LogService.args.locationTimestamp: location.timestamp.localTime])
    }
    
    
    func saveLocationToFile(_ location: CLLocation) {
        Settings.saveLastKnownLocation(with: location)
        let loc = UserLocation(id: self.id, location: location, targetAccuracy: self.locationManager.desiredAccuracy)
        self.currentLocation = loc
        
        let filename = DateHandler.dateToDayString(from: loc.timestamp) + ".csv"
        loc.dumps(to: filename) { done in
            if done {
                // upload to server
                UserLocation.upload()
            }
        }
    }
    
    func saveVisitToFile(_ visit: CLVisit, timestamp: Date) {
        let loc = UserLocation(id: self.id, visit: visit, targetAccuracy: self.locationManager.desiredAccuracy, timestamp: timestamp)
        self.currentLocation = loc
        
        let filename = DateHandler.dateToDayString(from: loc.timestamp) + ".csv"
        loc.dumps(to: filename) { done in
            if done {
                // upload to server
                UserLocation.upload()
            }
        }
    }
}

extension CLLocationCoordinate2D {
    
    func location(for bearing:Double, and distanceMeters:Double) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6) // earth radius in meters
        
        let lat1 = latitude * Double.pi / 180
        let lon1 = longitude * Double.pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }
}

extension CLLocation {
    func speed(with location: CLLocation) -> CLLocationSpeed {
        let d = distance(from: location)
        let t = abs(timestamp.timeIntervalSince1970 - location.timestamp.timeIntervalSince1970)
        
        return d/t
    }
}
