//
//  NetworkService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/4/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

class NetworkService : NSObject {
    
    static let shared = NetworkService()
    
    func getSSID() -> String? {
        
        let interfaces = CNCopySupportedInterfaces()
        if interfaces == nil {
            return nil
        }
        
        let interfacesArray = interfaces as! [String]
        if interfacesArray.count <= 0 {
            return nil
        }
        
        let interfaceName = interfacesArray[0] as String
        let unsafeInterfaceData =     CNCopyCurrentNetworkInfo(interfaceName as CFString)
        if unsafeInterfaceData == nil {
            return nil
        }
        
        let interfaceData = unsafeInterfaceData as! Dictionary <String,AnyObject>
        
        return interfaceData["SSID"] as? String
    }
}
