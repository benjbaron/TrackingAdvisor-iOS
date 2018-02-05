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
    func dataStoreDidAddReviewChallenge(reviewChallenge: UserReviewChallenge)
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
            for userPlace in userUpdate.p {
                print("save place")
                _ = try? Place.findOrCreatePlace(matching: userPlace, in: context)
            }

            for userVisit in userUpdate.v {
                print("save visit")
                _ = try? Visit.findOrCreateVisit(matching: userVisit, in: context)
            }

            for userMove in userUpdate.m {
                print("save move")
                _ = try? Move.findOrCreateMove(matching: userMove, in: context)
            }

            for userPI in userUpdate.pi {
                print("save personal information")
                _ = try? PersonalInformation.findOrCreatePersonalInformation(matching: userPI, in: context)
            }

            for userReview in userUpdate.rv {
                print("save reviews for visits")
                _ = try? ReviewVisit.findOrCreateReviewVisit(matching: userReview, question: userUpdate.q[userReview.q], in: context)
            }

            for userReview in userUpdate.rpi {
                print("save reviews for personal information")
                _ = try? ReviewPersonalInformation.findOrCreateReviewPersonalInformation(matching: userReview, question: userUpdate.q[userReview.q], in: context)
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
    
    func updateDataBase(with reviewChallenge: UserReviewChallenge) {
        container?.performBackgroundTask { [weak self] context in
            _ = try? ReviewChallenge.findOrCreateReviewChallenge(matching: reviewChallenge, in: context)
            
            do {
                try context.save()
            } catch {
                print("error saving the database")
            }
            self?.stats()
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidAddReviewChallenge(reviewChallenge: reviewChallenge)
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
    
    func getLatestReviewChallenge() -> ReviewChallenge? {
        guard let context = container?.viewContext else { return nil }
        
        // create the fetch request
        let request: NSFetchRequest<ReviewChallenge> = ReviewChallenge.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            return matches.first
        } catch {
            print("Could not fetch visits. \(error)")
        }
        
        return nil
    }
}
