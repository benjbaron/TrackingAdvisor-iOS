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
}
