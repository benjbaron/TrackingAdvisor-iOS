//
//  constants.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/15/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Foundation

struct Constants {
    
    struct defaultsKeys {
        static let lastLocationUpdate = "lastLocationUpdate"
        static let lastFileUpdate = "lastFileUpdate"
        static let pushNotificationToken = "pushNotificationToken"
        static let userid = "userid"
    }
    
    struct variables {
        static let minimumDurationBetweenLocationFileUploads: TimeInterval = 3600 // one hour
    }
    
    struct colors {
        static let defaultColor = UIColor.init(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0);
        static let primaryDark = UIColor.init(red: 48.0/255.0, green: 63.0/255.0, blue: 159.0/255.0, alpha: 1)
        static let primaryLight = UIColor.init(red: 167.0/255.0, green: 175.0/255.0, blue: 217.0/255.0, alpha: 1.0)
        static let descriptionColor = UIColor.gray
        static let titleColor = UIColor.white
        static let black = UIColor.black
        static let white = UIColor.white
        static let green = UIColor.init(red: 76/255, green: 175/255, blue: 80/255, alpha: 1)
        static let noColor = UIColor.clear.cgColor
    }
    
    struct filenames {
        static let locationFile = "locations.csv"
    }
    
    struct urls {
        static let locationUploadURL = "http://semantica.geog.ucl.ac.uk/uploader"
        static let sendMailURL = "http://semantica.geog.ucl.ac.uk/mail"
        static let userUpdateURL = "http://semantica.geog.ucl.ac.uk/userupdate"
        static let placeAutcompleteURL = "http://semantica.geog.ucl.ac.uk/autocomplete"
    }
    
}
