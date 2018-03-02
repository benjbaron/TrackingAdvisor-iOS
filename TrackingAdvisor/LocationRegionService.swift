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
        locationManager.startMonitoringVisits()
        
        adaptiveLocationManager = LocationAdaptiveService.shared
        adaptiveLocationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        adaptiveLocationManager = LocationAdaptiveService.shared
        adaptiveLocationManager.stopUpdatingLocation()
    }
    
    func restartUpdatingLocation() {
//        FileService.shared.log("restartUpdatingLocation called", classname: "LocationRegionService")
        stopUpdatingLocation()
        startUpdatingLocation()
    }
    
    func deleteRegions() {
//        FileService.shared.log("Delete all regions", classname: "LocationRegionService")
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
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
                radius = min(100.0, max(100.0 * sqrt(s), 500.0))
            }
            FileService.shared.log("Speed: \(s)", classname: "LocationRegionService")
        }
        
        let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: "currentRegion")
        currentRegions.append(region)
        locationManager.startMonitoring(for: region)
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
        
        DispatchQueue.global(qos: .background).async {
            self.updateRegions(for: location)
        }
        restartUpdatingLocation()
        locationUpdateType = .significant
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        FileService.shared.log("didExitRegion \(region.identifier)", classname: "LocationRegionService")
        restartUpdatingLocation()
        updating = true
        locationUpdateType = .region
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let location = regionLocations[region.identifier]
        guard let loc = location else { return }
//        FileService.shared.log("didEnterRegion \(region.identifier) and location \(loc)", classname: "LocationRegionService")
        DispatchQueue.global(qos: .background).async {
            self.updateRegions(for: loc)
        }
        restartUpdatingLocation()
        locationUpdateType = .region
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
//        FileService.shared.log("didVisit \(visit)", classname: "LocationRegionService")
        restartUpdatingLocation()
        locationUpdateType = .visit
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
//        FileService.shared.log("Started monitoring region \(region.identifier); number of regions: \(locationManager.monitoredRegions.count)", classname: "LocationRegionService")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
//        FileService.shared.log("didDetermineState for region \(region.identifier) -- \(state.rawValue)", classname: "LocationRegionService")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        FileService.shared.log("Location Manager FAILED monitoring region \((error as NSError).description) for region \(String(describing: region))",
            classname: "LocationRegionService")
        if let region = region {
            locationManager.startMonitoring(for: region)
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
        FileService.shared.log("locationDidUpdate \(location.latitude),\(location.longitude)", classname: "LocationRegionService")
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        updateRegions(for: loc)
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
