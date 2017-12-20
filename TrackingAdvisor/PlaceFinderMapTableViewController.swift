//
//  PlaceFinderMapTableViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/18/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox
import Alamofire


class PlaceFinderTableViewCell: UITableViewCell {
    @IBOutlet weak var placeAddress: UILabel!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var icon: UIImageView!
}

struct PlaceSearchResult: Codable {
    let name: String
    let placeid: String
    let category: String
    let city: String
    let distance: Float
    let origin: String
}

class PlaceFinderMapTableViewController: UIViewController, MGLMapViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBAction func done(_ sender: Any) {
        // TODO: - save the changes and notify the backend server
        
        // quit the modal window
        view.endEditing(true)
        presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func back(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func startDatePickerValueChanged(_ sender: UIDatePicker) {
        visitStartDate.text = DateHandler.dateToLetterAndPeriod(from: sender.date)
    }
    
    @IBAction func endDatePickerValueChanged(_ sender: UIDatePicker) {
        visitEndDate.text = DateHandler.dateToLetterAndPeriod(from: sender.date)
    }
    
    @IBOutlet weak var mapHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var map: MGLMapView!
    
    // IBOutlets for the visit identity view
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var visitStartDate: UILabel!
    @IBOutlet weak var visitEndDate: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var startDatePickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var startDateView: UIView!
    @IBOutlet weak var endDateView: UIView!
    @IBOutlet var visitIdentityHeightConstraint: NSLayoutConstraint!
    
    var visit: Visit?
    var isAnimating: Bool = false
    var isFolded: Bool = false
    var isShowingStartDatePicker = false
    var isShowingEndDatePicker = false
    var searchActive: Bool = false
    var marker = UIImageView()
    var isFetchingFromServer = false
    var places:[PlaceSearchResult] = []
    
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
        table.rowHeight = 50
        
        // set up the search bar controller
        searchbar.placeholder = "Search for a place..."
        searchbar.delegate = self
        
        // set up the visit identity view
        if let visit = visit {
            placeName.text = visit.place?.name
            visitStartDate.text = DateHandler.dateToLetterAndPeriod(from: visit.arrival!)
            visitStartDate.textColor = Constants.colors.primaryDark
            visitEndDate.text = DateHandler.dateToLetterAndPeriod(from: visit.departure!)
            visitEndDate.textColor = Constants.colors.primaryDark
        }
        visitIdentityHeightConstraint.isActive = false
        
        // set up the gesture recognizer to enable the start and end date pickers
        let startDatePickerGesture = UITapGestureRecognizer(target: self, action: #selector (self.toggleStartDatePicker (_:)))
        let endDatePickerGesture = UITapGestureRecognizer(target: self, action: #selector (self.toggleEndDatePicker(_:)))
        
        startDateView.addGestureRecognizer(startDatePickerGesture)
        endDateView.addGestureRecognizer(endDatePickerGesture)
        
        // set up the start and end date pickers
        if let visit = visit {
            startDatePicker.minimumDate = visit.arrival!.startOfDay
            startDatePicker.maximumDate = visit.arrival!.endOfDay
            startDatePicker.date = visit.arrival!
            
            endDatePicker.minimumDate = visit.departure!.startOfDay
            endDatePicker.maximumDate = visit.departure!.endOfDay
            endDatePicker.date = visit.departure!
        }
        startDatePicker.isHidden = true
        endDatePicker.isHidden = true
        
        // set up the overlaying map marker
        marker = UIImageView(image: UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate))
        marker.tintColor = Constants.colors.primaryDark
        marker.contentMode = .scaleAspectFit
        map.addSubview(marker)
        marker.translatesAutoresizingMaskIntoConstraints = false
        let verticalConstraint = NSLayoutConstraint(item: marker, attribute: .centerY, relatedBy: .equal, toItem: map, attribute: .centerY, multiplier: 1, constant: 0)
        let horizontalConstraint = NSLayoutConstraint(item: marker, attribute: .centerX, relatedBy: .equal, toItem: map, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: marker, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 40)
        let heightConstraint = NSLayoutConstraint(item: marker, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 40)
        view.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
        
        // Center the map on the visit coordinates
        let coordinates = CLLocationCoordinate2D(latitude: (visit?.place?.latitude)!, longitude: (visit?.place?.longitude)!)
        map?.centerCoordinate = coordinates
        
        // Enable keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDataSource delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationSearchResult", for: indexPath) as! PlaceFinderTableViewCell
        let place = places[indexPath.row]
        cell.placeName.text = place.name
        cell.placeAddress.text = place.city
        cell.icon.image = UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate)
        cell.icon.tintColor = Constants.colors.primaryLight
        cell.icon.contentMode = .scaleAspectFit
        return cell
    }
    
