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
        request.predicate = NSPredicate(format: "id = %@", userReviewChallenge.reviewchallengeid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ReviewChallenge.findOrCreateReviewChallenge -- database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let reviewChallenge = ReviewChallenge(context: context)
        reviewChallenge.id = userReviewChallenge.reviewchallengeid
        reviewChallenge.name = userReviewChallenge.name
        reviewChallenge.day = userReviewChallenge.day
        reviewChallenge.date = userReviewChallenge.date
        reviewChallenge.personalInformation = NSSet(array: userReviewChallenge.personalinformationids.map {
            try! PersonalInformation.findPersonalInformation(matching: $0, in: context)!
        })
        
        return reviewChallenge
    }
    
    func getPersonalInformationPlaces() -> [PersonalInformation]? {
        guard let personalInformation = personalInformation else { return nil }
        var piplaces: [PersonalInformation] = []
        for case let pi as PersonalInformation in personalInformation {
            piplaces.append(pi)
        }
        return piplaces
    }

    
}
