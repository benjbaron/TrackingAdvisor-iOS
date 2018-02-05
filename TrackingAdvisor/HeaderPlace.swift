//
//  HeaderPlace.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/22/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

class HeaderPlace: UIView {
    var placeName : String? {
        didSet {
            placeNameLabel.text = placeName
        }
    }
    var placeAddress : String? {
        didSet {
            placeAddressLabel.text = placeAddress
        }
    }
    
    internal let placeNameLabel: UILabel = {
        let label = UILabel()
        label.text = "place name"
        label.font = UIFont.systemFont(ofSize: 25, weight: .heavy)
        label.textColor = Constants.colors.white
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal let placeAddressLabel: UILabel = {
        let label = UILabel()
        label.text = "place address"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.superLightGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        addSubview(placeNameLabel)
        addSubview(placeAddressLabel)
        
        // add constraints
        addVisualConstraint("V:|-(28@750)-[title][address]-(18@750)-|", views: ["title": placeNameLabel, "address": placeAddressLabel])
        
        addVisualConstraint("H:|-75-[title]-75-|", views: ["title": placeNameLabel])
        addVisualConstraint("H:|-25-[address]-25-|", views: ["address": placeAddressLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

class HeaderPlaceDetail : HeaderPlace {
    var placeCity: String? {
        didSet {
            placeCityLabel.text = placeCity
        }
    }
    
    var placeTimes: String? {
        didSet {
            placeTimesLabel.text = placeTimes
        }
    }
    
    internal let placeCityLabel: UILabel = {
        let label = UILabel()
        label.text = "place city"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.superLightGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal let placeTimesLabel: UILabel = {
        let label = UILabel()
        label.text = "place times"
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textColor = Constants.colors.superLightGray
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func setupViews() {
        addSubview(placeNameLabel)
        addSubview(placeAddressLabel)
        addSubview(placeCityLabel)
        addSubview(placeTimesLabel)
        
        // add constraints
        addVisualConstraint("V:|-(28@750)-[title][address][city]-(12@750)-[times]-(18@750)-|", views: ["title": placeNameLabel, "address": placeAddressLabel, "city": placeCityLabel, "times": placeTimesLabel])
        
        addVisualConstraint("H:|-75-[title]-75-|", views: ["title": placeNameLabel])
        addVisualConstraint("H:|-25-[address]-25-|", views: ["address": placeAddressLabel])
        addVisualConstraint("H:|-25-[city]-25-|", views: ["city": placeCityLabel])
        addVisualConstraint("H:|-25-[times]-25-|", views: ["times": placeTimesLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

