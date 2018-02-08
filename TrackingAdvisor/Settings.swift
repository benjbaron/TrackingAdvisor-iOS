//
//  Settings.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/7/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation

open class Settings {
    open class func registerDefaults() {
        let defaults = UserDefaults.standard
        
        // Install defaults
        if (!defaults.bool(forKey: "DEFAULTS_INSTALLED")) {
            defaults.set(true, forKey: "DEFAULTS_INSTALLED")
            defaults.set(Date(), forKey: Constants.defaultsKeys.lastFileUpdate)
            defaults.set(Date(), forKey: Constants.defaultsKeys.lastLocationUpdate)
            defaults.set(Date(), forKey: Constants.defaultsKeys.lastUserUpdate)
            defaults.set(Date(), forKey: Constants.defaultsKeys.lastPersonalInformationCategoryUpdate)
            defaults.set(String(), forKey: Constants.defaultsKeys.pushNotificationToken)
            defaults.set(false, forKey: Constants.defaultsKeys.onboarding)
        }
    }
    
    open class func getUserId() -> String {
        let defaults = UserDefaults.standard
        return "1EE560B1-6054-4E2D-A64B-B9ACC3FA0761" // TODO: CHANGE
//        return defaults.string(forKey: Constants.defaultsKeys.userid) ?? ""
    }
    
    open class func getUUID() -> String {
        return "1EE560B1-6054-4E2D-A64B-B9ACC3FA0761" // TODO: CHANGE
//        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
}
