//
//  PersonalInformation.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/25/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(PersonalInformation)
class PersonalInformation : NSManagedObject {
    
    class func findPersonalInformation(matching userPersonalInformationId: String, in context: NSManagedObjectContext) throws -> PersonalInformation? {
        let request: NSFetchRequest<PersonalInformation> = PersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userPersonalInformationId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "PersonalInformation.findPersonalInformation -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    class func findOrCreatePersonalInformation(matching userPersonalInformation: UserPersonalInformation, in context: NSManagedObjectContext) throws -> PersonalInformation {
        
        let request: NSFetchRequest<PersonalInformation> = PersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userPersonalInformation.piid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "PersonalInformation.findOrCreatePersonalInformation -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let personalInformation = PersonalInformation(context: context)
        personalInformation.id = userPersonalInformation.piid
        personalInformation.name = userPersonalInformation.name
        personalInformation.desc = userPersonalInformation.d
        personalInformation.icon = userPersonalInformation.icon
        personalInformation.source = userPersonalInformation.s
        personalInformation.explanation = userPersonalInformation.e
        personalInformation.privacy = userPersonalInformation.p
        personalInformation.category = userPersonalInformation.picid
        
        if let place = try! Place.findPlace(matching: userPersonalInformation.pid, in: context) {
            personalInformation.place = place
            place.addToPersonalInformation(personalInformation)
        }
        
        return personalInformation
    }
    
    func getReview(of type: ReviewType) -> Review? {
        guard let reviews = reviews else { return nil }
        for case let review as Review in reviews {
            if review.type == type {
                return review
            }
        }
        return nil
    }
        
    func getPersonalInformationPhrase() -> String {
        guard let pi  = name else { return "" }
        return "This place gives information about \(pi.lowercased())"
    }
}
