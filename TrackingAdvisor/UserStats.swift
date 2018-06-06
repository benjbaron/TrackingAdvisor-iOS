//
//  UserStats.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 5/19/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation

class UserStats: NSObject, NSCoding, Decodable {
    static let shared = UserStats()
    
    override init() {
        super.init()
        
        if let stats = UserStats.getUserStats() {
            score = stats.score
            level = stats.level
            numberOfDaysStudy = stats.numberOfDaysStudy
            totNumberOfPlacesVisited = stats.totNumberOfPlacesVisited
            numberOfVisitsToConfirm = stats.numberOfVisitsToConfirm
            numberOfVisitsConfirmed = stats.numberOfVisitsConfirmed
            totNumberOfVisits = stats.totNumberOfVisits
            numberOfPlacePersonalInformationToReview = stats.numberOfPlacePersonalInformationToReview
            numberOfPlacePersonalInformationReviewed = stats.numberOfPlacePersonalInformationReviewed
            totNumberOfPlacePersonalInformation = stats.totNumberOfPlacePersonalInformation
            numberOfAggregatedPersonalInformationToReview = stats.numberOfAggregatedPersonalInformationToReview
            numberOfAggregatedPersonalInformationReviewed = stats.numberOfAggregatedPersonalInformationReviewed
            totNumberOfAggregatedPersonalInformation = stats.totNumberOfAggregatedPersonalInformation
        }
    }
    
    // MARK: Properties
    var score: Int = 0
    var level: Int = 1
    
    var numberOfDaysStudy: Int = 1
    var totNumberOfPlacesVisited: Int = 0
    
    var numberOfVisitsToConfirm: Int = 0
    var numberOfVisitsConfirmed: Int = 0
    var totNumberOfVisits: Int = 0
    
    var numberOfPlacePersonalInformationToReview: Int = 0
    var numberOfPlacePersonalInformationReviewed: Int = 0
    var totNumberOfPlacePersonalInformation: Int = 0
    
    var numberOfAggregatedPersonalInformationToReview: Int = 0
    var numberOfAggregatedPersonalInformationReviewed: Int = 0
    var totNumberOfAggregatedPersonalInformation: Int = 0
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("userStats")
    
    // MARK: Types
    struct PropertyKey {
        static let score = "score"
        static let level = "level"
        static let numberOfDaysStudy = "numberOfDaysStudy"
        static let totNumberOfPlacesVisited = "totNumberOfPlacesVisited"
        static let numberOfVisitsToConfirm = "numberOfVisitsToConfirm"
        static let numberOfVisitsConfirmed = "numberOfVisitsConfirmed"
        static let totNumberOfVisits = "totNumberOfVisits"
        static let numberOfPlacePersonalInformationToReview = "numberOfPlacePersonalInformationToReview"
        static let numberOfPlacePersonalInformationReviewed = "numberOfPlacePersonalInformationReviewed"
        static let totNumberOfPlacePersonalInformation = "totNumberOfPlacePersonalInformation"
        static let numberOfAggregatedPersonalInformationToReview = "numberOfAggregatedPersonalInformationToReview"
        static let numberOfAggregatedPersonalInformationReviewed = "numberOfAggregatedPersonalInformationReviewed"
        static let totNumberOfAggregatedPersonalInformation = "totNumberOfAggregatedPersonalInformation"
    }
    
