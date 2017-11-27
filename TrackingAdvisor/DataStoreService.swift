//
//  CoreDataService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/2/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData


protocol DataStoreUpdateProtocol {
    func dataStoreDidUpdate(update: UserUpdate)
}


class DataStoreService: NSObject {
    static let shared = DataStoreService()
    var delegate: DataStoreUpdateProtocol? = nil
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override init() {
        super.init()
    }
    
    func updateDatabase(with userUpdate: UserUpdate) {
        container?.performBackgroundTask { [weak self] context in
            for userPlace in userUpdate.places {
                print("save place")
                _ = try? Place.findOrCreatePlace(matching: userPlace, in: context)
            }
            
            for userVisit in userUpdate.visits {
                print("save visit")
                _ = try? Visit.findOrCreateVisit(matching: userVisit, in: context)
            }
            
            for userMove in userUpdate.movements {
                print("save move")
                _ = try? Move.findOrCreateMove(matching: userMove, in: context)
            }
            
            do {
                try context.save()
            } catch {
                print("error saving the database")
            }
            self?.stats()
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidUpdate(update: userUpdate)
            }
        }
    }
    
    func stats() {
        if let context = container?.viewContext {
            context.perform {
                if let placeCount = try? context.count(for: Place.fetchRequest()) {
                    print("\(placeCount) places")
                }
                if let visitCount = try? context.count(for: Visit.fetchRequest()) {
                    print("\(visitCount) visits")
                }
                if let moveCount = try? context.count(for: Move.fetchRequest()) {
                    print("\(moveCount) moves")
                }
            }
        }
    }
    
    func getUniqueVisitDays() -> [String] {
        guard let context = container?.viewContext else { return [] }
        
        // create the fetch request
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "arrival", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            let distinct = NSSet(array: matches.map { $0.day! })
            return Array(distinct.allObjects.reversed()) as! [String]
        } catch {
            print("Could not fetch visits. \(error)")
        }
        
        return []
    }
    
    func getVisits(for day: String) -> [Visit] {
        guard let context = container?.viewContext else { return [] }
        
        // create the fetch request
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "arrival", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        // Add a predicate
        request.predicate = NSPredicate(format: "day = %@", day)
        
        do {
            let matches = try context.fetch(request)
            return matches
        } catch {
            print("Could not fetch visits. \(error)")
        }
        
        return []
    }
    
    func deleteAll() {
        guard let context = container?.viewContext else { return }
        
        // deleting visits
        var fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Visit")
        var request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting visits", error)
        }
        
        // deleting moves
        fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Move")
        request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting moves", error)
        }
        
        // deleting places
        fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting places", error)
        }
    }
}
