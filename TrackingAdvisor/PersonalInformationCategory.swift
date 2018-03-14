//
//  PersonalInformationCategory.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 2/5/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import Alamofire

class PersonalInformationCategory: NSObject, NSCoding, Decodable {
    
    // MARK: Properties
    var picid: String  // Equivalent to an acronym
    var name: String
    var detail: String
    var explanation: String
    var icon: String
    var question: String
    var scale: [String]
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("personalInformationCategories")
    
    // MARK: Types
    struct PropertyKey {
        static let picid = "picid"
        static let name = "name"
        static let detail = "detail"
        static let explanation = "explanation"
        static let icon = "icon"
        static let question = "question"
        static let scale = "scale"
    }
    
    // MARK: Initialization
    init?(picid: String, name: String, detail: String, explanation: String, icon: String, question: String, scale: [String]) {
        self.picid = picid
        self.name = name
        self.detail = detail
        self.explanation = explanation
        self.icon = icon
        self.question = question
        self.scale = scale
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(picid, forKey: PropertyKey.picid)
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(detail, forKey: PropertyKey.detail)
        aCoder.encode(explanation, forKey: PropertyKey.explanation)
        aCoder.encode(icon, forKey: PropertyKey.icon)
        aCoder.encode(question, forKey: PropertyKey.question)
        aCoder.encode(scale, forKey: PropertyKey.scale)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // this retrieves our saved picid and casts it as a String
        guard let picid = aDecoder.decodeObject(forKey: PropertyKey.picid) as? String else {
            return nil // initializer should fail
        }
        
        let name = aDecoder.decodeObject(forKey: PropertyKey.name) as! String
        let detail = aDecoder.decodeObject(forKey: PropertyKey.detail) as! String
        let explanation = aDecoder.decodeObject(forKey: PropertyKey.explanation) as! String
        let icon = aDecoder.decodeObject(forKey: PropertyKey.icon) as! String
        let question = aDecoder.decodeObject(forKey: PropertyKey.question) as? String ?? ""
        let scale = aDecoder.decodeObject(forKey: PropertyKey.scale) as? [String] ?? []
        
        self.init(picid: picid, name: name, detail: detail, explanation: explanation, icon: icon, question: question, scale: scale)
    }
    
    // MARK: Class functions to save and load the personal information categories
    class func savePersonalInformationCategories(pics: [PersonalInformationCategory]) -> Bool {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(pics, toFile: PersonalInformationCategory.ArchiveURL.path)
        return isSuccessfulSave
    }
    
    class func loadPersonalInformationCategories() -> [PersonalInformationCategory]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: PersonalInformationCategory.ArchiveURL.path) as? [PersonalInformationCategory]
    }
    
    class func getPersonalInformationCategory(with picid: String) -> PersonalInformationCategory? {
        if let pics = loadPersonalInformationCategories() {
            for pic in pics {
                if pic.picid == picid {
                    return pic
                }
            }
        }
        return nil
    }
    
    // MARK: - Udpate the personal information categories from the server
    class func retrieveLatestPersonalInformationCategories() {
        let userid = Settings.getUserId() ?? ""
        let parameters: Parameters = ["userid": userid]
        Alamofire.request(Constants.urls.personalInformationCategoriesURL, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                guard let data = response.data else { return }
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    let pics = try decoder.decode([PersonalInformationCategory].self, from: data)
                    _ = savePersonalInformationCategories(pics: pics)
                    FileService.shared.log("Retrieved latest personal information categories from server", classname: "PersonalInformationCategory")
                } catch {
                    print("Error serializing the json", error)
                }
            }
        }
    }
    
    class func updateIfNeeded(force: Bool = false) {
        if let lastUpdate = Settings.getLastPersonalInformationCategoryUpdate() {
            let pics = loadPersonalInformationCategories()
            if force || pics == nil || pics?.count == 0 || abs(lastUpdate.timeIntervalSinceNow) > Constants.variables.minimumDurationBetweenPersonalInformationCategoryUpdates {
                FileService.shared.log("update the personal information categories in the background", classname: "PersonalInformationCategory")
                DispatchQueue.global(qos: .background).async {
                    PersonalInformationCategory.retrieveLatestPersonalInformationCategories()
                    Settings.saveLastPersonalInformationCategoryUpdate(with: Date())
                }
            }
        }
    }
}

