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
        request.predicate = NSPredicate(format: "id = %@", userVisit.visitid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Visit.findOrCreateVisit -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let visit = Visit(context: context)
        visit.id = userVisit.visitid
        visit.confidence = userVisit.confidence
        visit.departure = userVisit.departure
        visit.arrival = userVisit.arrival
        visit.placeid = userVisit.placeid
        visit.day = dateFormatter.string(from: userVisit.arrival)
        visit.place = try! Place.findPlace(matching: userVisit.placeid, in: context)
        
        return visit
    }
}
