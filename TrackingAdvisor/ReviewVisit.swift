//
//  ReviewVisit.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 2/5/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc(ReviewVisit)
class ReviewVisit: Review {
    class func findReviewVisit(matching userReviewId: String, in context: NSManagedObjectContext) throws -> ReviewVisit? {
        let request: NSFetchRequest<ReviewVisit> = ReviewVisit.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userReviewId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewVisit.findReviewVisit -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    class func findOrCreateReviewVisit(matching userReview: UserReviewVisit, question: String, in context: NSManagedObjectContext) throws -> ReviewVisit {
        
        let request: NSFetchRequest<ReviewVisit> = ReviewVisit.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userReview.rid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewVisit.findOrCreateReviewVisit -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let review = ReviewVisit(context: context)
        review.id = userReview.rid
        review.question = question
        review.answer = ReviewAnswer(rawValue: userReview.a)!
        review.type = ReviewType(rawValue: userReview.t)!
        if let visit = try! Visit.findVisit(matching: userReview.vid, in: context) {
            review.visit = visit
            visit.review = review
        }
        
        return review
    }
}