    // MARK: - UISearchBarDelegate Delegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        foldMapView()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.text = ""
        if isFolded {
            view.endEditing(true)
            unfoldMapView()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        view.endEditing(true)
        unfoldMapView()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count >= 3 {
            getPlaces(matching: searchText)
        } else if searchText.count == 0 {
            getPlaces(matching: "")
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let oldText = searchBar.text {
            let newText = (searchBar.text ?? "").replacingCharacters(in: Range(range, in: oldText)!, with: text)
            if oldText.count > newText.count && newText.count < 3 {
                getPlaces(matching: newText)
            }
        }
        return true
    }
    
    
    // MARK: - fetch search result from server
    private func getPlaces(matching searchText: String) {
        if isFetchingFromServer ||
            (self.map.centerCoordinate.longitude == 0 && self.map.centerCoordinate.latitude == 0) {
            return
        }
        
        isFetchingFromServer = true
        
        let parameters: Parameters = [
            "userid": Settings.getUserId(),
            "lon": self.map.centerCoordinate.longitude,
            "lat": self.map.centerCoordinate.latitude,
            "query": searchText
        ]
        
        Alamofire.request(Constants.urls.placeAutcompleteURL, method: .get, parameters: parameters)
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        strongSelf.places = try decoder.decode([PlaceSearchResult].self, from: data)
                        strongSelf.table.reloadData()
                    } catch {
                        print("Error serializing the json", error)
                    }
                }
                strongSelf.isFetchingFromServer = false
        }
    }
    
    
    // MARK: - Map view interactions
    private func foldMapView() {
        isAnimating = true
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.mapHeightContraint?.constant = 100
            strongSelf.visitIdentityHeightConstraint.isActive = true
//            strongSelf.marker.frame = mapHeightContraint.constant / 2 - strongSelf.marker.frame.height
            strongSelf.view.layoutIfNeeded()
            }, completion: { [weak self] completed in
                if completed {
                    guard let strongSelf = self else { return }
                    strongSelf.isAnimating = false
                    strongSelf.isFolded = true
                }
        })
    }
    
    private func unfoldMapView() {
        isAnimating = true
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.mapHeightContraint.constant = 250
            strongSelf.visitIdentityHeightConstraint.isActive = false
//            strongSelf.marker.frame.y = mapHeightContraint.constant / 2 - strongSelf.marker.frame.height
            strongSelf.view.layoutIfNeeded()
            }, completion: { [weak self] completed in
                if completed {
                    guard let strongSelf = self else { return }
                    strongSelf.isAnimating = false
                    strongSelf.isFolded = false
                }
        })
    }
    
    // MARK: - Touch actions for date pickers
    @objc func toggleStartDatePicker(_ sender: UITapGestureRecognizer) {
        print("Touched toggleStartDatePicker")
        isAnimating = true
        if isShowingEndDatePicker {
            toggleEndDatePicker(sender)
        }
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.isShowingStartDatePicker {
                strongSelf.startDatePicker.isHidden = true
                strongSelf.startDatePickerHeightConstraint.constant = 0
            } else {
                strongSelf.startDatePicker.isHidden = false
                strongSelf.startDatePickerHeightConstraint.constant = 150
            }
            strongSelf.view.layoutIfNeeded()
            }, completion: { [weak self] completed in
                if completed {
                    guard let strongSelf = self else { return }
                    strongSelf.isAnimating = false
                    strongSelf.isShowingStartDatePicker = !strongSelf.isShowingStartDatePicker
                }
        })
    }
    
    @objc func toggleEndDatePicker(_ sender: UITapGestureRecognizer) {
        print("Touched toggleEndDatePicker")
        if isShowingStartDatePicker {
            toggleStartDatePicker(sender)
        }
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.isShowingEndDatePicker {
                strongSelf.endDatePicker.isHidden = true
                strongSelf.endDatePickerHeightConstraint.constant = 0
            } else {
                strongSelf.endDatePicker.isHidden = false
                strongSelf.endDatePickerHeightConstraint.constant = 150
            }
            strongSelf.view.layoutIfNeeded()
            }, completion: { [weak self] completed in
                if completed {
                    guard let strongSelf = self else { return }
                    strongSelf.isAnimating = false
                    strongSelf.isShowingEndDatePicker = !strongSelf.isShowingEndDatePicker
                }
        })
    }

    // MARK: - Keyboard notifications
    @objc func keyboardWillShow(_ notification: NSNotification){
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        table.keyboardRaised(height: keyboardFrame.height)
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification){
        table.keyboardClosed()
    }
    
    // MARK: - MGLMapViewDelegate protocol
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        getPlaces(matching: searchbar.text ?? "")
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


extension UITableView {
    func keyboardRaised(height: CGFloat){
        self.contentInset.bottom = height
        self.scrollIndicatorInsets.bottom = height
    }
    
    func keyboardClosed(){
        self.contentInset.bottom = 0
        self.scrollIndicatorInsets.bottom = 0
        self.scrollRectToVisible(CGRect.zero, animated: true)
    }
}
