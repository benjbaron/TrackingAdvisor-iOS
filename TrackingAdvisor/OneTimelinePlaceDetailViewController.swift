//
//  OneTimelinePlaceDetailViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/12/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class OneTimelinePlaceDetailViewController: UIViewController, MGLMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBAction func edit(_ sender: UIBarButtonItem) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "PlaceFinderMapTableViewController") as? UINavigationController {
            if let viewController = controller.topViewController as? PlaceFinderMapTableViewController {
                viewController.visit = visit
                viewController.title = "Edit place"
                tabBarController?.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func back(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    
    @IBOutlet weak var map: MGLMapView?
    @IBOutlet weak var table: UITableView!
    var visit: Visit?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map?.delegate = self
        map?.zoomLevel = 15
        
        table.delegate = self
        table.dataSource = self
        
        self.title = visit?.place?.name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Timeline", style: .plain, target: nil, action: nil)
        
        // configure map
        let annotation = MGLPointAnnotation()
        let coordinates = CLLocationCoordinate2D(latitude: (visit?.place?.latitude)!, longitude: (visit?.place?.longitude)!)
        annotation.coordinate = coordinates
        annotation.title = visit?.place?.name
        map?.addAnnotation(annotation)
        map?.centerCoordinate = coordinates
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return visit?.place?.personalinfo?.keys.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let personalinfo = visit?.place?.personalinfo {
            let key = Array(personalinfo.keys)[section]
            print("numberOfRowsInSection \(section): \(Array(personalinfo.keys)[section].count) -- \(key)")
            return max(1, personalinfo[key]!.count)
        } else {
            return 1
        }
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let personalinfo = visit?.place?.personalinfo {
            return Array(personalinfo.keys)[section]
        } else {
            return ""
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeDetailPersonalInformationCell", for: indexPath)
        var text = "None"
        if let personalinfo = visit?.place?.personalinfo {
            let key = Array(personalinfo.keys)[indexPath.section]
            if personalinfo[key]!.count > 0 {
                text = (personalinfo[key]?[indexPath.row])!
            }
        }
        cell.textLabel?.text = text
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
