//
//  ReviewPersonalInformation.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 2/5/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(ReviewPersonalInformation)
class ReviewPersonalInformation: Review {
    
    class func findReviewPersonalInformation(matching userReviewId: String, in context: NSManagedObjectContext) throws -> ReviewPersonalInformation? {
        let request: NSFetchRequest<ReviewPersonalInformation> = ReviewPersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userReviewId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewPersonalInformation.findReviewPersonalInformation -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    class func findOrCreateReviewPersonalInformation(matching userReview: UserReviewPersonalInformation, question: String, in context: NSManagedObjectContext) throws -> ReviewPersonalInformation {
        
        let request: NSFetchRequest<ReviewPersonalInformation> = ReviewPersonalInformation.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userReview.rid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewPersonalInformation.findOrCreateReviewPersonalInformation -- database inconsistency")
                
                // update the review
                let managedObject = matches[0]
                                
                if let oldPlace = managedObject.place {
                    oldPlace.removeFromReviews(managedObject)
                }
                if let oldPi = managedObject.personalinformation {
                    oldPi.removeFromReviews(managedObject)
                }
                
                managedObject.setValue(question, forKey: "question")
                managedObject.setValue(userReview.a, forKey: "answer_")
                managedObject.setValue(userReview.t, forKey: "type_")
                
                if let newPlace = try! Place.findPlace(matching: userReview.pid, in: context) {
                    managedObject.setValue(newPlace, forKey: "place")
                    newPlace.addToReviews(managedObject)
                }
                if let newPi = try! PersonalInformation.findPersonalInformation(matching: userReview.piid, in: context) {
                    managedObject.setValue(newPi, forKey: "personalinformation")
                    newPi.addToReviews(managedObject)
                }
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        let review = ReviewPersonalInformation(context: context)
        review.id = userReview.rid
        review.question = question
        review.answer = ReviewAnswer(rawValue: userReview.a)!
        review.type = ReviewType(rawValue: userReview.t)!
        if let place = try! Place.findPlace(matching: userReview.pid, in: context) {
            review.place = place
            place.addToReviews(review)
        }
        if let pi = try! PersonalInformation.findPersonalInformation(matching: userReview.piid, in: context) {
            review.personalinformation = pi
            pi.addToReviews(review)
        }
        
        return review
    }

}


