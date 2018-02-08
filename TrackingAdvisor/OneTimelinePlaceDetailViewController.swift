//
//  OneTimelinePlaceDetailViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/12/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class OneTimelinePlaceDetailViewController: UIViewController, MGLMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PersonalInformationCategoryCellDelegate, FooterMoreInformationDelegate {
    
    @objc func edit(_ sender: UIBarButtonItem) {
        let viewController = PlaceFinderMapTableViewController()
        viewController.visit = visit
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    
    var mapView: MGLMapView!
    var collectionView: UICollectionView!
    lazy var headerView: HeaderPlaceDetail = {
        return HeaderPlaceDetail()
    }()
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    let footerCellId = "FooterCellId"
    var color = Constants.colors.orange
    
    var visit: Visit? {
        didSet {
            guard let visit = visit, let place = visit.place else { return }
            headerView.placeAddress = place.address
            headerView.placeName = place.name
            headerView.placeCity = place.city
            headerView.placeTimes = visit.getTimesPhrase()
            color = place.getPlaceColor()
            headerView.backgroundColor = color
            personalInformation = place.getPersonalInformation()
            print("place: \(place)")
        }
    }
    
    var personalInformation: [String: [PersonalInformation]]?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        setupNavBarButtons()
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        
        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.lightStyleURL())
        mapView.delegate = self
        mapView.tintColor = color
        mapView.zoomLevel = 15

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        
        // Register cells types
        collectionView.register(PersonalInformationCategoryCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(HeaderPersonalInformationCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        collectionView.register(FooterMoreInformationCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerCellId)
        
        // configure map
        let annotation = MGLPointAnnotation()
        let coordinates = CLLocationCoordinate2D(latitude: (visit?.place?.latitude)!, longitude: (visit?.place?.longitude)!)
        annotation.coordinate = coordinates
        annotation.title = visit?.place?.name
        mapView.addAnnotation(annotation)
        mapView.centerCoordinate = coordinates
        
        setupViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNavBarButtons() {
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        editButton.tintColor = Constants.colors.superLightGray
        self.navigationItem.rightBarButtonItem = editButton
        
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "angle-left")!.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = Constants.colors.superLightGray
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = leftBarButton

    }
    
    func setupViews() {
        self.view.addSubview(headerView)
        self.view.addVisualConstraint("H:|[header]|", views: ["header" : headerView])
        self.view.addVisualConstraint("V:|[header]", views: ["header" : headerView])
        
        mapView?.backgroundColor = .white
        mapView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mapView!)
        
        self.view.addVisualConstraint("H:|[map]|", views: ["map" : mapView!])
        self.view.addVisualConstraint("V:[header][map(150)]", views: ["header": headerView, "map" : mapView!])
        
        collectionView.backgroundColor = UIColor.white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        
        self.view.addVisualConstraint("H:|[collection]|", views: ["collection" : collectionView])
        self.view.addVisualConstraint("V:[map][collection]|", views: ["collection" : collectionView, "map": mapView])
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = personalInformation?.count {
            return count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PersonalInformationCategoryCell
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationCategoryCell
        
        guard let pi = personalInformation else { return cell }
        let picid = Array(pi.keys)[indexPath.item]
        cell.personalInformationCategory = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
        cell.personalInformation = pi[picid]
        cell.color = color
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 150)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! HeaderPersonalInformationCell
            return headerCell
        } else if kind == UICollectionElementKindSectionFooter {
            let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerCellId, for: indexPath) as! FooterMoreInformationCell
            footerCell.delegate = self
            footerCell.color = color
            return footerCell
        } else {
            assert(false, "Unexpected element kind")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // From https://stackoverflow.com/questions/33402596/how-can-i-dynamically-resize-a-header-view-in-a-uicollectionview
        
        // 1 - instanciate a new header
        let headerView = HeaderPersonalInformationCell()
        
        // 2 - set the width through a constraint and layout the view
        headerView.addConstraint(NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: collectionView.frame.width))
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        // 3 - get the height
        let height = headerView.height()
        
        // 4 - return the correct size
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 45)
    }

    
    // MARK: - MGLMapViewDelegate delegate methods
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        let reuseIdentifier = "map-marker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

        if annotationView == nil {
            let marker = UIImageView(image: UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate))
            marker.tintColor = color
            marker.contentMode = .scaleAspectFit
            marker.clipsToBounds = true
            marker.translatesAutoresizingMaskIntoConstraints = false
            
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            annotationView?.addSubview(marker)
            
            // add constraints
            let verticalConstraint = NSLayoutConstraint(item: marker, attribute: .centerY, relatedBy: .equal, toItem: annotationView, attribute: .centerY, multiplier: 1, constant: 0)
            let horizontalConstraint = NSLayoutConstraint(item: marker, attribute: .centerX, relatedBy: .equal, toItem: annotationView, attribute: .centerX, multiplier: 1, constant: 0)
            let widthConstraint = NSLayoutConstraint(item: marker, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 40)
            let heightConstraint = NSLayoutConstraint(item: marker, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 40)
            annotationView?.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
        }
        
        return annotationView
    }
    
    // MARK: - PersonalInformationCategoryCellDelegate method
    func addPersonalInformation(cat: String) {
        print("add a personal information for category \(cat)")
    }
    
    func reviewPersonalInformation(cat: String, personalInformation: PersonalInformation, answer: ReviewAnswer) {
        if let review = personalInformation.getReview(of: .personalInformation) {
            print("save review in the database with answer: \(answer.rawValue)")
            review.answer = answer
            DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: answer)
        }
        if let review = personalInformation.getReview(of: .explanation) {
            review.answer = .none
            DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .none)
        }
        if let review = personalInformation.getReview(of: .privacy) {
            review.answer = .none
            DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .none)
        }
    }
    
    // MARK: - FooterMoreInformationDelegate method
    func didPressMoreInformation() {
        let viewController = PlacePersonalInformationController()
        viewController.visit = visit
        navigationController?.pushViewController(viewController, animated: true)
    }
    
}

