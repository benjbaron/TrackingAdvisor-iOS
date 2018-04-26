//
//  LogService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/9/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import Alamofire

class LogService : NSObject {
    static let shared = LogService()
    
    struct types {
        static let notificationReceived = "notification-received"
        static let notificationOpen = "notification-open"
        static let appLaunchType = "app-launch-type"
        static let appBackground = "app-background"
        static let appForeground = "app-foreground"
        static let appTerminate = "app-terminate"
        static let appStoryboard = "app-storyboard"
        static let locationRegionFailed = "location-region-failed"
        static let locationRegionStart = "location-region-start"
        static let locationRegionStop = "location-region-stop"
        static let locationRegionEnter = "location-region-enter"
        static let locationRegionExit = "location-region-exit"
        static let locationRegionCreate = "location-region-create"
        static let locationRegionDelete = "location-region-delete"
        static let locationVisitUpdate = "location-visit-update"
        static let locationVisitStart = "location-visit-start"
        static let locationVisitStop = "location-visit-stop"
        static let locationSignificantStart = "location-significant-start"
        static let locationSignificantStop = "location-significant-stop"
        static let locationAdaptiveStart = "location-adaptive-start"
        static let locationAdaptiveStop = "location-adaptive-stop"
        static let locationAdaptiveRestart = "location-adaptive-restart"
        static let locationStart = "location-start"
        static let locationRestart = "location-restart"
        static let locationStop = "location-stop"
        static let locationUpdateStart = "location-update-start"
        static let locationUpdateStop = "location-update-stop"
        static let locationUpdate = "location-update"
        static let locationUpdateBest = "location-update-best"
        static let locationUpdateTimer = "location-update-timer"
        static let locationUpdateDelay = "location-update-delay"
        static let locationUpdateFile = "location-update-file"
        static let serverRequest = "server-request"
        static let serverResponse = "server-response"
        static let tabTimeline = "tab-timeline"
        static let tabReviews = "tab-reviews"
        static let tabMap = "tab-map"
        static let tabProfile = "tab-profile"
        static let tabSettings = "tab-settings"
        static let timelineNotification = "timeline-notification"
        static let timelineDay = "timeline-day"
        static let timelineUpdate = "timeline-update"
        static let timelineMap = "timeline-map"
        static let timelineFeedback = "timeline-feedback"
        static let timelineAdded = "timeline-added"
        static let visitAccess = "visit-access"
        static let visitToggle = "visit-toggle"
        static let visitPi = "visit-pi"
        static let visitBack = "visit-back"
        static let visitEditAccess = "visit-edit-access"
        static let visitEditBack = "visit-edit-back"
        static let visitEditSaved = "visit-edit-saved"
        static let visitEditStart = "visit-edit-start"
        static let visitEditEnd = "visit-edit-end"
        static let visitEditDelete = "visit-edit-delete"
        static let visitEditSelected = "visit-edit-selected"
        static let personalInfoAccess = "personal-info-access"
        static let personalInfoLoad = "personal-info-load"
        static let personalInfoSelected = "personal-info-selected"
        static let personalInfoBack = "personal-info-back"
        static let personalInfoSaved = "personal-info-saved"
        static let placeEditSaved = "place-edit-saved"
        static let reviewNotification = "review-notification"
        static let reviewPlaces = "review-places"
        static let reviewPi = "review-pi"
        static let reviewPlacesVisited = "review-places-visited"
        static let reviewPlacesPi = "review-places-pi"
        static let reviewPlacesNext = "review-places-next"
        static let reviewPlacesEndAll = "review-places-end-all"
        static let reviewPiReview = "review-pi-review"
        static let reviewPiFeedback = "review-pi-feedback"
        static let reviewPiOverlay = "review-pi-overlay"
        static let reviewPiNext = "review-pi-next"
        static let reviewPiEndAll = "review-pi-end-all"
        static let profilePiOverlay = "profile-pi-overlay"
        static let profilePiReview = "profile-pi-review"
        static let profilePiFeedback = "profile-pi-feedback"
        static let profileMap = "profile-map"
        static let settingsTerms = "settings-terms"
        static let settingsPolicy = "settings-policy"
        static let settingsLegal = "settings-legal"
        static let settingsContact = "settings-contact"
        static let settingsOptout = "settings-optout"
        static let settingsDelete = "settings-delete"
        static let settingsData = "settings-data"
        static let settingsDataFile = "settings-data-file"
        static let settingsDataFileDelete = "settings-data-file-delete"
        static let settingsDataFileMap = "settings-data-file-map"
        static let webView = "web-view"
        static let mapReview = "map-review"
        static let settingsPedometer = "settings-pedometer"
    }
    
