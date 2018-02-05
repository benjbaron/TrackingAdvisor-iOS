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
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Move.findOrCreateMove -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let move = Move(context: context)
        move.id = userMove.mid
        move.activity = userMove.a
        move.arrivalDate = userMove.ad
        move.departureDate = userMove.dd
        move.arrivalPlace = try! Place.findPlace(matching: userMove.apid, in: context)
        move.departurePlace = try! Place.findPlace(matching: userMove.dpid, in: context)
        move.day = dateFormatter.string(from: userMove.ad)
        
        return move
    }
}
