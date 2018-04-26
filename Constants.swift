//
//  constants.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/15/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    
    struct defaultsKeys {
        static let versionOfLastRun = "versionOfLastRun"
        static let lastLocationUpdate = "lastLocationUpdate"
        static let lastFileUpdate = "lastFileUpdate"
        static let lastUserUpdate = "lastUserUpdate"
        static let lastPersonalInformationCategoryUpdate = "lastPersonalInformationCategoryUpdate"
        static let lastDatabaseUpdate = "lastDatabaseUpdate"
        static let pushNotificationToken = "pushNotificationToken"
        static let userid = "userid"
        static let onboarding = "onboarding"
        static let optOut = "optOut"
        static let lastKnownLocation = "lastKnownLocation"
        static let forceUploadLocation = "forceUploadLocation"
        static let currentSessionId = "currentSessionId"
        static let currentAppState = "currentAppState"
        static let showRawTrace = "showRawTrace"
        static let pedometerStepsGoal = "pedometerStepsGoal"
        static let pedometerDistanceGoal = "pedometerDistanceGoal"
        static let pedometerTimeGoal = "pedometerTimeGoal"
        static let pedometerUnit = "pedometerUnit"
        static let showActivityRings = "showActivityRings"
    }
    
    struct variables {
        static let minimumDurationBetweenLocationFileUploads: TimeInterval = 3600 // one hour
        static let minimumDurationBetweenUserUpdates: TimeInterval = 60 // 10 minutes
        static let minimumDurationBetweenPersonalInformationCategoryUpdates: TimeInterval = 62400 // one day
    }
    
    struct colors {
        static let defaultColor = UIColor.init(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0);
        static let primaryDark = UIColor.init(red: 48.0/255.0, green: 63.0/255.0, blue: 159.0/255.0, alpha: 1.0)
        static let primaryMidDark = UIColor.init(red: 61.0/255.0, green: 80.0/255.0, blue: 204.0/255.0, alpha: 1.0)
        static let primaryLight = UIColor.init(red: 167.0/255.0, green: 175.0/255.0, blue: 217.0/255.0, alpha: 1.0)
        static let descriptionColor = UIColor.gray
        static let titleColor = UIColor.white
        static let black = UIColor.black
        static let white = UIColor.white
        static let green = UIColor.init(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        static let noColor = UIColor.clear
        static let superLightGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        static let lightGray = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        static let darkRed = UIColor(red: 0.698, green: 0.1529, blue: 0.1529, alpha: 1.0)
        static let orange = UIColor(red: 247/255, green: 148/255, blue: 29/255, alpha: 1.0)
        static let lightOrange = UIColor(red: 244/255, green: 197/255, blue: 146/255, alpha: 1.0)
        static let lightPurple = UIColor(red: 198/255, green: 176/255, blue: 188/255, alpha: 1.0)
        static let midPurple = UIColor(red: 80/255, green: 7/255, blue: 120/255, alpha: 1.0)
        static let darkPurple = UIColor(red: 75/255, green: 56/255, blue: 76/255, alpha: 1.0)
    }
    
    struct filenames {
        static let locationFile = "locations.csv"
        static let logFile = "logs.csv"
    }
    
    struct urls {
        static let locationUploadURL = "https://iss-lab.geog.ucl.ac.uk/semantica/uploader"
        static let closestPlaceURL = "https://iss-lab.geog.ucl.ac.uk/semantica/getclosestplace"
        static let sendMailURL = "https://iss-lab.geog.ucl.ac.uk/semantica/mail"
        static let userUpdateURL = "https://iss-lab.geog.ucl.ac.uk/semantica/userupdate"
        static let placeAutocompleteURL = "https://iss-lab.geog.ucl.ac.uk/semantica/autocomplete"
        static let piAutcompleteURL = "https://iss-lab.geog.ucl.ac.uk/semantica/autocompletepi"
        static let rawTraceURL = "https://iss-lab.geog.ucl.ac.uk/semantica/rawtrace"
        static let personalInformationCategoriesURL = "https://iss-lab.geog.ucl.ac.uk/semantica/personalinformationcategories"
        static let addvisitURL = "https://iss-lab.geog.ucl.ac.uk/semantica/addvisit"
        static let reviewUpdateURL = "https://iss-lab.geog.ucl.ac.uk/semantica/reviews"
        static let reviewChallengeURL = "https://iss-lab.geog.ucl.ac.uk/semantica/userchallenge"
        static let reviewChallengeUpdateURL = "https://iss-lab.geog.ucl.ac.uk/semantica/userchallengeupdate"
        static let registerURL = "https://iss-lab.geog.ucl.ac.uk/semantica/register"
        static let updateUserInfoURL = "https://iss-lab.geog.ucl.ac.uk/semantica/updateuserinfo"
        static let personalInformationUpdateURL = "https://iss-lab.geog.ucl.ac.uk/semantica/personalinformationupdate"
        static let personalInformationReviewUpdateURL = "https://iss-lab.geog.ucl.ac.uk/semantica/personalinformationreviews"
        static let aggregatedPersonalInformationURL = "https://iss-lab.geog.ucl.ac.uk/semantica/aggregatepersonalinformation"
        static let termsURL = "https://iss-lab.geog.ucl.ac.uk/semantica/terms"
        static let privacyPolicyURL = "https://iss-lab.geog.ucl.ac.uk/semantica/privacypolicy"
        static let optOutURL = "https://iss-lab.geog.ucl.ac.uk/semantica/optout"
        static let consentFormURL = "https://iss-lab.geog.ucl.ac.uk/semantica/consentform"
        static let authClientURL = "https://iss-lab.geog.ucl.ac.uk/semantica/authclient"
        static let uploadPedometerDataURL = "https://iss-lab.geog.ucl.ac.uk/semantica/uploadpedometerdata"
    }
    
}
