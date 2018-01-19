//
//  PersonalInformation.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/16/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation

struct PersonalInformationCategory: Decodable {
    var name: String? = ""
    var type: String? = ""
    var color: String? = ""
    var icon: String? = ""
    var description: String? = ""
    var personalInfo: [PersonalInformation]? = []
    
    init(name: String) {
        self.name = name
    }
}

struct PersonalInformation: Decodable {
    var name: String? = ""
    var icon: String? = ""
    var color: String? = ""
    var category: String? = ""
    var description: String? = ""
    
    init(name: String) {
        self.name = name
    }
}
