//
//  LocationCell.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 10/27/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import CoreData

class LocationCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var magnometerLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    var location: NSManagedObject? { didSet { updateUI() } }
    
    private func updateUI() {
        var coordinatesString = ""
        var magneticFieldString = ""
        var dateString = ""
        var typeString = ""
        
        if  let lat = location?.value(forKeyPath: "latitude") as? Double,
            let lon = location?.value(forKeyPath: "longitude") as? Double {
            
            coordinatesString = "(\(String(format:"%.6f", lat)), \(String(format:"%.6f", lon)))"
        }
        if  let magX = location?.value(forKeyPath: "magX") as? Double,
            let magY = location?.value(forKeyPath: "magY") as? Double,
            let magZ = location?.value(forKeyPath: "magZ") as? Double {
            
            magneticFieldString = "(\(String(format:"%.2f", magX)), \(String(format:"%.2f", magY)), \(String(format:"%.2f", magZ)))"
        }
        
        if let ts = location?.value(forKeyPath: "timestamp") as? Date {
            dateString = dateToSting(ts)
        }
        
        if let type = location?.value(forKey: "type") as? String {
            typeString = type
        }
        
        // set the label outlets
        locationLabel?.text = coordinatesString
        magnometerLabel?.text = magneticFieldString
        dateLabel?.text = dateString
        typeLabel?.text = typeString
    }
    
    
    // MARK - private utility functions
    
    private func dateToSting(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" // yyyy-MM-dd
        return formatter.string(from: date)
    }

}
