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
    @objc optional func dataStoreDidUpdatePersonalInformationReview(for piid: String?, type: ReviewType, with rating: Int32, allRatings: [Int32])
    @objc optional func dataStoreDidUpdateVisit(for vid: String, with visited: Int32)
    @objc optional func dataStoreDidUpdatePlaceReviewed(for pid: String, with reviewed: Bool)
    @objc optional func dataStoreDidUpdatePersonalInformationRating(for piid: String, with rating: Int32)
    @objc optional func dataStoreDidUpdateAggregatedPersonalInformation()
}


class DataStoreService: NSObject {
    static let shared = DataStoreService()
    var delegate: DataStoreUpdateProtocol?
    var container: NSPersistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    override init() {
        super.init()
    }
    
    func resetContext() {
        let context = container.viewContext
        print("resetContext")
        context.reset()
    }
    
    func updateDatabase(with userUpdate: UserUpdate, delete: Bool = false, callback:(()->Void)? = nil) {
        container.performBackgroundTask { [weak self] context in
            guard let strongSelf = self else { return }
            
            if let places = userUpdate.p {
                for userPlace in places {
                    _ = try? Place.findOrCreatePlace(matching: userPlace, in: context)
                }
            }
            if let visits = userUpdate.v, let days = userUpdate.days {
                var savedVisits: Set<String> = Set()
                for day in days {
                    for v in strongSelf.getVisits(for: day, sameContext: true) {
                        if let vid = v.id {
                            savedVisits.insert(vid)
                        }
                    }
                }
                
                for userVisit in visits {
                    _ = try? Visit.findOrCreateVisit(matching: userVisit, in: context)
                    savedVisits.remove(userVisit.vid)
                }
                
                if delete {
                    for vid in savedVisits {
                        if let v = try! Visit.findVisit(matching: vid, in: context) {
                            context.delete(v)
                        }
                    }
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
            if let apis = userUpdate.api {
                for userAPI in apis {
                    _ = try? AggregatedPersonalInformation.findOrCreateAggregatedPersonalInformation(matching: userAPI, in: context)
                }
            }
            do {
                try context.save()
            } catch {
                print("updateDatabase userUpdate -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidUpdate?(for: userUpdate.days?.first)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.updateTabBadges()
                callback?()
            }
        }
    }
    
    func updateDatabase(with reviewChallenge: UserReviewChallenge) {
        container.performBackgroundTask { [weak self] context in
            _ = try? ReviewChallenge.findOrCreateReviewChallenge(matching: reviewChallenge, in: context)
            
            do {
                try context.save()
            } catch {
                print("updateDatabase reviewChallenge -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidAddReviewChallenge?(for: reviewChallenge.rcid)
            }
        }
    }
    
    func saveReviewAnswer(with reviewId: String, answer: ReviewAnswer) {
        container.performBackgroundTask { [weak self] context in
            _ = try? Review.saveReviewAnswer(reviewId: reviewId, answer: answer, in: context)
            
            do {
                try context.save()
            } catch {
                print("saveReviewAnswer -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                print("datastore service - update review with answer")
                self?.delegate?.dataStoreDidUpdateReviewAnswer?(for: reviewId, with: answer.rawValue)
            }
        }
    }
    
    func saveCompletedReviewChallenge(with rcid: String, for date: Date) {
        container.performBackgroundTask { [weak self] context in
            _ = try? ReviewChallenge.saveReviewChallengeCompleted(reviewChallengeId: rcid, for: date, in: context)
            
            do {
                try context.save()
            } catch {
                print("saveCompletedReviewChallenge -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                self?.delegate?.dataStoreDidUpdateReviewChallenge?(for: rcid)
            }
        }
    }
    
    func updatePersonalInformationComment(with piid: String, comment: String) {
        container.performBackgroundTask { context in
            try? AggregatedPersonalInformation.updateComment(for: piid, comment: comment,  in: context)
            do {
                try context.save()
            } catch {
                print("updatePersonalInformationComment -- error saving the database")
            }
        }
    }
    
    func updatePersonalInformationReview(with piid: String, type: ReviewType, rating: Int32, callback: (([Int32])->Void)? = nil) {
        container.performBackgroundTask { [weak self] context in
            let allRatings = try? AggregatedPersonalInformation.updateReview(for: piid, type: type, rating: rating, in: context)
            do {
                try context.save()
            } catch {
                print("updatePersonalInformationReview -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                if let allRatings = allRatings {
                    callback?(allRatings)
                    self?.delegate?.dataStoreDidUpdatePersonalInformationReview?(for: piid, type: type, with: rating, allRatings: allRatings)
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.updateTabBadges(type: "reviews")
                }
            }
        }
    }
    
    
    func getPersonalInformation(with piid: String, sameContext:Bool = false) throws -> PersonalInformation? {
        print("getpersonalinformation - \(sameContext)")
        let context = container.viewContext
        if !sameContext {
            context.reset()
        }
        
        do {
            return try PersonalInformation.findPersonalInformation(matching: piid, in: context)
        } catch {
            print("getPersonalInformation -- error saving the database")
        }
        
        return nil
    }
    
    func updateAggregatedPersonalInformation(with pis: [UserAggregatedPersonalInformation], delete: Bool = false, callback: (()->Void)? = nil) {
        
        container.performBackgroundTask { [weak self] context in
            guard let strongSelf = self else { return }
            
            var savedPI: Set<String> = Set()
            for pi in strongSelf.getAllAggregatedPersonalInformation(sameContext: true) {
                if let pid = pi.id {
                    savedPI.insert(pid)
                }
            }
            
            for userPI in pis {
                _ = try? AggregatedPersonalInformation.findOrCreateAggregatedPersonalInformation(matching: userPI, in: context)
                savedPI.remove(userPI.piid)
            }
            
            if delete {
                for pid in savedPI {
                    if let pi = try! AggregatedPersonalInformation.findAggregatedPersonalInformation(matching: pid, in: context) {
                        context.delete(pi)
                    }
                }
            }
                        
            do {
                try context.save()
            } catch {
                print("updateAggregatedPersonalInformation -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                callback?()
                self?.delegate?.dataStoreDidUpdateAggregatedPersonalInformation?()
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.updateTabBadges(type: "reviews")
            }
        }
    }
    
    func updateVisit(with vid: String, visited: Int32, callback: (()->Void)? = nil) {
        container.performBackgroundTask { [weak self] context in
            try? Visit.updateVisit(for: vid, visited: visited, in: context)
            do {
                try context.save()
            } catch {
                print("updateVisit vid visited -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                print("call udpateTabBadges")
                appDelegate.updateTabBadges()
                
                callback?()
                self?.delegate?.dataStoreDidUpdateVisit?(for: vid, with: visited)
            }

        }
        
    }
    
    func updateVisit(with vid: String, departure: Date, callback: (()->Void)? = nil) {
        container.performBackgroundTask { context in
            try? Visit.updateVisit(for: vid, departure: departure, in: context)
            do {
                try context.save()
            } catch {
                print("updateVisit vid departure -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                callback?()
            }
        }
    }
    
    func updatePlaceReviewed(with pid: String, reviewed: Bool, callback: (()->Void)? = nil) {
        container.performBackgroundTask { [weak self] context in
            try? Place.updatePlaceReviewed(for: pid, reviewed: reviewed, in: context)
            do {
                try context.save()
            } catch {
                print("updatePlaceReviewed -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                callback?()
                self?.delegate?.dataStoreDidUpdatePlaceReviewed?(for: pid, with: reviewed)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.updateTabBadges(type: "reviews")
            }
        }
    }
    
    func updatePlaceType(with pid: String, answer: Int32, callback: (()->Void)? = nil) {
        container.performBackgroundTask { context in
            try? Place.updatePlaceType(for: pid, answer: answer, in: context)
            do {
                try context.save()
            } catch {
                print("updatePlaceType -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                callback?()
            }
        }
    }
    
    func updatePersonalInformationRating(with piid: String, rating: Int32, callback: (()->())? = nil) {
        container.performBackgroundTask { [weak self] context in
            try? PersonalInformation.updateRating(for: piid, rating: rating, in: context)
            do {
                try context.save()
            } catch {
                print("updatePersonalInformationRating -- error saving the database")
            }
            
            DispatchQueue.main.async { () -> Void in
                callback?()
                self?.delegate?.dataStoreDidUpdatePersonalInformationRating?(for: piid, with: rating)
            }
        }
    }
    
    func getUniqueVisitDays(sameContext: Bool = false) -> [String] {
//        guard let context = container?.viewContext else { return [] }
        let context = container.viewContext
        print("getUniqueVisitDays - \(sameContext)")
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "arrival", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            let distinct = NSOrderedSet(array: matches.map { $0.day ?? "" })
            let array = distinct.array as! [String]
            return array.reversed()
        } catch {
            print("Could not fetch visits. \(error)")
        }
        
        return []
    }
    
    func getVisits(for day: String, sameContext: Bool = false) -> [Visit] {
        let context = container.viewContext
        print("getVisits for day - \(sameContext)")
        
        if !sameContext {
            context.reset()
        }
        
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
    
    func getVisit(for vid: String, sameContext: Bool = false) -> Visit? {
//        guard let context = container.viewContext else { return nil }
        let context = container.viewContext
        print("getvisit for vid - \(sameContext)")
        if !sameContext {
            context.reset()
        }
        
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
    
    func getAllVisits(sameContext: Bool = false) -> [Visit] {
//        guard let context = container?.viewContext else { return [] }
        let context = container.viewContext
        print("getallvisits - \(sameContext)")
        if !sameContext {
            context.reset()
        }
        
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
    
    func getAllVisitsConfirmed(sameContext: Bool = false) -> [Visit] {
        let context = container.viewContext
        print("getallvisitsConfirmed - \(sameContext)")
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<Visit> = Visit.fetchRequest()
        
        // Add a predicate
        request.predicate = NSPredicate(format: "visited == 1")
        
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
    
    func getAllPlaces(sameContext: Bool = false) -> [Place] {
        print("getallplaces - \(sameContext)")
//        guard let context = container?.viewContext else { return [] }
        let context = container.viewContext
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "added", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            return matches
        } catch {
            print("Could not fetch all places. \(error)")
        }
        
        return []
    }
    
    func getAllPlacesReviewed(sameContext: Bool = false) -> [Place] {
        print("getAllPlacesReviewed - \(sameContext)")
        
        let context = container.viewContext
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        
        // Add a predicate
        request.predicate = NSPredicate(format: "(reviewed == TRUE) AND (personalInformation.@count > 0) AND (visits.@count > 0)")
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "added", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            print("return \(matches.count) matches")
            return matches
        } catch {
            print("Could not fetch all places reviewed. \(error)")
        }
        
        return []
    }

    func getAllPlacesToReview(sameContext: Bool = false) -> [Place] {
        print("getAllPlacesToReview")
        
        let context = container.viewContext
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        
        // Add a predicate
        request.predicate = NSPredicate(format: "(reviewed == NIL OR reviewed == FALSE) AND (personalInformation.@count > 0) AND (visits.@count > 0)")
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "added", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request).filter({
                $0.numberOfPersonalInformationToReview > 0 && $0.numberOfVisitsConfirmed > 0
            })
            return matches
        } catch {
            print("Could not fetch all places to review. \(error)")
        }
        
        return []
    }
    
    func getAllAggregatedPersonalInformation(sameContext: Bool = false) -> [AggregatedPersonalInformation] {
        print("getallaggregatedpersonalinformation - \(sameContext)")
//        guard let context = container?.viewContext else { return [] }
        let context = container.viewContext
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<AggregatedPersonalInformation> = AggregatedPersonalInformation.fetchRequest()
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request)
            return matches
        } catch {
            print("Could not fetch all aggregated personal information. \(error)")
        }
        
        return []
    }
    
    func getAggregatedPersonalInformationToReview(sameContext: Bool = false) -> [AggregatedPersonalInformation] {
        print("getAggregatedPersonalInformationToReview - \(sameContext)")
        //        guard let context = container?.viewContext else { return [] }
        let context = container.viewContext
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<AggregatedPersonalInformation> = AggregatedPersonalInformation.fetchRequest()
        
        // Add a predicate
        request.predicate = NSPredicate(format: "(reviewed == NIL OR reviewed == FALSE)")
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request).filter({ $0.numberOfVisits > 0 })
            return matches
        } catch {
            print("Could not fetch all aggregated personal information. \(error)")
        }
        
        return []
    }
    
    func getAggregatedPersonalInformationReviewed(sameContext: Bool = false) -> [AggregatedPersonalInformation] {
        print("getAggregatedPersonalInformationReviewed - \(sameContext)")
        //        guard let context = container?.viewContext else { return [] }
        let context = container.viewContext
        if !sameContext {
            context.reset()
        }
        
        // create the fetch request
        let request: NSFetchRequest<AggregatedPersonalInformation> = AggregatedPersonalInformation.fetchRequest()
        
        // Add a predicate
        request.predicate = NSPredicate(format: "(reviewed == TRUE)")
        
        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let matches = try context.fetch(request).filter({ $0.numberOfVisits > 0 })
            return matches
        } catch {
            print("Could not fetch all aggregated personal information. \(error)")
        }
        
        return []
    }
    
    func deleteAllReviewChallenges() {
//        guard let context = container?.viewContext else { return }
        let context = container.viewContext
        
        // deleting personal information
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ReviewChallenge")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting review challenges", error)
        }
    }
    
    func deleteAllAggregatedPersonalInformation() {
//        guard let context = container?.viewContext else { return }
        let context = container.viewContext
        
        // deleting personal information
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "AggregatedPersonalInformation")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            _ = try context.execute(request)
        } catch {
            print("error when deleting aggregated personal information", error)
        }
    }
    
    func deleteAll() {
//        guard let context = container?.viewContext else { return }
        let context = container.viewContext
        
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
    
    func deleteVisit(vid: String, callback:(()->Void)? = nil) {
//        guard let context = container?.viewContext else { return }
        let context = container.viewContext
        
        if let visit = try! Visit.findVisit(matching: vid, in: context) {
            
            // delete the review associated to it
            if let review = visit.review {
                context.delete(review)
            }
            
            context.delete(visit)
            
            do {
                try context.save()
                callback?()
            } catch {
                print("error when deleting visit \(vid)", error)
            }
        }
    }
    
    func getLatestReviewChallenge() -> [ReviewChallenge] {
//        guard let context = container?.viewContext else { return [] }
        let context = container.viewContext
        
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
    
    func updateIfNeeded(force: Bool = false) {
        if let lastUpdate = Settings.getLastDatabaseUpdate() {
            let lastUpdateStr = DateHandler.dateToDayString(from: lastUpdate.startOfDay)
            let todayStr = DateHandler.dateToDayString(from: Date())
            if force || todayStr != lastUpdateStr {
                let days = getUniqueVisitDays()
                for day in days {
                    if day == todayStr { continue }
                    let lastVisit = getVisits(for: day, sameContext: true).last
                    if let vid = lastVisit?.id, let lastVisitDeparture = lastVisit?.departure {
                        let endOfDay = lastVisitDeparture.endOfDay
                        updateVisit(with: vid, departure: endOfDay) {
                            print("Updated visit \(vid) with \(endOfDay)")
                        }
                    }
                }
            }
        }
    }
    
    func stats() {
        let context = container.viewContext
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
            if let aggregatedPICount = try? context.count(for: AggregatedPersonalInformation.fetchRequest()) {
                print("\(aggregatedPICount) aggregated personal information")
            }
            
        }
    }
}
