//
//  LocationData.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/2/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion

struct UserLocation: Encodable {
    let userID: String
    let longitude: Double
    let latitude: Double
    let timestamp: Date
    let accuracy: Double
    let speed: Double
    let targetAccuracy: Double
    
    init(id: String,
         location: CLLocation,
         targetAccuracy: Double = 10.0) {
        self.userID = id
        self.longitude = location.coordinate.longitude
        self.latitude = location.coordinate.latitude
        self.timestamp = location.timestamp
        self.accuracy = location.horizontalAccuracy
        self.speed = location.speed
        self.targetAccuracy = targetAccuracy
    }
    
    func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }
    
    func timestampUnix() -> Double {
        return timestamp.timeIntervalSince1970
    }
}

struct Place: Codable {
    let placeID: String
    let name: String
    let category: String
    let longitude: Double
    let latitude: Double
}

struct UserVisit: Codable {
    let userID: String
    let placeID: String
    let arrival: Date
    let departure: Date
}

struct UserMovement: Codable {
    let userID: String
    let departurePlaceID: String
    let arrivalPlaceID: String
    let departureDate: Date
    let arrivalDate: Date
}

struct UserLocationExtensive: Encodable {
    let userID: String
    let longitude: Double
    let latitude: Double
    let timestamp: Date
    let accuracy: Double
    let magX: Double
    let magY: Double
    let magZ: Double
    let activity: String
    let activityConfidence: Int
    let type: String
    
    init(id: String,
         type: String,
         location: CLLocation,
         magneticField: CMMagneticField,
         activity: String,
         activityConfidence: Int) {
        
        self.userID = id
        self.longitude = location.coordinate.longitude
        self.latitude = location.coordinate.latitude
        self.timestamp = location.timestamp
        self.accuracy = location.horizontalAccuracy
        self.magX = magneticField.x
        self.magY = magneticField.y
        self.magZ = magneticField.z
        self.activityConfidence = activityConfidence
        self.activity = activity
        self.type = type
    }
    
    func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }
    
    func timestampUnix() -> Double {
        return timestamp.timeIntervalSince1970
    }
}
