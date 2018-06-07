//
//  AggregatedPersonalInformation.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/12/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData


struct AggregatedPersonalInformationExplanationPlace {
    let place: Place
    let pi: PersonalInformation
    let pid: String
    let lastVisit: Date?
    let numberOfVisits: Int
}


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
                if let subcat = userAggregatedPersonalInformation.subcat {
                    managedObject.setValue(subcat, forKey: "subcategory")
                }
                if let subcatIcon = userAggregatedPersonalInformation.subcat{
                    managedObject.setValue(subcatIcon, forKey: "subcategoryicon")
                }
                
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
        
        if let subcat = userAggregatedPersonalInformation.subcat {
            personalInformation.subcategory = subcat
        }
        if let subcatIcon = userAggregatedPersonalInformation.scicon {
            personalInformation.subcategoryicon = subcatIcon
        }
        
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
                    managedObject.setValue(true, forKey: "reviewed")
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
    
    var numberOfPlacesVisited: Int {
        var resSet = Set<String>()
        if let personalInformation = personalInformation {
            for case let pi as PersonalInformation in personalInformation {
                if let pid = pi.place?.id, let nbVisits = pi.place?.numberOfVisitsConfirmed, nbVisits > 0 {
                    resSet.insert(pid)
                }
            }
        }
        
        return resSet.count
    }
    
    func getExplanationPlaces() -> [AggregatedPersonalInformationExplanationPlace] {
        var res:[AggregatedPersonalInformationExplanationPlace] = []
        if let personalInformation = personalInformation {
            for case let pi as PersonalInformation in personalInformation {
                if let picid = pi.category, picid != category {
                    continue
                }
                
                if let place = pi.place, let visits = pi.place?.visits, let nbVisits = pi.place?.numberOfVisitsConfirmed, nbVisits > 0 {
                    let visitFiltered = (Array(visits) as? [Visit] ?? []).filter({ $0.visited == 1 }).sorted(by: { $0.arrival! < $1.arrival! })
                    let expPlace = AggregatedPersonalInformationExplanationPlace(
                            place: place,
                            pi: pi,
                            pid: place.id!,
                            lastVisit: visitFiltered.last?.arrival,
                            numberOfVisits: visitFiltered.count)
                    
                    res.append(expPlace)
                }
            }
        }
        return res
    }
    
    var numberOfVisits: Int {
        var resSet = Set<String>()
        if let personalInformation = personalInformation {
            for case let pi as PersonalInformation in personalInformation {
                if pi.rating > 1, let visits = pi.place?.visits {
                    for case let visit as Visit in visits {
                        if let vid = visit.id, visit.visited == 1 {
                            resSet.insert(vid)
                        }
                    }
                }
            }
        }
        return resSet.count
    }
    
    var score: Double {
        var res: Double = 0.0
        if reviewPersonalInformation == 1 {
            res = 1.0
        } else if reviewPersonalInformation == 2 {
            res = 25.0
        } else if reviewPersonalInformation == 3 {
            res = 100.0
        }
        
        return res * sqrt(Double(numberOfVisits * numberOfPlacesVisited))
    }
    
    func getExplanation() -> String {
        let nop = numberOfPlacesVisited
        let nov = numberOfVisits
        let placeStr = nop > 1 ? "different places" : "place"
        let visitStr = nov > 2 ? "\(nov) times" : (nov == 2 ? "twice" : "once")
        
        return "You visited \(nop) \(placeStr) \(visitStr) with this personal information."
    }
    
    
}
