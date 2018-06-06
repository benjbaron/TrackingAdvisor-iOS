//
//  Networking.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/11/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import Alamofire

class Networking {
    static let shared = Networking()
    public var sessionManager: Alamofire.SessionManager // most of your web service clients will call through sessionManager
    public var backgroundSessionManager: Alamofire.SessionManager // your web services you intend to keep running when the system backgrounds your app will use this
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 10
        configuration.timeoutIntervalForRequest = 10
        self.sessionManager = Alamofire.SessionManager(configuration: configuration)
        
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.trackingadvisor.backgroundtransfer")
        backgroundConfiguration.timeoutIntervalForResource = 10
        backgroundConfiguration.timeoutIntervalForRequest = 10
        
        self.backgroundSessionManager = Alamofire.SessionManager(configuration: backgroundConfiguration)
    }
}
