//
//  AggregatedPersonalInformation.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/12/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(AggregatedPersonalInformation)
class AggregatedPersonalInformation : PersonalInformation {
    
    class func findAggregatedPersonalInformation(matching pid: String, in context: NSManagedObjectContext) throws -> AggregatedPersonalInformation? {
        let request: NSFetchRequest<AggregatedPersonalInformation> = AggregatedPersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", pid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "AggregatedPersonalInformation.findAggregatedPersonalInformation -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    class func findOrCreateAggregatedPersonalInformation(matching userAggregatedPersonalInformation: UserAggregatedPersonalInformation, in context: NSManagedObjectContext) throws -> AggregatedPersonalInformation {
    
        let request: NSFetchRequest<AggregatedPersonalInformation> = AggregatedPersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userAggregatedPersonalInformation.piid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "AggregatedPersonalInformation.findOrCreateAggregatedPersonalInformation -- database inconsistency")
                
                // update the personal information
                let managedObject = matches[0]
                
                if let oldPlace = managedObject.place {
                    oldPlace.removeFromPersonalInformation(managedObject)
                }
                
                managedObject.setValue(userAggregatedPersonalInformation.name, forKey: "name")
                managedObject.setValue(userAggregatedPersonalInformation.d, forKey: "desc")
                managedObject.setValue(userAggregatedPersonalInformation.icon, forKey: "icon")
                managedObject.setValue(userAggregatedPersonalInformation.s, forKey: "source")
                managedObject.setValue(userAggregatedPersonalInformation.privacy, forKey: "privacy")
                managedObject.setValue(userAggregatedPersonalInformation.picid, forKey: "category")
                managedObject.setValue(userAggregatedPersonalInformation.explanation, forKey: "explanation")
                managedObject.setValue(userAggregatedPersonalInformation.rpi, forKey: "reviewPersonalInformation")
                managedObject.setValue(userAggregatedPersonalInformation.rexp, forKey: "reviewExplanation")
                managedObject.setValue(userAggregatedPersonalInformation.rpriv, forKey: "reviewPrivacy")
                managedObject.setValue(userAggregatedPersonalInformation.com, forKey: "comment")
                
                managedObject.mutableSetValue(forKey: "personalInformation").removeAllObjects()
                for piid in userAggregatedPersonalInformation.piids {
                    if let pi = try! PersonalInformation.findPersonalInformation(matching: piid, in: context) {
                        managedObject.addToPersonalInformation(pi)
                    }
                }
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        let personalInformation = AggregatedPersonalInformation(context: context)
        personalInformation.id = userAggregatedPersonalInformation.piid
        personalInformation.name = userAggregatedPersonalInformation.name
        personalInformation.desc = userAggregatedPersonalInformation.d
        personalInformation.icon = userAggregatedPersonalInformation.icon
        personalInformation.source = userAggregatedPersonalInformation.s
        personalInformation.privacy = userAggregatedPersonalInformation.privacy
        personalInformation.category = userAggregatedPersonalInformation.picid
        personalInformation.reviewPersonalInformation = userAggregatedPersonalInformation.rpi
        personalInformation.reviewExplanation = userAggregatedPersonalInformation.rexp
        personalInformation.reviewPrivacy = userAggregatedPersonalInformation.rpriv
        personalInformation.comment = userAggregatedPersonalInformation.com
        
        for piid in userAggregatedPersonalInformation.piids {
            if let pi = try! PersonalInformation.findPersonalInformation(matching: piid, in: context) {
                personalInformation.addToPersonalInformation(pi)
            }
        }
        
        return personalInformation
    }
    
    class func updateReview(for piid: String, type: ReviewType, rating: Int32, in context: NSManagedObjectContext) throws -> [Int32] {
        let request: NSFetchRequest<AggregatedPersonalInformation> = AggregatedPersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", piid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "AggregatedPersonalInformation.updateReview -- database inconsistency")
                let managedObject = matches[0]
                
                switch type {
                case .personalInformation:
                    managedObject.setValue(rating, forKey: "reviewPersonalInformation")
                case .explanation:
                    managedObject.setValue(rating, forKey: "reviewExplanation")
                case .privacy:
                    managedObject.setValue(rating, forKey: "reviewPrivacy")
                default:
                    break
                }
                
                // return all personal information ratings
                return [managedObject.reviewPersonalInformation, managedObject.reviewExplanation, managedObject.reviewPrivacy]
            }
        } catch {
            throw error
        }
        
        return []
    }
    
    class func updateComment(for piid: String, comment: String, in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<AggregatedPersonalInformation> = AggregatedPersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", piid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "AggregatedPersonalInformation.updateComment -- database inconsistency")
                let managedObject = matches[0]
                managedObject.setValue(comment, forKey: "comment")
            }
        } catch {
            throw error
        }
    }
    
    func getNumberOfPlacesVisited() -> Int {
        var resSet = Set<String>()
        if let personalInformation = personalInformation {
            for case let pi as PersonalInformation in personalInformation {
                if let pid = pi.place?.id {
                    resSet.insert(pid)
                }
            }
        }
        
        return resSet.count
    }
    
    func getNumberOfVisits() -> Int {
        var resSet = Set<String>()
        
        if let personalInformation = personalInformation {
            for case let pi as PersonalInformation in personalInformation {
                if let visits = pi.place?.visits {
                    for case let visit as Visit in visits {
                        if let vid = visit.id {
                            resSet.insert(vid)
                        }
                    }
                }
            }
        }
        
        return resSet.count
    }
    
    func getExplanation() -> String {
        let numberOfPlaces = getNumberOfPlacesVisited()
        let numberOfVisits = getNumberOfVisits()
        
        let placeStr = numberOfPlaces > 1 ? "different places" : "place"
        let visitStr = numberOfVisits > 2 ? "\(numberOfVisits) times" : (numberOfVisits == 2 ? "twice" : "once")
        
        return "You visited \(numberOfPlaces) \(placeStr) \(visitStr) with this personal information."
    }
}
