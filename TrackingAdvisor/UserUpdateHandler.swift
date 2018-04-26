//
//  UserUpdate.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/11/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

struct UserPlace: Codable {
    let pid: String      // placeid
    let name: String     // name
    let t: String        // type
    let pt: Int32?       // place type
    let lon: Double      // longitude
    let lat: Double      // latitude
    let c: String?       // city
    let a: String?       // address
    let col: String      // color
    let icon: String?    // icon
    let emoji: String?   // emoji
}

struct UserVisit: Codable {
    let vid: String      // visitid
    let pid: String      // placeid
    let a: Date          // arrival
    let d: Date          // departure
    let c: Double        // confidence
    let visited: Bool?   // visited
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
    let r: Int32         // personal information rating (relevance)
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

struct UserAggregatedPersonalInformation : Codable {
    let piid: String
    let picid: String
    let name: String
    let d: String?            // description
    let icon: String?
    let s: [String] = []      // source
    let privacy: String?
    var rpi: Int32 = 0
    var rexp: Int32 = 0
    var rpriv: Int32 = 0
    var explanation: String?
    var piids: [String] = []  // personal information ids list
    var com: String?          // explanation comment
}

struct UserUpdate: Codable {
    let uid: String?                          // userid
    let from: Date?
    let to: Date?
    let days: [String]?
    let rv: [UserReviewVisit]?                    // reviews for visits
    let rpi: [UserReviewPersonalInformation]?     // reviews for personal information
    let p: [UserPlace]?                           // places
    let v: [UserVisit]?                           // visits
    let m: [UserMove]?                            // moves
    let pi: [UserPersonalInformation]?            // personal information
    let api: [UserAggregatedPersonalInformation]? // aggregated personal information
    let q: [String]?                              // questions
}

class UserUpdateHandler {
    static var isRetrievingUserUpdateFromServer = false
    static var isRetrievingReviewChallengeFromServer = false
    
    class func retrieveLatestUserUpdates(for day: String, force: Bool = false, callback: (()->Void)? = nil) {
        if isRetrievingUserUpdateFromServer { return }
        
