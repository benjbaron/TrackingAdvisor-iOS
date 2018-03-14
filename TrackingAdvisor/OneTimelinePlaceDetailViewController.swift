//
//  OneTimelinePlaceDetailViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/12/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class OneTimelinePlaceDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PersonalInformationCategoryCellDelegate, HeaderReviewVisitDelegate, DataStoreUpdateProtocol {
    
    private func presentEditVC() {
        let viewController = PlaceFinderMapTableViewController()
        viewController.visit = visit
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func presentAddPIVC(for cat: String?) {
        let viewController = PersonalInformationChooserViewController()
        viewController.color = color
        viewController.place = visit?.place
        viewController.visit = visit
        viewController.cat = cat
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func edit(_ sender: UIBarButtonItem) {
        presentEditVC()
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        UserUpdateHandler.sendReviewUpdate(reviews: updatedReviews)
        presentingViewController?.dismiss(animated: true)
    }
    
    var collectionView: UICollectionView!
    lazy var headerView: HeaderPlaceDetail = {
        return HeaderPlaceDetail()
    }()
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
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
            pics = personalInformation!.keys.sorted(by: { $0 < $1 })
            if collectionView != nil {
                collectionView.reloadData()
            }
        }
    }
    
    var personalInformation: [String: [PersonalInformation]]?
    var pics: [String]?
    var updatedReviews: [String:Int32] = [:]  // [reviewId : Answer]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        DataStoreService.shared.delegate = self
        
        setupNavBarButtons()
        updatedReviews.removeAll()
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        
        // Register cells types
        collectionView.register(PersonalInformationCategoryCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(HeaderPersonalInformationCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        
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
        
        collectionView.backgroundColor = UIColor.white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        
        self.view.addVisualConstraint("H:|[collection]|", views: ["collection" : collectionView])
        self.view.addVisualConstraint("V:|[header][collection]|", views: ["header" : headerView, "collection" : collectionView])
        
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
        
        guard let pi = personalInformation, let pics = pics else { return cell }
        let picid = pics[indexPath.item]
        cell.personalInformationCategory = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
        cell.personalInformation = pi[picid]
        cell.color = color
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 220)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! HeaderPersonalInformationCell
            headerCell.delegate = self
            headerCell.color = color
            if let count = personalInformation?.count {
                headerCell.hasPersonalInformation = count > 0
            }
            if let place = visit?.place {
                headerCell.coordinates = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            }
            if let answer = visit?.review?.answer {
                headerCell.setReviewAnswer(with: answer)
            }
            return headerCell
        } else {
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // From https://stackoverflow.com/questions/33402596/how-can-i-dynamically-resize-a-header-view-in-a-uicollectionview
        
        // 1 - instanciate a new header
        let headerView = HeaderPersonalInformationCell()
        if let answer = visit?.review?.answer {
            headerView.setReviewAnswer(with: answer)
        }
        
        // 2 - set the width through a constraint and layout the view
        headerView.addConstraint(NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: collectionView.frame.width))
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        // 3 - get the height
        let height = headerView.height()
        
        // 4 - return the correct size
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    // MARK: - PersonalInformationCategoryCellDelegate method    
    func reviewPersonalInformation(cat: String, personalInformation: PersonalInformation, answer: FeedbackType) {
        print("feedback from personal information \(personalInformation.name!): \(answer)")
        
        // TODO: save the feedback in the database
        personalInformation.rating = answer.rawValue
        if let piid = personalInformation.id {
            updatedReviews[piid] = answer.rawValue
            DataStoreService.shared.updatePersonalInformationRating(with: piid, rating: answer.rawValue) {
                print("reviewPersonalInformation for personal information \(personalInformation.name!) and rating \(answer)")
            }
        }
    }
    
    // MARK: - HeaderReviewVisitDelegate methods
    func didPressReviewVisit(with answer: ReviewAnswer) {
        if let review = visit?.review {
            review.answer = answer
            DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: answer)
        }
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
    }
    
    func didPressVisitEdit() {
        presentEditVC()
    }
    
    func didPressAddPersonalInformation() {
        presentAddPIVC(for: nil)
    }
    
    // MARK: DataStoreUpdateProtocol method
    func dataStoreDidUpdateReviewAnswer(for reviewId: String?, with answer: Int32) {
        if let reviewId = reviewId {
            updatedReviews[reviewId] = answer
        }
    }
    
    func dataStoreDidUpdate(for day: String?) {
        print("dataStoreDidUpdate -> reload data")
        
        if let vid = visit?.id {
            visit = DataStoreService.shared.getVisit(for: vid)
        }
    }
}

