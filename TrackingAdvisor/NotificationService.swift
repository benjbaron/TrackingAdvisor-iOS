//
//  NotificationService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/6/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    func sendLocalNotificationNow(title: String, body: String) {
        
        let localNotification = UNMutableNotificationContent()
        localNotification.title = title
        localNotification.body = body
        localNotification.badge = 1
        localNotification.categoryIdentifier = "trackAdvisor"
        
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "trackAdvisor", content: localNotification, trigger: notificationTrigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            print(error as Any)
        }
    }
}