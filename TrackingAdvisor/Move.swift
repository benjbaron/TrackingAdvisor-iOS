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
        request.predicate = NSPredicate(format: "id = %@", userMove.moveid)
        
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
        move.id = userMove.moveid
        move.activity = userMove.activity
        move.arrivalDate = userMove.arrivaldate
        move.departureDate = userMove.departuredate
        move.arrivalPlace = try! Place.findPlace(matching: userMove.arrivalplaceid, in: context)
        move.departurePlace = try! Place.findPlace(matching: userMove.departureplaceid, in: context)
        move.day = dateFormatter.string(from: userMove.arrivaldate)
        
        return move
    }
}
