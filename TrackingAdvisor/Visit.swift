//
//  Visit.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/23/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(Visit)
class Visit: NSManagedObject {
    
    class func findVisit(matching userVisitId: String, in context: NSManagedObjectContext) throws -> Visit? {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userVisitId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Visit.findVisit -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    class func findOrCreateVisit(matching userVisit: UserVisit, in context: NSManagedObjectContext) throws -> Visit {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userVisit.vid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Visit.findOrCreateVisit -- database inconsistency")
                
                // update the visit
                let managedObject = matches[0]
                                                
                if let oldPlace = managedObject.place {
                    oldPlace.removeFromVisits(managedObject)
                }

                managedObject.setValue(userVisit.c, forKey: "confidence")
                managedObject.setValue(userVisit.d, forKey: "departure")
                managedObject.setValue(userVisit.a, forKey: "arrival")
                managedObject.setValue(userVisit.pid, forKey: "placeid")
                managedObject.setValue(DateHandler.dateToDayString(from: userVisit.a), forKey: "day")
                
                if let newPlace = try! Place.findPlace(matching: userVisit.pid, in: context) {
                    managedObject.setValue(newPlace, forKey: "place")
                    newPlace.addToVisits(managedObject)
                }
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        let visit = Visit(context: context)
        visit.id = userVisit.vid
        visit.confidence = userVisit.c
        visit.departure = userVisit.d
        visit.arrival = userVisit.a
        visit.placeid = userVisit.pid
        visit.day = DateHandler.dateToDayString(from: userVisit.a)
        if let place = try! Place.findPlace(matching: userVisit.pid, in: context) {
            visit.place = place
            place.addToVisits(visit)
        }
        
        return visit
    }
    
    class func updateVisit(for vid: String, visited: Int32, in context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", vid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Visit.updateVisit -- database inconsistency")
                let managedObject = matches[0]
                managedObject.setValue(visited, forKey: "visited")
            }
        } catch {
            throw error
        }
    }
    
    func getTimesPhrase() -> String {
        guard let arrival = arrival, let departure = departure else { return "" }
        
        let timeDiff = departure.timeIntervalSince(arrival)
        return "You were at this place on \(DateHandler.dateToDayLetterString(from: arrival)) for \(timeDiff.timeIntervalToString()) from \(DateHandler.dateToTimePeriodString(from: arrival)) to \(DateHandler.dateToTimePeriodString(from: departure))"
    }
}
