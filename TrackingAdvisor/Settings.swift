//
//  Settings.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/7/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

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
            defaults.set(Date(), forKey: Constants.defaultsKeys.lastDatabaseUpdate)
            defaults.set(String(), forKey: Constants.defaultsKeys.pushNotificationToken)
            defaults.set(false, forKey: Constants.defaultsKeys.onboarding)
            defaults.set(false, forKey: Constants.defaultsKeys.optOut)
            defaults.set(nil, forKey: Constants.defaultsKeys.lastKnownLocation)
            defaults.set(false, forKey: Constants.defaultsKeys.forceUploadLocation)
        }
    }
    
    open class func getUserId() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: Constants.defaultsKeys.userid) ?? nil
    }
    
    open class func getUUID() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString ?? nil
    }
    
    open class func getPushNotificationId() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: Constants.defaultsKeys.pushNotificationToken) ?? nil
    }
    
    open class func getLastPersonalInformationCategoryUpdate() -> Date? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: Constants.defaultsKeys.lastPersonalInformationCategoryUpdate) as? Date
    }
    
    open class func getLastUserUpdate() -> Date? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: Constants.defaultsKeys.lastUserUpdate) as? Date
    }
    
    open class func getLastLocationUpdate() -> Date? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: Constants.defaultsKeys.lastLocationUpdate) as? Date
    }
    
    open class func getLastFileUpdate() -> Date? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: Constants.defaultsKeys.lastFileUpdate) as? Date
    }
    
    open class func getLastDatabaseUpdate() -> Date? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: Constants.defaultsKeys.lastDatabaseUpdate) as? Date
    }
    
    open class func getOnboarding() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: Constants.defaultsKeys.onboarding)
    }
    
    open class func getOptOut() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: Constants.defaultsKeys.optOut)
    }
    
    open class func getLastKnownLocation() -> CLLocation? {
        let defaults = UserDefaults.standard
        if let archived = defaults.data(forKey: Constants.defaultsKeys.lastKnownLocation) {
            return NSKeyedUnarchiver.unarchiveObject(with: archived) as? CLLocation
        }
        return nil
    }
    
    open class func getForceUploadLocation() -> Bool {
        let defautls = UserDefaults.standard
        return defautls.bool(forKey: Constants.defaultsKeys.forceUploadLocation)
    }
    
    open class func savePushNotificationId(with pnid: String) {
        let defaults = UserDefaults.standard
        defaults.set(pnid, forKey: Constants.defaultsKeys.pushNotificationToken)
    }
    
    open class func saveUserId(with userId: String) {
        let defaults = UserDefaults.standard
        defaults.set(userId, forKey: Constants.defaultsKeys.userid)
    }
    
    open class func saveOnboarding(with value: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.onboarding)
    }
    
    open class func saveOptOut(with value: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.optOut)
    }
    
    open class func saveLastPersonalInformationCategoryUpdate(with value: Date) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.lastPersonalInformationCategoryUpdate)
    }
    
    open class func saveLastUserUpdate(with value: Date) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.lastUserUpdate)
    }
    
    open class func saveLastDatabaseUpdate(with value: Date) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.lastDatabaseUpdate)
    }
    
    open class func saveLastLocationUpdate(with value: Date) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.lastLocationUpdate)
    }
    
    open class func saveLastFileUpdate(with value: Date) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.lastFileUpdate)
    }
    
    open class func saveLastKnownLocation(with location: CLLocation) {
        let defaults = UserDefaults.standard
        let archived = NSKeyedArchiver.archivedData(withRootObject: location)
        defaults.set(archived, forKey: Constants.defaultsKeys.lastKnownLocation)
    }
    
    open class func saveForceUploadLocation(with value: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Constants.defaultsKeys.forceUploadLocation)
    }
}