    // MARK: Initialization
    init?(score: Int, level: Int, numberOfDaysStudy: Int, totNumberOfPlacesVisited: Int, numberOfVisitsToConfirm: Int, numberOfVisitsConfirmed: Int, totNumberOfVisits: Int, numberOfPlacePersonalInformationToReview: Int, numberOfPlacePersonalInformationReviewed: Int, totNumberOfPlacePersonalInformation: Int, numberOfAggregatedPersonalInformationToReview: Int, numberOfAggregatedPersonalInformationReviewed: Int, totNumberOfAggregatedPersonalInformation: Int) {
        self.score = score
        self.level = level
        self.numberOfDaysStudy = numberOfDaysStudy
        self.totNumberOfPlacesVisited = totNumberOfPlacesVisited
        self.numberOfVisitsToConfirm = numberOfVisitsToConfirm
        self.numberOfVisitsConfirmed = numberOfVisitsConfirmed
        self.totNumberOfVisits = totNumberOfVisits
        self.numberOfPlacePersonalInformationToReview = numberOfPlacePersonalInformationToReview
        self.numberOfPlacePersonalInformationReviewed = numberOfPlacePersonalInformationReviewed
        self.totNumberOfPlacePersonalInformation = totNumberOfPlacePersonalInformation
        self.numberOfAggregatedPersonalInformationToReview = numberOfAggregatedPersonalInformationToReview
        self.numberOfAggregatedPersonalInformationReviewed = numberOfAggregatedPersonalInformationReviewed
        self.totNumberOfAggregatedPersonalInformation = totNumberOfAggregatedPersonalInformation
    }

    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(score, forKey: PropertyKey.score)
        aCoder.encode(level, forKey: PropertyKey.level)
        aCoder.encode(numberOfDaysStudy, forKey: PropertyKey.numberOfDaysStudy)
        aCoder.encode(totNumberOfPlacesVisited, forKey: PropertyKey.totNumberOfPlacesVisited)
        aCoder.encode(numberOfVisitsToConfirm, forKey: PropertyKey.numberOfVisitsToConfirm)
        aCoder.encode(numberOfVisitsConfirmed, forKey: PropertyKey.numberOfVisitsConfirmed)
        aCoder.encode(totNumberOfVisits, forKey: PropertyKey.totNumberOfVisits)
        aCoder.encode(numberOfPlacePersonalInformationToReview, forKey: PropertyKey.numberOfPlacePersonalInformationToReview)
        aCoder.encode(numberOfPlacePersonalInformationReviewed, forKey: PropertyKey.numberOfPlacePersonalInformationReviewed)
        aCoder.encode(totNumberOfPlacePersonalInformation, forKey: PropertyKey.totNumberOfPlacePersonalInformation)
        aCoder.encode(numberOfAggregatedPersonalInformationToReview, forKey: PropertyKey.numberOfAggregatedPersonalInformationToReview)
        aCoder.encode(numberOfAggregatedPersonalInformationReviewed, forKey: PropertyKey.numberOfAggregatedPersonalInformationReviewed)
        aCoder.encode(totNumberOfAggregatedPersonalInformation, forKey: PropertyKey.totNumberOfAggregatedPersonalInformation)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let score = aDecoder.decodeInteger(forKey: PropertyKey.score)
        let level = aDecoder.decodeInteger(forKey: PropertyKey.level)
        let numberOfDaysStudy = aDecoder.decodeInteger(forKey: PropertyKey.numberOfDaysStudy)
        let totNumberOfPlacesVisited = aDecoder.decodeInteger(forKey: PropertyKey.totNumberOfPlacesVisited)
        let numberOfVisitsToConfirm = aDecoder.decodeInteger(forKey: PropertyKey.numberOfVisitsToConfirm)
        let numberOfVisitsConfirmed = aDecoder.decodeInteger(forKey: PropertyKey.numberOfVisitsConfirmed)
        let totNumberOfVisits = aDecoder.decodeInteger(forKey: PropertyKey.totNumberOfVisits)
        let numberOfPlacePersonalInformationToReview = aDecoder.decodeInteger(forKey: PropertyKey.numberOfPlacePersonalInformationToReview)
        let numberOfPlacePersonalInformationReviewed = aDecoder.decodeInteger(forKey: PropertyKey.numberOfPlacePersonalInformationReviewed)
        let totNumberOfPlacePersonalInformation = aDecoder.decodeInteger(forKey: PropertyKey.totNumberOfPlacePersonalInformation)
        let numberOfAggregatedPersonalInformationToReview = aDecoder.decodeInteger(forKey: PropertyKey.numberOfAggregatedPersonalInformationToReview)
        let numberOfAggregatedPersonalInformationReviewed = aDecoder.decodeInteger(forKey: PropertyKey.numberOfAggregatedPersonalInformationReviewed)
        let totNumberOfAggregatedPersonalInformation = aDecoder.decodeInteger(forKey: PropertyKey.totNumberOfAggregatedPersonalInformation)
        