    struct args {
        static let notificationId = "notification-id"
        static let launchType = "launch-type"
        static let regionId = "region-id"
        static let regionLat = "region-lat"
        static let regionLon = "region-lon"
        static let regionRadius = "region-radius"
        static let visitLat = "visit-lat"
        static let visitLon = "visit-lon"
        static let visitStart = "visit-start"
        static let visitEnd = "visit-end"
        static let visitAccuracy = "visit-accuracy"
        static let locationLat = "location-lat"
        static let locationLon = "location-lon"
        static let locationTimestamp = "location-timestamp"
        static let locationAccuracy = "location-accuracy"
        static let duration = "duration"
        static let requestMethod = "request-method"
        static let requestUrl = "request-url"
        static let requestSize = "request-size"
        static let responseMethod = "response-method"
        static let responseUrl = "response-url"
        static let responseSize = "response-size"
        static let responseCode = "response-code"
        static let day = "day"
        static let toggle = "toggle"
        static let visitId = "visit-id"
        static let placeId = "place-id"
        static let venueId = "venue-id"
        static let piId = "pi-id"
        static let personalInfo = "personal-info"
        static let searchedText = "searched-text"
        static let searchedSelected = "searched-selected"
        static let startTimestamp = "start-timestamp"
        static let endTimestamp = "end-timestamp"
        static let userChoice = "user-choice"
        static let filename = "filename"
        static let reason = "reason"
        static let value = "value"
        static let storyboard = "storyboard"
        static let reviewType = "review-type"
        static let total = "total"
        static let pedometerSteps = "pedometer-steps"
        static let pedometerTime = "pedometer-time"
        static let pedometerDistance = "pedometer-distance"
        static let pedometerUnit = "pedometer-unit"
    }
    
    func determineBatteryState() -> BatteryState {
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
    
    func log(_ id: String, args: [String:String]? = nil) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        let userid = Settings.getUserId() ?? ""
        let sessionId = Settings.getCurrentSessionId()
        let appState = Settings.getCurrentAppState() ?? "none"
        let lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = determineBatteryState()
        let ssid = NetworkService.shared.getSSID() ?? "none"
        let lastKnownLocation = Settings.getLastKnownLocation()
        let lon = lastKnownLocation?.coordinate.longitude ?? 0.0
        let lat = lastKnownLocation?.coordinate.latitude ?? 0.0
        let timestamp = Date().localTime
        let json = args?.json() ?? ""
        
        let line = "\(userid),\(sessionId),\(appState),\(lowPowerMode),\(batteryLevel),\(batteryState),\(ssid),\(lon),\(lat),\(timestamp),\(id),|\(json)|\n"
        let header = "User,Session,State,Power,batteryLevel,batteryCharge,ssid,Lat,Lon,Timestamp,Type,|Args|\n"
        
        // update the temporary file
        if !FileService.shared.fileExists(file: Constants.filenames.logFile) {
            FileService.shared.write(header, in: Constants.filenames.logFile)
        }
        FileService.shared.append(line, in: Constants.filenames.logFile)
    }
}
