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


struct PlaceSearchResult: Codable {
    let street: String?
    let city: String?
    let places: [PlaceSearchResultDetail]
}

struct PlaceSearchResultDetail: Codable {
    let name: String
    let placeid: String
    let category: String
    let city: String
    let address: String
    let distance: Float
    let origin: String
    let longitude: Double
    let latitude: Double
}

enum VisitTimesEditType {
    case start
    case end
}

protocol VisitTimesEditDelegate {
    func didPress(visitTimesEditType: VisitTimesEditType)
}

class PlaceFinderMapTableViewController: UIViewController, MGLMapViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, VisitTimesEditDelegate {

    @objc func done(_ sender: Any) {
        // TODO: - save the changes and notify the backend server
        
        // quit the modal window
        view.endEditing(true)
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        
        guard let controllers = navigationController?.viewControllers else { return }
        let count = controllers.count
        if count == 2 {
            // get the previous place detail controller
            if let vc = controllers[0] as? OneTimelinePlaceDetailViewController {
                vc.visit = visit
                navigationController?.popToViewController(vc, animated: true)
            }
        } else if count == 1 {
            // return to the timeline
            presentingViewController?.dismiss(animated: true)
        }
    }
    
    @objc func deletePlace(_ sender: Any) {
        // TODO: - do a delete action and present a confirmation alert
        print("Clicked on the delete button")
    }
    
    var searchbarView: UISearchBar!
    var tableView: UITableView!
    var mapView: MGLMapView!
    lazy var headerView: HeaderPlace = {
        return HeaderPlace()
    }()
    lazy var startVisitTimesEditView: VisitTimesEditRow = {
        let vter = VisitTimesEditRow()
        vter.type = .start
        vter.textLabel.text = "Start time of the visit"
        vter.delegate = self
        return vter
    }()
    lazy var endVisitTimesEditView: VisitTimesEditRow = {
        let vter = VisitTimesEditRow()
        vter.type = .end
        vter.textLabel.text = "End time of the visit"
        vter.delegate = self
        return vter
    }()
    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle("Delete the place", for: .normal)
        button.setTitleColor(Constants.colors.darkRed, for: .normal)
        button.setTitleColor(Constants.colors.darkRed.withAlphaComponent(0.5), for: .highlighted)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let cellId = "locationSearchResultCell"
    
    // height constraints
    var mapHeightContraint: NSLayoutConstraint!
    var headerHeightConstraint: NSLayoutConstraint!
    var deleteButtonHeightConstraint: NSLayoutConstraint!
    
    var color = UIColor.white // TODO: Associate the color to a Place
    
    var visit: Visit? {
        didSet {
            color = UIColor.orange // TODO: Associate the color to a Place
            
            headerView.placeName = visit!.place?.name
            headerView.placeAddress = visit!.place?.formatAddressString()
            headerView.backgroundColor = color
            
            startVisitTimesEditView.date = visit!.arrival
            endVisitTimesEditView.date = visit!.departure
        }
    }
    
    var isAnimating: Bool = false
    var isFolded: Bool = false
    var isShowingStartDatePicker = false
    var isShowingEndDatePicker = false
    var searchActive: Bool = false
    var marker = UIImageView()
    var isFetchingFromServer = false
    var searchResult:PlaceSearchResult? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        // set up the navigation controller bar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        
        // set up the table view
        tableView = UITableView(frame: view.bounds)
        tableView.register(PlaceFinderTableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 50
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // set up the search bar controller
        searchbarView = UISearchBar(frame: view.bounds)
        searchbarView.placeholder = "Search for a place..."
        searchbarView.searchBarStyle = .minimal
        searchbarView.setShowsCancelButton(true, animated: true)
        searchbarView.returnKeyType = .done
        searchbarView.isTranslucent = true
        searchbarView.delegate = self
        searchbarView.translatesAutoresizingMaskIntoConstraints = false
        
        // set up the delete button
        deleteButton.addTarget(self, action: #selector(deletePlace), for: .touchUpInside)
        
        // set up the map view
        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.lightStyleURL())
        mapView.tintColor = color
        mapView.delegate = self
        mapView.zoomLevel = 15
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Center the map on the visit coordinates
        let coordinates = CLLocationCoordinate2D(latitude: (visit?.place?.latitude)!, longitude: (visit?.place?.longitude)!)
        mapView.centerCoordinate = coordinates
        
        // Enable keyboard notifications when showing and hiding the keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        setupViews()
    }
    
