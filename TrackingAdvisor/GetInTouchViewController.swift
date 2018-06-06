//
//  GetInTouchViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 5/24/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class GetInTouchViewController : UIViewController {
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var contactFormImageView: UIImageView!
    @IBOutlet weak var chatImageView: UIImageView!
    
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var formLabel: UILabel!
    
    @IBOutlet weak var chatButton: UIButton!
    
    
    var isRegisteredForNotifications = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AppDelegate.isIPhone5() {
            welcomeLabel.font = UIFont.systemFont(ofSize: 14.0)
            formLabel.font = UIFont.systemFont(ofSize: 13.0)
            chatLabel.font = UIFont.systemFont(ofSize: 13.0)
        }
        
        contactFormImageView.image = UIImage(named: "envelope")?.withRenderingMode(.alwaysTemplate)
        contactFormImageView.tintColor = Constants.colors.lightPurple
        
        chatImageView.image = UIImage(named: "comments")?.withRenderingMode(.alwaysTemplate)
        chatImageView.tintColor = Constants.colors.midPurple
        
        // Check whether the notifications are enabled
        
        getNotificationRegistration { isRegistered in
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.isRegisteredForNotifications = isRegistered
                if !isRegistered {
                    // User is not registered for notification
                    strongSelf.chatLabel.text = "If you want a truly anonymised experience, you can use a chat to contact us. However, you need to enable the notifications in order to receive the messages."
                    strongSelf.chatButton.setTitle("Enable notifications", for: .normal)
                } else {
                    strongSelf.chatLabel.text = "If you want a truly anonymised experience, you can use the chat to contact us and we will get back to you without having to know your name or your email address."
                    strongSelf.chatButton.setTitle("Chat", for: .normal)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LogService.shared.log(LogService.types.tabSettings)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == "showChat") {
            if isRegisteredForNotifications {
                return true
            } else {
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                return false
            }
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Settings"
        navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
    }
    
    private func getNotificationRegistration(callback: @escaping (Bool)-> Void) {
        if #available(iOS 10.0, *) {
            let current = UNUserNotificationCenter.current()
            current.getNotificationSettings(completionHandler: { settings in
                switch settings.authorizationStatus {
                case .notDetermined:
                    // Authorization request has not been made yet
                    callback(false)
                    break
                case .denied:
                    // User has denied authorization.
                    // You could tell them to change this in Settings
                    callback(false)
                    break
                case .authorized:
                    // User has given authorization.
                    callback(true)
                    break
                }
            })
        } else {
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                callback(true)
            } else {
                callback(false)
            }
        }
    }
}
