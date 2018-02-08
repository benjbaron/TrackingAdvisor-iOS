//
//  Review.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/25/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData

@objc enum ReviewAnswer: Int32 {
    case none  = 0
    case yes   = 1
    case no    = 2
}

@objc enum ReviewType: Int32 {
    case place               = 0
    case personalInformation = 1
    case explanation         = 2
    case privacy             = 3
}

@objc(Review)
class Review: NSManagedObject {
    
    var type: ReviewType {
        get { return ReviewType(rawValue: type_)! }
        set { type_ = newValue.rawValue }
    }
    var answer: ReviewAnswer {
        get { return ReviewAnswer(rawValue: answer_)! }
        set { answer_ = newValue.rawValue }
    }
    
    class func findReview(matching userReviewId: String, in context: NSManagedObjectContext) throws -> Review? {
        let request: NSFetchRequest<Review> = Review.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", userReviewId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Review.findReview -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }

    class func saveReviewAnswer(reviewId: String, answer: ReviewAnswer, in context: NSManagedObjectContext) throws -> Review? {
        
        let request: NSFetchRequest<Review> = Review.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", reviewId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Review.saveReviewAnswer -- database inconsistency")
                let managedObject = matches[0]
                managedObject.setValue(answer.rawValue, forKey: "answer_")
                
                return managedObject
            }
        } catch {
            throw error
        }
        
        return nil
    }
}