        self.init(score: score,
                  level: level,
                  numberOfDaysStudy: numberOfDaysStudy,
                  totNumberOfPlacesVisited: totNumberOfPlacesVisited,
                  numberOfVisitsToConfirm: numberOfVisitsToConfirm,
                  numberOfVisitsConfirmed: numberOfVisitsConfirmed,
                  totNumberOfVisits: totNumberOfVisits,
                  numberOfPlacePersonalInformationToReview: numberOfPlacePersonalInformationToReview,
                  numberOfPlacePersonalInformationReviewed: numberOfPlacePersonalInformationReviewed,
                  totNumberOfPlacePersonalInformation: totNumberOfPlacePersonalInformation,
                  numberOfAggregatedPersonalInformationToReview: numberOfAggregatedPersonalInformationToReview,
                  numberOfAggregatedPersonalInformationReviewed: numberOfAggregatedPersonalInformationReviewed,
                  totNumberOfAggregatedPersonalInformation: totNumberOfAggregatedPersonalInformation)
    }
    
    // MARK: Print function
    public func printStats() {
        var s = "==== User Stats ====\n"
        s += "score: \(score)\n"
        s += "level: \(level)\n"
        s += "number of days in the study: \(numberOfDaysStudy)\n"
        s += "total number of places visited: \(totNumberOfPlacesVisited)\n"
        s += "number of visits to confirm: \(numberOfVisitsToConfirm)\n"
        s += "number of visits confirmed: \(numberOfVisitsConfirmed)\n"
        s += "total number of visits: \(totNumberOfVisits)\n"
        s += "number of place with personal information to review: \(numberOfPlacePersonalInformationToReview)\n"
        s += "number of place with personal information reviewed: \(numberOfPlacePersonalInformationReviewed)\n"
        s += "total number of aggregated personal information: \(totNumberOfAggregatedPersonalInformation)\n"
        s += "number of aggregated personal information to review: \(numberOfAggregatedPersonalInformationToReview)\n"
        s += "number of aggregated personal information reviewed: \(numberOfAggregatedPersonalInformationReviewed)\n"
        print(s)
    }
    
    // MARK: Update functions
    public func updateVisitConfirmed() {
        let visits = DataStoreService.shared.getAllVisits(ctxt: nil)
        let visitsConfirmed = visits.filter({ $0.visited == 1 })
        let uniquePlaces = Array(Set(visitsConfirmed.map { $0.place! }))
        totNumberOfPlacesVisited = uniquePlaces.count
        
        // compute the number of visits
        totNumberOfVisits = visits.count
        numberOfVisitsToConfirm = visits.filter({ $0.visited == 0 }).count
        numberOfVisitsConfirmed = visitsConfirmed.count
        
        updateScoreLevel()
    }
    
    public func updateAggregatedPersonalInformation() {
        let aggregatedPI = DataStoreService.shared.getAllAggregatedPersonalInformation(ctxt: nil)
        
        // compute the number of aggregated personal information
        totNumberOfAggregatedPersonalInformation = aggregatedPI.filter({ $0.numberOfVisits > 0 }).count
        numberOfAggregatedPersonalInformationToReview = aggregatedPI.filter({ !$0.reviewed && $0.numberOfVisits > 0 }).count
        numberOfAggregatedPersonalInformationReviewed = aggregatedPI.filter({ $0.reviewed && $0.numberOfVisits > 0 }).count
        
        updateScoreLevel()
    }
    
    public func updatePlacePersonalInformation() {
        let visits = DataStoreService.shared.getAllVisits(ctxt: nil)
        let visitsConfirmed = visits.filter({ $0.visited == 1 })
        let uniquePlaces = Array(Set(visitsConfirmed.map { $0.place! }))
        
        // compute the number of place personal information
        totNumberOfPlacePersonalInformation = uniquePlaces.map({ ($0.personalInformation ?? NSSet()).count }).reduce(0, +)
        numberOfPlacePersonalInformationToReview = uniquePlaces.filter({ !$0.reviewed && $0.numberOfPersonalInformationToReview > 0 && $0.numberOfVisitsConfirmed > 0 }).count
        numberOfPlacePersonalInformationReviewed = uniquePlaces.filter({ $0.reviewed && ($0.personalInformation ?? NSSet()).count > 0 && ($0.visits ?? NSSet()).count > 0 }).count
        
        updateScoreLevel()
    }
    
    private func updateScoreLevel() {
        score = numberOfDaysStudy * 5 + numberOfVisitsConfirmed * 2 + numberOfPlacePersonalInformationReviewed * 1 + numberOfAggregatedPersonalInformationReviewed * 3
        level = UserStats.computeLevel(score: score)
    }
    
    // Update the user stats
    public func updateAll() {
        let visits = DataStoreService.shared.getAllVisits(ctxt: nil)
        let visitsConfirmed = visits.filter({ $0.visited == 1 })
        let aggregatedPI = DataStoreService.shared.getAllAggregatedPersonalInformation(ctxt: nil)
        
        score = 0
        // compute the number of days since the start of the study
        numberOfDaysStudy = 1
        if let firstVisit = visits.first {
            let today = Date()
            numberOfDaysStudy = today.numberOfDays(to: firstVisit.arrival)! + 1
        }
        score += numberOfDaysStudy * 5
        
        // compute the number of places visited
        let uniquePlaces = Array(Set(visitsConfirmed.map { $0.place! }))
        totNumberOfPlacesVisited = uniquePlaces.count
        
        // compute the number of visits
        totNumberOfVisits = visits.count
        numberOfVisitsToConfirm = visits.filter({ $0.visited == 0 }).count
        numberOfVisitsConfirmed = visitsConfirmed.count
        score += numberOfVisitsConfirmed * 2
        
        // compute the number of place personal information
        totNumberOfPlacePersonalInformation = uniquePlaces.map({ ($0.personalInformation ?? NSSet()).count }).reduce(0, +)
        numberOfPlacePersonalInformationToReview = uniquePlaces.filter({ !$0.reviewed && $0.numberOfPersonalInformationToReview > 0 && $0.numberOfVisitsConfirmed > 0 }).count
        numberOfPlacePersonalInformationReviewed = uniquePlaces.filter({ $0.reviewed && ($0.personalInformation ?? NSSet()).count > 0 && ($0.visits ?? NSSet()).count > 0 }).count
        score += numberOfPlacePersonalInformationReviewed * 1
        
        // compute the number of aggregated personal information
        totNumberOfAggregatedPersonalInformation = aggregatedPI.filter({ $0.numberOfVisits > 0 }).count
        numberOfAggregatedPersonalInformationToReview = aggregatedPI.filter({ !$0.reviewed && $0.numberOfVisits > 0 }).count
        numberOfAggregatedPersonalInformationReviewed = aggregatedPI.filter({ $0.reviewed && $0.numberOfVisits > 0 }).count
        score += numberOfAggregatedPersonalInformationReviewed * 3
        
        level = UserStats.computeLevel(score: score)
    }
    
    // MARK: Class functions to save and load the personal information categories
    class func saveUserStats(stats: UserStats) -> Bool {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(stats, toFile: UserStats.ArchiveURL.path)
        return isSuccessfulSave
    }
    
    class func getUserStats() -> UserStats? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: UserStats.ArchiveURL.path) as? UserStats
    }
    
    class func computeLevel(score: Int) -> Int {
        if score < 10 {
            return 1
        } else if score < 25 {
            return 2
        } else if score < 50 {
            return 3
        } else if score < 100 {
            return 4
        } else if score < 250 {
            return 5
        } else if score < 500 {
            return 6
        } else if score < 1000 {
            return 7
        } else if score < 2500 {
            return 8
        } else if score < 5000 {
            return 9
        } else if score < 10000 {
            return 10
        } else {
            return 11
        }
    }
    
    class func getLevelBoundsString(level: Int) -> (String, String) {
        if level == 1 { return ("0", "10") }
        else if level == 2 { return ("10", "25") }
        else if level == 3 { return ("25", "50") }
        else if level == 4 { return ("50", "100") }
        else if level == 5 { return ("100", "250") }
        else if level == 6 { return ("250", "500") }
        else if level == 7 { return ("500", "1,000") }
        else if level == 8 { return ("1,000", "2,500") }
        else if level == 9 { return ("2,500", "5,000") }
        else if level == 10 { return ("5,000", "10,000") }
        else { return ("10,000", "100,000")}
    }
    
    class func getLevelBounds(level: Int) -> (Int, Int) {
        if level == 1 { return (0, 10) }
        else if level == 2 { return (10, 25) }
        else if level == 3 { return (25, 50) }
        else if level == 4 { return (50, 100) }
        else if level == 5 { return (100, 250) }
        else if level == 6 { return (250, 500) }
        else if level == 7 { return (500, 1000) }
        else if level == 8 { return (1000, 2500) }
        else if level == 9 { return (2500, 5000) }
        else if level == 10 { return (5000, 10000) }
        else { return (10000, 100000)}
    }
}
