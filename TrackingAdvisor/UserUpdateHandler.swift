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
    let pid: String      // placeid
    let name: String     // name
    let t: String        // type
    let lon: Double      // longitude
    let lat: Double      // latitude
    let c: String        // city
    let a: String        // address
    let col: String    // color
}

struct UserVisit: Codable {
    let vid: String      // visitid
    let pid: String      // placeid
    let a: Date          // arrival
    let d: Date          // departure
    let c: Double        // confidence
}

struct UserMove: Codable {
    let mid: String      // moveid
    let dpid: String     // departureplaceid
    let apid: String     // arrivalplaceid
    let dd: Date         // departuredate
    let ad: Date         // arrivaldate
    let a: String        // activity
}

struct UserPersonalInformation: Codable {
    let piid: String     // personalinformationid
    let picid: String    // personalinformationcategoryid
    let pid: String      // placeid
    let icon: String?
    let name: String
    let d: String?       // description
    let s: [String]?     // source
    let e: String?       // explanation
    let p: String?       // privacy
}

struct UserReviewVisit: Codable {
    let rid: String       // reviewid
    let vid: String       // visitit
    let q: Int            // question
    let t: Int32          // type
    let a: Int32          // answer
}

struct UserReviewPersonalInformation: Codable {
    let rid: String       // reviewid
    let piid: String      // personalinformationid
    let pid: String       // placeid
    let q: Int            // question
    let t: Int32          // type
    let a: Int32          // answer
}

struct UserReviewChallenge: Codable {
    let name: String
    let day: String
    let reviewchallengeid: String
    let date: Date
    let personalinformationids: [String]
}

struct UserUpdate: Codable {
    let uid: String           // userid
    let from: Date
    let to: Date
    let rv: [UserReviewVisit]      // reviews for visits
    let rpi: [UserReviewPersonalInformation] // reviews for personal information
    let p: [UserPlace]        // places
    let v: [UserVisit]        // visits
    let m: [UserMove]         // moves
    let pi: [UserPersonalInformation] // personalinformation
    let q: [String]           // questions
}

class UserUpdateHandler {
    class func retrieveLatestUserUpdates(for day: String) {
        let userid = "1EE560B1-6054-4E2D-A64B-B9ACC3FA0761" // Settings.getUUID()
        let day = "2017-11-21" // TODO: - Change the date to get the latest date available

        // 1 - Retreieve the data from the server
        print("Retreiving udpate from the server \(Constants.urls.userUpdateURL)")
        let parameters: Parameters = ["userid": userid, "day": day]
        Alamofire.request(Constants.urls.userUpdateURL, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                FileService.shared.log("Retrieved latest user update from server", classname: "UserUpdateHandler")
                guard let data = response.data else { return }
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                    DataStoreService.shared.updateDatabase(with: userUpdate)
                } catch {
                    print("Error serializing the json", error)
                }
            } else {
                print("Error in response \(response.result)")
            }
        }
    }
}