protocol HeaderReviewVisitDelegate {
    func didPressReviewVisit(with answer: ReviewAnswer)
    func didPressVisitEdit()
    func didPressAddPersonalInformation()
}

class HeaderPersonalInformationCell : UICollectionViewCell, MGLMapViewDelegate {
    var delegate: HeaderReviewVisitDelegate?
    var hasPersonalInformation: Bool = true { didSet {
        if !hasPersonalInformation {
            instructionsLabel.text = "We do not have any personal information for this place at the moment."
        } else {
            instructionsLabel.text = "Please validate the inferences using the marks on the cards presented below."
        }
        
    }}
    var color: UIColor = Constants.colors.orange {
        didSet {
            mapView.tintColor = color
            visitReviewView.textColor = color
            visitReviewView.backgroundColor = color.withAlphaComponent(0.3)
            instructionsLabel.textColor = color
            addPersonalInformationLabel.textColor = color
            addPersonalInformationLabel.backgroundColor = color.withAlphaComponent(0.3)
        }
    }
    var coordinates: CLLocationCoordinate2D? {
        didSet {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = coordinates!
            mapView.addAnnotation(annotation)
            mapView.centerCoordinate = coordinates!
        }
    }
    
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
    private lazy var instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Please validate the inferences using the marks on the cards presented below."
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textColor = color
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var visitReviewView: ReviewCardView = {
        let review = ReviewCardView(title: "Did you visit this place?", color: Constants.colors.primaryLight)
        let yesAction: ()->() = { [weak self] in
            self?.visitReviewView.selected = .yes
            self?.delegate?.didPressReviewVisit(with: .yes)
        }
        let noAction: ()->() = { [weak self] in
            self?.visitReviewView.selected = .no
            self?.delegate?.didPressReviewVisit(with: .no)
        }
        let commentAction: ()->() = { [weak self] in
            self?.delegate?.didPressVisitEdit()
        }
        review.questionView.unselectedColor = .white
        review.hideEdit()
        review.noAction = noAction
        review.yesAction = yesAction
        review.commentAction = commentAction
        return review
    }()
    
    private lazy var mapView: MGLMapView = {
        let map = MGLMapView(frame: .zero, styleURL: MGLStyle.lightStyleURL())
        map.delegate = self
        map.tintColor = color
        map.zoomLevel = 14
        map.attributionButton.alpha = 0
        map.layer.cornerRadius = 5.0
        map.backgroundColor = .white
        map.clipsToBounds = true
        map.layer.masksToBounds = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private lazy var addPersonalInformationLabel: UILabel = {
        let l = UILabel()
        l.layer.cornerRadius = 5.0
        l.layer.masksToBounds = true
        l.text = "Add personal information"
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.textColor = color
        l.backgroundColor = Constants.colors.superLightGray
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
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
        addSubview(visitReviewView)
        addSubview(mapView)
        addSubview(addPersonalInformationLabel)
        
        // add constraints
        addVisualConstraint("V:|-14-[map(125)]-14-[review]-14-[title][instructions]-14-[addPI(64)]-14-|", views: ["map": mapView, "review": visitReviewView, "title": titleLabel, "instructions": instructionsLabel, "addPI": addPersonalInformationLabel])
        addVisualConstraint("H:|-14-[map]-14-|", views: ["map" : mapView])
        addVisualConstraint("H:|-14-[review]-14-|", views: ["review": visitReviewView])
        addVisualConstraint("H:|-14-[title]-14-|", views: ["title": titleLabel])
        addVisualConstraint("H:|-14-[instructions]-14-|", views: ["instructions": instructionsLabel])
        addVisualConstraint("H:|-14-[addPI]-14-|", views: ["addPI": addPersonalInformationLabel])
        
        addPersonalInformationLabel.addTapGestureRecognizer { [weak self] in
            self?.addPersonalInformationLabel.alpha = 0.7
            self?.delegate?.didPressAddPersonalInformation()
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.addPersonalInformationLabel.alpha = 1
            }
        }
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 14 + mapView.bounds.height + 14 + visitReviewView.height() + 14 + titleLabel.bounds.height + instructionsLabel.bounds.height + 14 + addPersonalInformationLabel.bounds.height + 14
    }
    
    func setReviewAnswer(with answer: ReviewAnswer) {
        visitReviewView.selected = answer
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
}

