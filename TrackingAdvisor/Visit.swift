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
    
    class func findOrCreateVisit(matching userVisit: UserVisit, in context: NSManagedObjectContext) throws -> Visit {
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userVisit.vid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Visit.findOrCreateVisit -- database inconsistency")
                return matches[0]
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
        
//        visit.personalInformation = NSSet(array: userVisit.personalinformationids.map {
//            try! PersonalInformation.findPersonalInformation(matching: $0, in: context)!
//        })
        
        return visit
    }
    
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
    
    func getTimesPhrase() -> String {

        guard let arrival = arrival, let departure = departure else { return "" }
        
        let timeDiff = departure.timeIntervalSince(arrival)
        return "You were at this place on \(DateHandler.dateToDayLetterString(from: arrival)) for \(timeDiff.timeIntervalToString()) from \(DateHandler.dateToTimePeriodString(from: arrival)) to \(DateHandler.dateToTimePeriodString(from: departure))"
    }
}
