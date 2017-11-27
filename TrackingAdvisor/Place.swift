//
//  Place.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/23/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(Place)
class Place: NSManagedObject {
    class func findOrCreatePlace(matching userPlace: UserPlace, in context: NSManagedObjectContext) throws -> Place {
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userPlace.placeid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Place.findOrCreatePlace -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let place = Place(context: context)
        place.address = userPlace.address
        place.category = userPlace.category
        place.city = userPlace.city
        place.id = userPlace.placeid
        place.latitude = userPlace.latitude
        place.longitude = userPlace.longitude
        place.name = userPlace.name
        place.userEntered = userPlace.userEntered
        
        return place
    }
}
