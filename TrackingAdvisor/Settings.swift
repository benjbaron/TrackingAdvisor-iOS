//
//  Settings.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/7/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation

open class Settings {
    open class func registerDefaults(){
        let defaults = UserDefaults.standard
        // Install defaults
        if (!defaults.bool(forKey: "DEFAULTS_INSTALLED")) {
            defaults.set(true, forKey: "DEFAULTS_INSTALLED")
            defaults.set(Date(), forKey: Constants.defaultsKeys.lastFileUpdate)
            defaults.set(Date(), forKey: Constants.defaultsKeys.lastLocationUpdate)
            defaults.set(String(), forKey: Constants.defaultsKeys.pushNotificationToken)
        }
    }
}
