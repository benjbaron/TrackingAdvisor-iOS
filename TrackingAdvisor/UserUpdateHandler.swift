//
//  UserUpdate.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/11/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import Alamofire

struct UserPlace: Codable {
    let placeid: String
    let name: String
    let category: String
    let city: String
    let longitude: Double
    let latitude: Double
    let address: String
    let personalinfo: [String:[String]]
}

struct UserVisit: Codable {
    let visitid: String
    let placeid: String
    let arrival: Date
    let departure: Date
    let confidence: Double
}

struct UserMove: Codable {
    let moveid: String
    let departureplaceid: String
    let arrivalplaceid: String
    let departuredate: Date
    let arrivaldate: Date
    let activity: String
}

struct UserUpdate: Codable {
    let userid: String
    let from: Date
    let to: Date
    let moves: [UserMove]
    let places: [UserPlace]
    let visits: [UserVisit]
}


class UserUpdateHandler {
    class func retrieveLatestUserUpdates(for day: String) {
        let userid = UIDevice.current.identifierForVendor!.uuidString
        let day = "2017-11-21"
        // 1 - Retreieve the data from the server
        let parameters: Parameters = ["userid": userid, "day": day]
        Alamofire.request(Constants.urls.userUpdateURL, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                FileService.shared.log("Retrieved latest user update from server", classname: "UserUpdateHandler")
                guard let data = response.data else { return }
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                    //                print(userUpdate)
                    DataStoreService.shared.updateDatabase(with: userUpdate)
                } catch {
                    print("Error serializing the json", error)
                }
            }
        }
    }
}
