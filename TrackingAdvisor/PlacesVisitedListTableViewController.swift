//
//  PlacesVisitedListTableViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/10/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

class PlacesVisitedListTableViewController: UITableViewController, DataStoreUpdateProtocol {
    
    var places: [Place] = [] { didSet {
        print("number of places: \(places.count)")
        tableView.reloadData()
    }}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DataStoreService.shared.delegate = self
        
        places = DataStoreService.shared.getAllPlaces(ctxt: nil).filter({ $0.numberOfVisitsConfirmed > 0 }).sorted(by: { $0.numberOfVisitsConfirmed > $1.numberOfVisitsConfirmed })
        
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 70
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "placeVisitedCell", for: indexPath) as? PlaceVisitedTableViewCell {
        
            cell.place = places[indexPath.item]

            return cell
        }
        
        return UITableViewCell()
    }
    
    // MARK: - DataStoreUpdateProtocol methods
    func dataStoreDidUpdate(for day: String?) {
        places = DataStoreService.shared.getAllPlaces(ctxt: nil).filter({ $0.numberOfVisitsConfirmed > 0 }).sorted(by: { $0.numberOfVisitsConfirmed > $1.numberOfVisitsConfirmed })
    }
    
}

class PlaceVisitedTableViewCell: UITableViewCell {
    
    var icon: String? {
        didSet {
            if let icon = icon {
                iconView.image = UIImage(named: icon)!.withRenderingMode(.alwaysTemplate)
            }
        }
    }
    
    var placeAddressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = Constants.colors.descriptionColor
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var placeNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var iconView: UIImageView = {
        let icon = UIImageView(image: UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate))
        icon.tintColor = Constants.colors.primaryLight
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    var placeDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = Constants.colors.descriptionColor
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var place: Place? { didSet {
        if let place = place {
            icon = place.icon
            placeNameLabel.text = place.name
            placeAddressLabel.text = place.formatAddressString()
            
            let nov = place.numberOfVisitsConfirmed
            let visitStr = nov > 2 ? "\(nov) times" : (nov == 2 ? "twice" : "once")
            placeDescriptionLabel.text = "You visited this place \(visitStr)."
        }
    }}
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        contentView.addSubview(placeAddressLabel)
        contentView.addSubview(placeDescriptionLabel)
        contentView.addSubview(placeNameLabel)
        contentView.addSubview(iconView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        // add constraints
        contentView.addVisualConstraint("V:|-10-[v0(25)]", views: ["v0": iconView])
        contentView.addVisualConstraint("H:|-[v0(25)]", views: ["v0": iconView])
        contentView.addVisualConstraint("V:|-10-[v0]", views: ["v0": placeNameLabel])
        contentView.addVisualConstraint("V:[v0][v1][v2]", views: ["v0": placeNameLabel, "v1": placeAddressLabel, "v2": placeDescriptionLabel])
        contentView.addVisualConstraint("H:[v0]-10-[v1]|", views: ["v0": iconView, "v1": placeNameLabel])
        contentView.addVisualConstraint("H:[v0]-10-[v1]|", views: ["v0": iconView, "v1": placeAddressLabel])
        contentView.addVisualConstraint("H:[v0]-10-[v1]|", views: ["v0": iconView, "v1": placeDescriptionLabel])
    }
}
