//
//  LocationViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 10/25/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import CoreData

class LocationTableViewController: UITableViewController {
    
    @IBAction func deleteAllLocations(_ sender: Any) {
        // Display an alert to warn the user
        print("Clicked Delete All")
        let alertController = UIAlertController(title: "Delete all", message: "This will delete all the locations recorded", preferredStyle: UIAlertControllerStyle.alert)
        
        let deleteAllAction = UIAlertAction(title: "Delete all",
                                            style: UIAlertActionStyle.destructive) {
            (result : UIAlertAction) -> Void in
            print("Delete all -- proceed")
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            
            do {
                try managedContext.execute(request)
                try managedContext.save()
                self.locations.removeAll()
                self.tableView.reloadData()
                print("Done -- deleted the locations")
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            (result : UIAlertAction) -> Void in
            print("Canacel delete all")
        }
        
        alertController.addAction(deleteAllAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)

    }
    
    
    // MARK:  - Model
    var locations: [[Location]] = []
    var dates: Dictionary<String,Int> = [:]
    
    private lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE, dd MMM yyyy"
        return df
    }()
    
    // MARK: - UITableViewDataSource methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        print("numberOfSections \(locations.count)")
        return locations.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRowsInSection \(section): \(locations[section].count)")
        return locations[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "locationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        // configure the cell
        let location = locations[indexPath.section][indexPath.row]
        if let locationCell = cell as? LocationCell {
            locationCell.location = location
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        for (date, index) in dates {
            if index == section {
                return date
            }
        }
        return ""
    }
    
    // MARK: - View Controller lifecycle
    private func observe() {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(contextObjectsDidChange(_:)),
                           name: Notification.Name.NSManagedObjectContextObjectsDidChange,
                           object: nil)
    }
    
    @objc func contextObjectsDidChange(_ notification: Notification) {
        print("\(String(describing: notification.userInfo))")
        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<Location>,
            !insertedObjects.isEmpty {
            let array = Array(insertedObjects)
            for loc in array {
                updateLocationModel(with: loc)
//                tableView.insertSections([0], with: .fade)
            }
//            locations += array
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the row height
        tableView.rowHeight = 64
        print("LocationView did load")
        observe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        do {
            let results = try managedContext.fetch(fetchRequest)
            let locationsList = results as! [Location]
            print("Locations retrieved: \(locationsList.count)")
            
            for loc in locationsList {
                updateLocationModel(with: loc)
            }
            print("Done -- loaded \(locations.count) sections")
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    deinit {
        let center = NotificationCenter.default
        center.removeObserver(self,
                              name: Notification.Name.NSManagedObjectContextObjectsDidChange,
                              object: nil)
    }
    
    
    // MARK - Private functions
    private func updateLocationModel(with location: Location) {
        if let ts = location.timestamp {
            let date = dateFormatter.string(from: ts)
            if let index = dates[date] {
                locations[index].append(location)
            } else {
                let index = dates.count
                dates[date] = index
                print("adding date \(date) at \(index) (\(locations.count))")
                locations.append([])
                locations[index].append(location)
            }
            
        }
    }
}
