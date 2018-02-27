//
//  ReviewChallenge.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/26/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(ReviewChallenge)
class ReviewChallenge : NSManagedObject {
    
    class func findReviewChallenge(matching userReviewChallengeId: String, in context: NSManagedObjectContext) throws -> ReviewChallenge? {
        let request: NSFetchRequest<ReviewChallenge> = ReviewChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userReviewChallengeId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewChallenge.findReviewChallenge -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    class func findOrCreateReviewChallenge(matching userReviewChallenge: UserReviewChallenge, in context: NSManagedObjectContext) throws -> ReviewChallenge {
        
        let request: NSFetchRequest<ReviewChallenge> = ReviewChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userReviewChallenge.rcid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewChallenge.findOrCreateReviewChallenge -- database inconsistency")
                
                // update the review challenge with the new value
                let managedObject = matches[0]
                
                print("update review challenge \(userReviewChallenge.rcid)")
                
                managedObject.setValue(userReviewChallenge.day, forKey: "day")
                managedObject.setValue(userReviewChallenge.d, forKey: "dateCreated")
                
                if let newPlace = try! Place.findPlace(matching: userReviewChallenge.pid, in: context) {
                    managedObject.setValue(newPlace, forKey: "place")
                }
                
                if let newVisit = try! Visit.findVisit(matching: userReviewChallenge.vid, in: context) {
                    managedObject.setValue(newVisit, forKey: "visit")
                }
                
                if userReviewChallenge.piid != nil {
                    if let newPi = try! PersonalInformation.findPersonalInformation(matching: userReviewChallenge.piid!, in: context) {
                        managedObject.setValue(newPi, forKey: "personalInformation")
                    }
                }
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        let reviewChallenge = ReviewChallenge(context: context)
        reviewChallenge.id = userReviewChallenge.rcid
        reviewChallenge.day = userReviewChallenge.day
        reviewChallenge.dateCreated = userReviewChallenge.d
        
        if let place = try! Place.findPlace(matching: userReviewChallenge.pid, in: context) {
            reviewChallenge.place = place
        }
        
        if let visit = try! Visit.findVisit(matching: userReviewChallenge.vid, in: context) {
            reviewChallenge.visit = visit
        }
        
        if userReviewChallenge.piid != nil {
            if let pi = try! PersonalInformation.findPersonalInformation(matching: userReviewChallenge.piid!, in: context) {
                reviewChallenge.personalInformation = pi
            }
        }
        
        return reviewChallenge
    }
    
    class func saveReviewChallengeCompleted(reviewChallengeId: String, for date: Date, in context: NSManagedObjectContext) throws -> ReviewChallenge? {
        
        let request: NSFetchRequest<ReviewChallenge> = ReviewChallenge.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", reviewChallengeId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewChallenge.saveReviewChallengeCompleted -- database inconsistency")
                let managedObject = matches[0]
                managedObject.setValue(date, forKey: "dateCompleted")
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    
}