        var days: Set<String> = Set<String>()
        let calendar = Calendar.current
        // See if the data needs to be uploaded to the server
        if let lastUserUpdate = Settings.getLastUserUpdate() {
            if !force && abs(lastUserUpdate.timeIntervalSinceNow) < Constants.variables.minimumDurationBetweenUserUpdates {
                return
            }
            
            var date = lastUserUpdate
            if force {
                days.insert(day)
                if let dayDate = DateHandler.dateFromDayString(from: day) {
                    date = dayDate
                    print("force -- start from \(date)")
                }
            }
            
            // 0 - get the days since the last update
            
            let today = Date()
            while date <= today {
                days.insert(DateHandler.dateToDayString(from: date))
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
            print("days: \(days)")
        }
        
        DispatchQueue.global(qos: .background).async {
            isRetrievingUserUpdateFromServer = true
            let userid = Settings.getUserId() ?? ""
            
            // 1 - Retreieve the data from the server
            let parameters: Parameters = [
                "userid": userid,
                "days": Array(days)
            ]
            
            Alamofire.request(Constants.urls.userUpdateURL, method: .get, parameters: parameters).responseJSON { response in
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "get",
                                             LogService.args.responseUrl: Constants.urls.userUpdateURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                        DataStoreService.shared.updateDatabase(with: userUpdate, delete: true) {
                            Settings.saveLastUserUpdate(with: Date())
                            callback?()
                        }                        
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
    
    class func getClosestPlace(coordinate: CLLocationCoordinate2D, callback: ((PlaceSearchResultDetail?)->Void)?) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "userid": userid,
                "lat": coordinate.latitude,
                "lon": coordinate.longitude
            ]
            
            Alamofire.request(Constants.urls.closestPlaceURL, method: .get, parameters: parameters).responseJSON { response in
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "get",
                                             LogService.args.responseUrl: Constants.urls.closestPlaceURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let place = try decoder.decode(PlaceSearchResultDetail.self, from: data)
                        callback?(place)
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
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
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.reviewUpdateURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
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
    
    class func sendPersonalInformationReviewUpdate(reviews: [String:[Int32]]) {
        if reviews.count == 0 { return }
        
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
                        
            let parameters: Parameters = [
                "userid": userid,
                "reviews": reviews
            ]
            
            Alamofire.request(Constants.urls.personalInformationReviewUpdateURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.personalInformationReviewUpdateURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
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
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.reviewChallengeUpdateURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
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
                "t": 0,
                "userid": userid,
                "pid": pid,
                "picid": picid,
                "name": name
            ]
            
            Alamofire.request(Constants.urls.personalInformationUpdateURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.personalInformationUpdateURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                        DataStoreService.shared.updateDatabase(with: userUpdate) {
                            DataStoreService.shared.resetContext()
                            callback?()
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
    
    class func updatePersonalInformation(for piid: String, with comment: String, callback: (()->Void)?) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "t": 1,
                "userid": userid,
                "piid": piid,
                "comment": comment
            ]
            
            Alamofire.request(Constants.urls.personalInformationUpdateURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.personalInformationUpdateURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        _ = try decoder.decode(UserUpdate.self, from: data)
                        DataStoreService.shared.updatePersonalInformationComment(with: piid, comment: comment)
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
    
    class func deleteVisit(for vid: String, callback: (()->Void)?) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "type": VisitActionType.delete.rawValue,
                "userid": userid,
                "visitid": vid
            ]
            
            Alamofire.request(Constants.urls.addvisitURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.addvisitURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        _ = try decoder.decode(UserUpdate.self, from: data)
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
    
    class func visitedVisit(for vid: String, callback: (()->Void)?) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "type": VisitActionType.visited.rawValue,
                "userid": userid,
                "visitid": vid
            ]
            
            Alamofire.request(Constants.urls.addvisitURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.addvisitURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        _ = try decoder.decode(UserUpdate.self, from: data)
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
    
    class func placeType(for pid: String, placeType: Int32, callback: (()->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "type": VisitActionType.placeType.rawValue,
                "userid": userid,
                "placeid": pid,
                "placetype": placeType
            ]
            
            Alamofire.request(Constants.urls.addvisitURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.addvisitURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        print("data")
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                        DataStoreService.shared.updateDatabase(with: userUpdate) {
                            callback?()
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
    
    class func placeEdit(for pid: String, placeName: String, placeAddress: String, placeCity: String, callback: (()->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "type": VisitActionType.placeEdit.rawValue,
                "userid": userid,
                "placeid": pid,
                "name": placeName,
                "address": placeAddress,
                "city": placeCity
            ]
            
            Alamofire.request(Constants.urls.addvisitURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.addvisitURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .secondsSince1970
                        let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                        DataStoreService.shared.updateDatabase(with: userUpdate) {
                            callback?()
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
    
    class func retrieveLatestAggregatedPersonalInformation(callback: (()->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "userid": userid
            ]
            
            Alamofire.request(Constants.urls.aggregatedPersonalInformationURL, method: .get, parameters: parameters).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "get",
                                             LogService.args.responseUrl: Constants.urls.aggregatedPersonalInformationURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let pis = try decoder.decode([UserAggregatedPersonalInformation].self, from: data)
                        DataStoreService.shared.updateAggregatedPersonalInformation(with: pis) {
                            print("updateAggregatedPersonalInformation callback")
                            callback?()
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
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.registerURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
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
    
    class func optOut(callback: (()->Void)?) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""

            let parameters: Parameters = [
                "userid": userid
            ]
            
            Alamofire.request(Constants.urls.optOutURL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.optOutURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                print(response.result)
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let res = try decoder.decode([String:String].self, from: data)
                        if res["status"] == "ok" {
                            callback? ()
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
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "post",
                                             LogService.args.responseUrl: Constants.urls.updateUserInfoURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
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
