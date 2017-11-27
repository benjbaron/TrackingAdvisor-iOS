//
//  LocationData.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/2/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreLocation

struct UserPlace: Codable {
    let placeid: String
    let name: String
    let city: String
    let category: String
    let longitude: Double
    let latitude: Double
    let address: String
    let userEntered: Bool
}

struct UserVisit: Codable {
    let visitid: String
    let place: UserPlace
    let placeid: String
    let arrival: Date
    let departure: Date
    let confidence: Double
    let longitude: Double
    let latitude: Double
}

struct UserMove: Codable {
    let moveid: String
    let departurePlace: UserPlace
    let arrivalPlace: UserPlace
    let departureDate: Date
    let arrivalDate: Date
    let activity: String
}

struct UserUpdate: Codable {
    let userid: String
    let from: Date
    let to: Date
    let movements: [UserMove]
    let places: [UserPlace]
    let visits: [UserVisit]
}

struct UserLocation {
    let userid: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let accuracy: Double
    let targetAccuracy: Double
    let speed: Double
    
    init(id: String, location: CLLocation, targetAccuracy: Double) {
        self.userid = id
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = location.speed
        self.accuracy = location.horizontalAccuracy
        self.targetAccuracy = targetAccuracy
    }
    
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }
}
