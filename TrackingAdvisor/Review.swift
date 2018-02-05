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
}
