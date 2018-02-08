//
//  Movement.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/23/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(Move)
class Move: NSManagedObject {
    class func findOrCreateMove(matching userMove: UserMove, in context: NSManagedObjectContext) throws -> Move {
        let request: NSFetchRequest<Move> = Move.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userMove.mid)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Move.findOrCreateMove -- database inconsistency")
                
                print("update move \(userMove.mid)")
                
                // update the move
                let managedObject = matches[0]
                
                managedObject.setValue(userMove.a, forKey: "activity")
                managedObject.setValue(userMove.ad, forKey: "arrivalDate")
                managedObject.setValue(userMove.dd, forKey: "departureDate")
                managedObject.setValue(dateFormatter.string(from: userMove.ad), forKey: "day")
                if let place = try? Place.findPlace(matching: userMove.apid, in: context) {
                    managedObject.setValue(place, forKey: "arrivalPlace")
                }
                if let place = try? Place.findPlace(matching: userMove.dpid, in: context) {
                    managedObject.setValue(place, forKey: "departurePlace")
                }
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        let move = Move(context: context)
        move.id = userMove.mid
        move.activity = userMove.a
        move.arrivalDate = userMove.ad
        move.departureDate = userMove.dd
        move.day = dateFormatter.string(from: userMove.ad)
        move.arrivalPlace = try! Place.findPlace(matching: userMove.apid, in: context)
        move.departurePlace = try! Place.findPlace(matching: userMove.dpid, in: context)
        
        return move
    }
}
