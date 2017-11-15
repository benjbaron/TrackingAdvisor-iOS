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
    func dataStoreDidUpdate(location: UserLocation)
}


class DataStoreService: NSObject {
    static let shared = DataStoreService()
    var delegate:DataStoreUpdateProtocol!
    var managedContext:NSManagedObjectContext?
    var visitEntity:NSEntityDescription?
    
    override init() {
        super.init()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        self.managedContext = appDelegate.persistentContainer.viewContext
        if let context = self.managedContext {
            self.visitEntity = NSEntityDescription.entity(forEntityName: "Visit", in: context)!
        }
    }
    
    func save(_ location: UserLocation) {
        guard let context = self.managedContext,
            let entity = self.visitEntity else {
                return
        }
        
        let loc = NSManagedObject(entity: entity, insertInto: context)
        
        loc.setValue(location.latitude, forKey: "latitude")
        loc.setValue(location.longitude, forKey: "longitude")
        
        do {
            try context.save()
        } catch let error as NSError {
            NSLog("Could not save. \(error), \(error.userInfo)")
            return
        }
        
        DispatchQueue.main.async { () -> Void in
            if self.delegate != nil {
                self.delegate.dataStoreDidUpdate(location: location)
            }
        }
    }
}
