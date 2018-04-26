//
//  Pedometer.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/25/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(Pedometer)
class Pedometer: NSManagedObject {
    class func findOrCreatePedometer(matching pedometerData: PedometerData, in context: NSManagedObjectContext) throws -> Pedometer? {
                
        let request: NSFetchRequest<Pedometer> = Pedometer.fetchRequest()
        request.predicate = NSPredicate(format: "start = %@", pedometerData.start as NSDate)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Pedometer.findOrCreatePedometer -- database inconsistency")
                
                // update the visit
                let managedObject = matches[0]
                managedObject.setValue(pedometerData.day, forKey: "day")
                managedObject.setValue(pedometerData.start, forKey: "start")
                managedObject.setValue(pedometerData.end, forKey: "end")
                managedObject.setValue(pedometerData.numberOfSteps, forKey: "numberOfSteps")
                managedObject.setValue(pedometerData.distance, forKey: "distance")
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        let pedometer = Pedometer(context: context)
        pedometer.day = pedometerData.day
        pedometer.start = pedometerData.start
        pedometer.end = pedometerData.end
        pedometer.numberOfSteps = Int32(pedometerData.numberOfSteps)
        pedometer.distance = pedometerData.distance
        
        return pedometer
    }
    
    var duration: Int {
        guard let start = start, let end = end else { return 0 }
        let diff = Int(abs(start.timeIntervalSince(end)))
        return min(diff, Int(ceil(Double(numberOfSteps) / 100.0)))
    }
}
