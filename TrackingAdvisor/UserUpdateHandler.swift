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
    let rcid: String      // reviewchallengeid
    let day: String       // day
    let d: Date           // datecreated
    let piid: String?     // personalinformationid
    let vid: String       // visitid
    let pid: String       // placeid
}

struct UserUpdate: Codable {
    let uid: String?           // userid
    let from: Date?
    let to: Date?
    let days: [String]?
    let rv: [UserReviewVisit]?      // reviews for visits
    let rpi: [UserReviewPersonalInformation]? // reviews for personal information
    let p: [UserPlace]?        // places
    let v: [UserVisit]?        // visits
    let m: [UserMove]?        // moves
    let pi: [UserPersonalInformation]? // personalinformation
    let q: [String]?           // questions
}

class UserUpdateHandler {
    static var isRetrievingUserUpdateFromServer = false
    static var isRetrievingReviewChallengeFromServer = false
    
    class func retrieveLatestUserUpdates(for day: String) {
        if isRetrievingUserUpdateFromServer { return }
        
        var days:[String] = []
        let calendar = Calendar.current
        // See if the data needs to be uploaded to the server
        if let lastUserUpdate = Settings.getLastUserUpdate() {
            if abs(lastUserUpdate.timeIntervalSinceNow) < Constants.variables.minimumDurationBetweenUserUpdates {
                return
            }
            
            // 0 - get the days since the last update
            var date = lastUserUpdate
            let today = Date()
            while date <= today {
                days.append(DateHandler.dateToDayString(from: date))
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            isRetrievingUserUpdateFromServer = true
            let userid = Settings.getUserId() ?? ""
            
            // 1 - Retreieve the data from the server
            let parameters: Parameters = [
                "userid": userid,
                "days": days
            ]
            
            Alamofire.request(Constants.urls.userUpdateURL, method: .get, parameters: parameters).responseJSON { response in
                print(response)
                if response.result.isSuccess {
                    FileService.shared.log("Retrieved latest user update from server", classname: "UserUpdateHandler")
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                        DataStoreService.shared.updateDatabase(with: userUpdate)
                        Settings.saveLastUserUpdate(with: Date())
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
                isRetrievingUserUpdateFromServer = false
            }
        }
    }
    
    class func retrievingLatestReviewChallenge(for day: String) {
        if isRetrievingReviewChallengeFromServer { return }
        
        DispatchQueue.global(qos: .background).async {
            isRetrievingReviewChallengeFromServer = true
            let userid = Settings.getUserId() ?? ""
            
            let parameters: Parameters = [
                "userid": userid,
                "day": day
            ]
            
            Alamofire.request(Constants.urls.reviewChallengeURL, method: .get, parameters: parameters).responseJSON { response in
                if response.result.isSuccess {
                    FileService.shared.log("Retrieved latest user challenge update from server", classname: "UserUpdateHandler")
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        let userReviewChallenges = try decoder.decode([UserReviewChallenge].self, from: data)
                        
                        // save review challenges in the database
                        for reviewChallenge in userReviewChallenges {
                            DataStoreService.shared.updateDatabase(with: reviewChallenge)
                        }
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
                isRetrievingReviewChallengeFromServer = false
            }
        }
    }
    
    class func sendReviewUpdate(reviews: [String:Int32]) {
        if reviews.count == 0 { return }
        
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            
            let parameters: Parameters = [
                "userid": userid,
                "reviews": reviews
            ]
            
            Alamofire.request(Constants.urls.reviewUpdateURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                if response.result.isSuccess {
                    FileService.shared.log("Sent review update to server", classname: "UserUpdateHandler")
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        _ = try decoder.decode(UserUpdate.self, from: data)
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
            }
        }
    }
    
    class func sendReviewChallengeUpdate(reviewChallenges: [String:Date]) {
        if reviewChallenges.count == 0 { return }
        
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "userid": userid,
                "reviewchallenges": reviewChallenges.mapValues { Int($0.timeIntervalSince1970) }
            ]
            
            Alamofire.request(Constants.urls.reviewChallengeUpdateURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                if response.result.isSuccess {
                    FileService.shared.log("Sent review challenge update to server", classname: "UserUpdateHandler")
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        _ = try decoder.decode(UserUpdate.self, from: data)
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
            }
        }
    }
    
    class func addNewPersonalInformation(for pid: String, name: String, picid: String, callback: (()->Void)?) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "userid": userid,
                "pid": pid,
                "picid": picid,
                "name": name
            ]
            
            Alamofire.request(Constants.urls.personalInformationUpdateURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                if response.result.isSuccess {
                    FileService.shared.log("Sent personal information update to server", classname: "UserUpdateHandler")
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                        DataStoreService.shared.updateDatabase(with: userUpdate)
                        callback?()
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
            }
        }
    }
    
    class func registerNewUser() {
        if Settings.getUserId() != nil { return }
        
        DispatchQueue.global(qos: .background).async {
            let uuid = Settings.getUUID() ?? ""
            let pnid = Settings.getPushNotificationId() ?? ""
            let date = Date()
            
            let parameters: Parameters = [
                "uuid": uuid,
                "pushnotificationid": pnid,
                "date": Int(date.timeIntervalSince1970),
                "type": "ios"
            ]
            
            Alamofire.request(Constants.urls.registerURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                print(response.result)
                if response.result.isSuccess {
                    FileService.shared.log("Register user to server", classname: "UserUpdateHandler")
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let res = try decoder.decode([String:String].self, from: data)
                        if let userid = res["userid"] {
                            Settings.saveUserId(with: userid)
                        }
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
            }
        }
        
    }
    
    class func updateUserInformation() {
        if Settings.getUserId() == nil { return }
        
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let uuid = Settings.getUUID() ?? ""
            let pnid = Settings.getPushNotificationId() ?? ""
            let date = Date()
            
            let parameters: Parameters = [
                "userid": userid,
                "uuid": uuid,
                "pushnotificationid": pnid,
                "date": Int(date.timeIntervalSince1970),
                "type": "ios"
            ]
            
            Alamofire.request(Constants.urls.updateUserInfoURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                print(response.result)
                if response.result.isSuccess {
                    FileService.shared.log("Update user info to server", classname: "UserUpdateHandler")
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let res = try decoder.decode([String:String].self, from: data)
                        if let userid = res["userid"] {
                            Settings.saveUserId(with: userid)
                        }
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
            }
        }
    }
}