protocol FooterMoreInformationDelegate {
    func didPressMoreInformation()
}

class FooterMoreInformationCell: UICollectionViewCell {
    var delegate: FooterMoreInformationDelegate?
    var color: UIColor? {
        didSet {
            backgroundColor = color
            moreInformationLabel.textColor = .white
            moreInformationIcon.tintColor = .white
        }
    }
    var text: String? {
        didSet {
            moreInformationLabel.text = text
        }
    }
    private var moreInformationView: UIView!
    private let moreInformationLabel: UILabel = {
        let label = UILabel()
        label.text = "Get more information on how we inferred the personal information"
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let moreInformationIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "chevron-right")!.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = Constants.colors.black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        backgroundColor = .red
        addSubview(moreInformationLabel)
        addSubview(moreInformationIcon)
        addTapGestureRecognizer {
            self.delegate?.didPressMoreInformation()
        }
        
        moreInformationLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        moreInformationIcon.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)

        // setup constraints
        addVisualConstraint("H:|-14-[label]-[icon]-14-|", views: ["label": moreInformationLabel, "icon": moreInformationIcon])
        addVisualConstraint("V:|[label]|", views: ["label": moreInformationLabel])
        addVisualConstraint("V:|-[icon]-|", views: ["icon": moreInformationIcon])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 45
    }
}


class HeaderPersonalInformationCell : UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 25, weight: .heavy)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Please tap the squares to validate the inferences presented below"
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textColor = Constants.colors.primaryLight
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(titleLabel)
        addSubview(instructionsLabel)
        
        // add constraints
        addVisualConstraint("V:|-14-[title][instructions]-14-|", views: ["title": titleLabel, "instructions": instructionsLabel])
        
        addVisualConstraint("H:|-14-[title]-14-|", views: ["title": titleLabel])
        addVisualConstraint("H:|-14-[instructions]-14-|", views: ["instructions": instructionsLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 14 + titleLabel.bounds.height + instructionsLabel.bounds.height + 14
    }
}

