//
//  CoreDataService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/2/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import CoreData
import UIKit


@objc protocol DataStoreUpdateProtocol {
    @objc optional func dataStoreDidUpdate(for day: String?)
    @objc optional func dataStoreDidAddReviewChallenge(for reviewChallengeId: String?)
    @objc optional func dataStoreDidUpdateReviewChallenge(for reviewChallengeId: String?)
    @objc optional func dataStoreDidUpdateReviewAnswer(for reviewId: String?, with answer: Int32)
}


class DataStoreService: NSObject {
    static let shared = DataStoreService()
    var delegate: DataStoreUpdateProtocol?
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override init() {
        super.init()
    }
    
    func updateDatabase(with userUpdate: UserUpdate) {
        container?.performBackgroundTask { [weak self] context in
            if let places = userUpdate.p {
                for userPlace in places {
                    _ = try? Place.findOrCreatePlace(matching: userPlace, in: context)
                }
            }
            if let visits = userUpdate.v {
                for userVisit in visits {
                    _ = try? Visit.findOrCreateVisit(matching: userVisit, in: context)
                }
            }
            if let moves = userUpdate.m {
                for userMove in moves {
                    _ = try? Move.findOrCreateMove(matching: userMove, in: context)
                }
            }
            if let pis = userUpdate.pi {
                for userPI in pis {
                    _ = try? PersonalInformation.findOrCreatePersonalInformation(matching: userPI, in: context)
                }
            }
            if let reviews = userUpdate.rv, let questions = userUpdate.q {
                for userReview in reviews {
                    _ = try? ReviewVisit.findOrCreateReviewVisit(matching: userReview, question: questions[userReview.q], in: context)
                }
            }
            if let reviews = userUpdate.rpi, let questions = userUpdate.q {
                for userReview in reviews {
                    _ = try? ReviewPersonalInformation.findOrCreateReviewPersonalInformation(matching: userReview, question: questions[userReview.q], in: context)
                }
            }

            do {
                try context.save()
            } catch {
                print("error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidUpdate?(for: userUpdate.days?.first)
            }
        }
    }
    
    func updateDatabase(with reviewChallenge: UserReviewChallenge) {
        container?.performBackgroundTask { [weak self] context in
            _ = try? ReviewChallenge.findOrCreateReviewChallenge(matching: reviewChallenge, in: context)
            
            do {
                try context.save()
            } catch {
                print("error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidAddReviewChallenge?(for: reviewChallenge.rcid)
            }
        }
    }
    
    func saveReviewAnswer(with reviewId: String, answer: ReviewAnswer) {
        container?.performBackgroundTask { [weak self] context in
            _ = try? Review.saveReviewAnswer(reviewId: reviewId, answer: answer, in: context)
            
            do {
                try context.save()
            } catch {
                print("error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                print("datastore service - update review with answer")
                self?.delegate?.dataStoreDidUpdateReviewAnswer?(for: reviewId, with: answer.rawValue)
            }
        }
    }
    
    func saveCompletedReviewChallenge(with rcid: String, for date: Date) {
        container?.performBackgroundTask { [weak self] context in
            _ = try? ReviewChallenge.saveReviewChallengeCompleted(reviewChallengeId: rcid, for: date, in: context)
            
            do {
                try context.save()
            } catch {
                print("error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidUpdateReviewChallenge?(for: rcid)
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
                if let piCount = try? context.count(for: PersonalInformation.fetchRequest()) {
                    print("\(piCount) personal information")
                }
                if let rcCount = try? context.count(for: ReviewChallenge.fetchRequest()) {
                    print("\(rcCount) review challenges")
                }
                if let reviewCount = try? context.count(for: Review.fetchRequest()) {
                    print("\(reviewCount) reviews")
                }
            }
        }
    }
    
    func getUniqueVisitDays() -> [String] {
        guard let context = container?.viewContext else { return [] }
        context.reset()
        
        // create the fetch request
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "arrival", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            let distinct = NSOrderedSet(array: matches.map { $0.day! })
            let array = distinct.array as! [String]
            return array.reversed()
        } catch {
            print("Could not fetch visits. \(error)")
        }
        
        return []
    }
    
    func getVisits(for day: String) -> [Visit] {
        guard let context = container?.viewContext else { return [] }
        context.reset()
        
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
    
    func getVisit(for vid: String) -> Visit? {
        guard let context = container?.viewContext else { return nil }
        context.reset()
        
        // create the fetch request
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Add a predicate
        request.predicate = NSPredicate(format: "id = %@", vid)
        
        do {
            let matches = try context.fetch(request)
            return matches[0]
        } catch {
            print("Could not fetch visit. \(error)")
        }
        
        return nil
    }
    
    func getAllVisits() -> [Visit] {
        guard let context = container?.viewContext else { return [] }
        context.reset()
        
        // create the fetch request
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "arrival", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            return matches
        } catch {
            print("Could not fetch all visits. \(error)")
        }
        
        return []
    }
    
    func deleteAllReviewChallenges() {
        guard let context = container?.viewContext else { return }
        
        // deleting personal information
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ReviewChallenge")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting review challenges", error)
        }
    }
    
    func deleteAll() {
        guard let context = container?.viewContext else { return }
        
        // deleting review personal information
        var fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ReviewPersonalInformation")
        var request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting review personal information", error)
        }
        
        // deleting review visits
        fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ReviewVisit")
        request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting review visits", error)
        }
        
        // deleting personal information
        fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PersonalInformation")
        request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting personal information", error)
        }
        
        // deleting review challenge
        fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ReviewChallenge")
        request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting places", error)
        }
        
        // deleting visits
        fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Visit")
        request = NSBatchDeleteRequest(fetchRequest: fetch)
        
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
    
    func deleteVisit(visitid: String) {
        guard let context = container?.viewContext else { return }
        
        if let visit = try! Visit.findVisit(matching: visitid, in: context) {
            
            // delete the review associated to it
            if let review = visit.review {
                context.delete(review)
            }
            
            context.delete(visit)
            
            do {
                try context.save()
            } catch {
                print("error when deleting visit \(visitid)", error)
            }
        }
    }
    
    func getLatestReviewChallenge() -> [ReviewChallenge] {
        guard let context = container?.viewContext else { return [] }
        
        // create the fetch request
        let request: NSFetchRequest<ReviewChallenge> = ReviewChallenge.fetchRequest()
        
        // Add a predicate
        request.predicate = NSPredicate(format: "dateCompleted == nil")
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            
            // filter the challenges for which the reviews have not been already all answered
            var res: [ReviewChallenge] = []
            for challenge in matches {
                if let reviews = challenge.personalInformation?.reviews {
                    for case let review as Review in reviews {
                        if review.answer == .none {
                            res.append(challenge)
                            break
                        }
                    }
                }
            }
            return res
        } catch {
            print("Could not fetch latest review challenges. \(error)")
        }
        
        return []
    }
}