    func setupViews() {
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(done))
        saveButton.tintColor = Constants.colors.superLightGray
        self.navigationItem.rightBarButtonItem = saveButton
        
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "angle-left")!.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = Constants.colors.superLightGray
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        self.view.addSubview(startVisitTimesEditView)
        self.view.addSubview(endVisitTimesEditView)
        self.view.addSubview(deleteButton)
        self.view.addSubview(headerView)
        self.view.addSubview(mapView)
        self.view.addSubview(searchbarView)
        self.view.addSubview(tableView)
        
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": headerView])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": startVisitTimesEditView])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": endVisitTimesEditView])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": deleteButton])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": mapView])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": searchbarView])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": tableView])
        self.view.addVisualConstraint("V:|[header][start][end][delete(40@750)][map][search][table]|", views: ["header": headerView, "start": startVisitTimesEditView, "end": endVisitTimesEditView, "delete": deleteButton, "map": mapView, "search": searchbarView, "table": tableView])
        
        // set up the overlaying map marker
        marker = UIImageView(image: UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate))
        marker.tintColor = Constants.colors.primaryDark
        marker.contentMode = .scaleAspectFit
        mapView.addSubview(marker)
        marker.translatesAutoresizingMaskIntoConstraints = false
        let verticalConstraint = NSLayoutConstraint(item: marker, attribute: .centerY, relatedBy: .equal, toItem: mapView, attribute: .centerY, multiplier: 1, constant: 0)
        let horizontalConstraint = NSLayoutConstraint(item: marker, attribute: .centerX, relatedBy: .equal, toItem: mapView, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: marker, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 40)
        let heightConstraint = NSLayoutConstraint(item: marker, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 40)
        view.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
        
        // set up the constraints on the UI elements
        headerHeightConstraint = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        view.addConstraint(headerHeightConstraint)
        headerHeightConstraint.isActive = false
        
        mapHeightContraint = NSLayoutConstraint(item: mapView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)
        view.addConstraint(mapHeightContraint)
        mapHeightContraint.isActive = false
        
        deleteButtonHeightConstraint = NSLayoutConstraint(item: deleteButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        view.addConstraint(deleteButtonHeightConstraint)
        deleteButtonHeightConstraint.isActive = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - VisitTimesEditDelegate method
    
    func toggleStartDatePicker() {
        isAnimating = true
        if isShowingEndDatePicker {
            toggleEndDatePicker()
        }
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.isShowingStartDatePicker {
                strongSelf.startVisitTimesEditView.hideDatePicker()
            } else {
                strongSelf.startVisitTimesEditView.showDatePicker()
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
    
    func toggleEndDatePicker() {
        print("Touched toggleEndDatePicker")
        if isShowingStartDatePicker {
            toggleStartDatePicker()
        }
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.isShowingEndDatePicker {
                strongSelf.endVisitTimesEditView.hideDatePicker()
            } else {
                strongSelf.endVisitTimesEditView.showDatePicker()
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
    
    func didPress(visitTimesEditType: VisitTimesEditType) {
        print("didPress with \(visitTimesEditType)")
        switch visitTimesEditType {
        case .start:
            toggleStartDatePicker()
        case .end:
            toggleEndDatePicker()
        }
    }
    
    // MARK: - UITableViewDataSource delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let offset = (searchbarView.text ?? "") == "" ? 0 : 1
        if let places = searchResult?.places {
            return places.count+offset
        } else {
            return offset
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PlaceFinderTableViewCell
        let offset = (searchbarView.text ?? "") == "" ? 0 : 1
        guard let searchResult = searchResult else { return cell }
        if let searchText = searchbarView.text, offset == 1 && indexPath.row == 0  {
            // this is a user-custom place
            let formattedString = NSMutableAttributedString()
            formattedString
                .normal("Enter new place ")
                .bold("\(searchText)")
            cell.placeNameLabel.attributedText = formattedString
            cell.placeAddressLabel.text = "Near \(formatAddress(street: searchResult.street, city: searchResult.city))"
            cell.iconView.image = UIImage(named: "plus-circle")!.withRenderingMode(.alwaysTemplate)
            cell.iconView.tintColor = Constants.colors.primaryDark
            cell.iconView.contentMode = .scaleAspectFit
            cell.place = nil
            cell.name = searchText
            cell.city = searchResult.city
            cell.street = searchResult.street
        } else {
            // this is a search result place
            let place = searchResult.places[indexPath.row-offset]
            cell.placeNameLabel.text = place.name
            cell.placeAddressLabel.text = place.city
            cell.place = place
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? PlaceFinderTableViewCell {
            if let place = cell.place {
                print("clicked on cell \(place.name)")
                // select the place
                headerView.placeName = place.name
                headerView.placeAddress = formatAddress(street: place.address, city: place.city)
                mapView.centerCoordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            } else {
                if indexPath.row == 0 {
                    // select the new place
                    headerView.placeName = cell.name ?? ""
                    headerView.placeAddress = formatAddress(street: cell.street, city: cell.city)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            if isFolded {
                unfoldMapView()
            }
        }
            
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
            unfoldMapView()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
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
            (self.mapView.centerCoordinate.longitude == 0 && self.mapView.centerCoordinate.latitude == 0) {
            return
        }
        
        isFetchingFromServer = true
        
        let parameters: Parameters = [
            "userid": Settings.getUserId(),
            "lon": self.mapView.centerCoordinate.longitude,
            "lat": self.mapView.centerCoordinate.latitude,
            "query": searchText
        ]
        
        Alamofire.request(Constants.urls.placeAutcompleteURL, method: .get, parameters: parameters)
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        strongSelf.searchResult = try decoder.decode(PlaceSearchResult.self, from: data)
                        strongSelf.tableView.reloadData()
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
            strongSelf.mapHeightContraint.isActive = true
            strongSelf.deleteButtonHeightConstraint.isActive = true
//            strongSelf.headerHeightConstraint.isActive = true
            strongSelf.startVisitTimesEditView.hide()
            strongSelf.endVisitTimesEditView.hide()
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
        view.endEditing(true)
        isAnimating = true
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.mapHeightContraint.isActive = false
            strongSelf.deleteButtonHeightConstraint.isActive = false
//            strongSelf.headerHeightConstraint.isActive = false
            strongSelf.startVisitTimesEditView.show()
            strongSelf.endVisitTimesEditView.show()
            strongSelf.view.layoutIfNeeded()
            }, completion: { [weak self] completed in
                if completed {
                    guard let strongSelf = self else { return }
                    strongSelf.isAnimating = false
                    strongSelf.isFolded = false
                }
        })
    }
    
    private func formatAddress(street: String?, city: String?) -> String {
        let addressString = street ?? ""
        let cityString = city ?? ""
        let sep = addressString != "" && cityString != "" ? ", " : ""
        return addressString + sep + cityString
    }

    // MARK: - Keyboard notifications
    @objc func keyboardWillShow(_ notification: NSNotification){
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        tableView.keyboardRaised(height: keyboardFrame.height)
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification){
        tableView.keyboardClosed()
    }
    
    // MARK: - MGLMapViewDelegate protocol
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        getPlaces(matching: searchbarView.text ?? "")
    }
}


class VisitTimesEditRow : UIView {
    
    var delegate:VisitTimesEditDelegate?
    var type: VisitTimesEditType?
    
    var date: Date? {
        didSet {
            dateLabel.text = DateHandler.dateToLetterAndPeriod(from: date!)
            
            datePicker.minimumDate = date!.startOfDay
            datePicker.maximumDate = date!.endOfDay
            datePicker.date = date!
        }
    }
    
    var textLabel: UILabel = {
        let label = UILabel()
        label.text = "Visit"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.primaryLight
        label.textAlignment = .left
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var dateLabel: UILabel = {
        let label = UILabel()
        label.text = "Visit date"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.primaryDark
        label.textAlignment = .right
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .time
        dp.addTarget(self, action: #selector(VisitTimesEditRow.datePickerValueChanged), for: .valueChanged)
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()
    
    var datePickerHeightConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        dateLabel.text = DateHandler.dateToLetterAndPeriod(from: sender.date)
        self.layoutIfNeeded()
    }

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
    
    func hideDatePicker() {
        datePicker.isHidden = true
        datePickerHeightConstraint.constant = 0
    }
    
    func showDatePicker() {
        datePicker.isHidden = false
        datePickerHeightConstraint.constant = 150
    }
    
    func hide() {
        hideDatePicker()
        heightConstraint.isActive = true
        dateLabel.alpha = 0
        textLabel.alpha = 0
    }
    
    func show() {
        heightConstraint.isActive = false
        dateLabel.alpha = 1
        textLabel.alpha = 1
    }

    func setupViews() {
        backgroundColor = .white
        
        addSubview(textLabel)
        addSubview(dateLabel)
        addSubview(datePicker)
        
        addVisualConstraint("V:|-(8@750)-[v0]", views: ["v0": textLabel])
        addVisualConstraint("H:|-[v0]", views: ["v0": textLabel])
        addVisualConstraint("V:|-(8@750)-[v0]", views: ["v0": dateLabel])
        addVisualConstraint("H:[v0]-|", views: ["v0": dateLabel])
        addVisualConstraint("V:[v0][v1]-(8@750)-|", views: ["v0": dateLabel, "v1": datePicker])
        
        datePickerHeightConstraint = NSLayoutConstraint(item: datePicker, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        datePicker.addConstraint(datePickerHeightConstraint)
        
        heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        addConstraint(heightConstraint)
        heightConstraint.isActive = false
        
        translatesAutoresizingMaskIntoConstraints = false
        
        addTapGestureRecognizer {
            self.delegate?.didPress(visitTimesEditType: self.type!)
        }
    }
}


class PlaceFinderTableViewCell: UITableViewCell {
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
    
    var place: PlaceSearchResultDetail?
    var name: String?
    var city: String?
    var street: String?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupViews() {
        addSubview(placeAddressLabel)
        addSubview(placeNameLabel)
        addSubview(iconView)
        
        // add constraints
        addVisualConstraint("V:|-5-[v0(30)]", views: ["v0": iconView])
        addVisualConstraint("H:|-[v0(30)]", views: ["v0": iconView])
        addVisualConstraint("V:|-5-[v0]", views: ["v0": placeNameLabel])
        addVisualConstraint("V:[v0][v1]", views: ["v0": placeNameLabel, "v1": placeAddressLabel])
        addVisualConstraint("H:[v0]-[v1]", views: ["v0": iconView, "v1": placeNameLabel])
        addVisualConstraint("H:[v0]-[v1]", views: ["v0": iconView, "v1": placeAddressLabel])
    }
}

