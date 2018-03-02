//
//  OneTimelinePlaceDetailViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/12/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class UnifiedPlaceInformationViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UnifiedPersonalInformationDelegate, DataStoreUpdateProtocol, MGLMapViewDelegate {
    
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
    
    var scrollView : UIScrollView!
    var contentView : UIView!
    
    var collectionView: UICollectionView!
    lazy var headerView: HeaderPlaceDetail = {
        return HeaderPlaceDetail()
    }()
    
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    var color = Constants.colors.orange { didSet {
        mapView.tintColor = color
        visitReviewView.textColor = color
        visitReviewView.backgroundColor = color.withAlphaComponent(0.3)
        addPersonalInformationLabel.textColor = color
        addPersonalInformationLabel.backgroundColor = color.withAlphaComponent(0.3)
    }}
    
    var visit: Visit? {
        didSet {
            guard let visit = visit, let place = visit.place else { return }
            headerView.placeAddress = place.address
            headerView.placeName = place.name
            headerView.placeCity = place.city
            headerView.placeTimes = visit.getTimesPhrase()
            color = place.getPlaceColor()
            headerView.backgroundColor = color
            coordinates = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            personalInformation = place.getPersonalInformation()
            pics = personalInformation!.keys.sorted(by: { $0 < $1 })
            if collectionView != nil {
                collectionView.reloadData()
            }
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
    
    var personalInformation: [String: [PersonalInformation]]?
    var pics: [String]?
    var updatedReviews: [String:Int32] = [:]  // [reviewId : Answer]
    
    private lazy var visitReviewView: ReviewCardView = {
        let review = ReviewCardView(title: "Did you visit this place?", color: Constants.colors.primaryLight)
        let yesAction: ()->() = { [weak self] in
            self?.visitReviewView.selected = .yes
            self?.didPressReviewVisit(with: .yes)
        }
        let noAction: ()->() = { [weak self] in
            self?.visitReviewView.selected = .no
            self?.didPressReviewVisit(with: .no)
        }
        let commentAction: ()->() = { [weak self] in
            self?.didPressVisitEdit()
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
        
        self.view.addSubview(headerView)
        
        scrollView = UIScrollView(frame: self.view.frame)
        scrollView.sizeToFit()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.white
        self.view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.white
        scrollView.addSubview(contentView)
        
        self.view.addVisualConstraint("H:|[header]|", views: ["header" : headerView])
        self.view.addVisualConstraint("H:|[scrollView]|", views: ["scrollView" : scrollView])
        self.view.addVisualConstraint("V:|[header][scrollView]|",  views: ["header": headerView, "scrollView" : scrollView])
        
        scrollView.addVisualConstraint("H:|[contentView]|", views: ["contentView" : contentView])
        scrollView.addVisualConstraint("V:|[contentView]|", views: ["contentView" : contentView])
        
        // make the width of content view to be the same as that of the containing view.
        self.view.addVisualConstraint("H:[contentView(==mainView)]", views: ["contentView" : contentView, "mainView" : self.view])
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .red
        
        // Register cells types
        collectionView.register(UnifiedPersonalInformationCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(UnifiedHeaderPersonalInformationCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        
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
        contentView.addSubview(visitReviewView)
        contentView.addSubview(mapView)
        contentView.addSubview(addPersonalInformationLabel)
        contentView.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // add constraints
        contentView.addVisualConstraint("V:|-14-[map(125)]-14-[review]-14-[addPI(64)]-14-[collection(500)]|", views: ["map": mapView, "review": visitReviewView,  "addPI": addPersonalInformationLabel, "collection": collectionView])
        contentView.addVisualConstraint("H:|-14-[map]-14-|", views: ["map" : mapView])
        contentView.addVisualConstraint("H:|-14-[review]-14-|", views: ["review": visitReviewView])
        contentView.addVisualConstraint("H:|-14-[addPI]-14-|", views: ["addPI": addPersonalInformationLabel])
        contentView.addVisualConstraint("H:|[collection]|", views: ["collection": collectionView])
        
        addPersonalInformationLabel.addTapGestureRecognizer { [weak self] in
            self?.addPersonalInformationLabel.alpha = 0.7
            self?.presentAddPIVC(for: nil)
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.addPersonalInformationLabel.alpha = 1
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let count = personalInformation?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let pi = personalInformation, let pics = pics {
            let category = pics[section]
            if let count = pi[category]?.count {
                return count
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UnifiedPersonalInformationCell
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UnifiedPersonalInformationCell
        
        guard let pi = personalInformation, let pics = pics else { return cell }
        let picid = pics[indexPath.section]
        if let piName = pi[picid]?[indexPath.item].name {
            cell.title = piName
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 150)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! UnifiedHeaderPersonalInformationCell
            headerCell.color = color
            guard let pics = pics else { return headerCell }
            let picid = pics[indexPath.section]
            if let category = PersonalInformationCategory.getPersonalInformationCategory(with: picid) {
                headerCell.title = category.name
                headerCell.subtitle = category.detail
                headerCell.icon = category.icon
            }
            return headerCell
        } else {
            assert(false, "Unexpected element kind")
        }        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: collectionView.frame.width, height: 150)
    }
    
    // MARK: - PersonalInformationCategoryCellDelegate method
    func addPersonalInformation(cat: String) {
        presentAddPIVC(for: cat)
    }
    
    func reviewPersonalInformation(cat: String, personalInformation: PersonalInformation, answer: ReviewAnswer) {
        if let review = personalInformation.getReview(of: .personalInformation) {
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

class UnifiedHeaderPersonalInformationCell : UICollectionViewCell {
    var title: String? {
        didSet {
            self.titleLabel.text = title
        }
    }
    var subtitle: String? {
        didSet {
            self.subtitleLabel.text = subtitle
        }
    }
    var color: UIColor = Constants.colors.orange {
        didSet {
            self.iconView.iconColor = color
            self.instructionsLabel.textColor = color
        }
    }
    var icon: String = "user-circle" {
        didSet {
            self.iconView.icon = icon
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Please give us feedback on the personal information inferences we made below."
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textColor = Constants.colors.primaryLight
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var iconView: IconView = {
        return IconView(icon: icon, iconColor: Constants.colors.primaryLight)
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel,subtitleLabel,instructionsLabel])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        addSubview(iconView)
        
        // add constraints
        addVisualConstraint("V:|-20-[stack]-|", views: ["stack": stackView])
        addVisualConstraint("V:|-20-[icon(30)]", views: ["icon": iconView])
        addVisualConstraint("H:|-14-[icon(30)]-[stack]-14-|", views: ["icon": iconView, "stack": stackView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 14 + titleLabel.bounds.height + subtitleLabel.bounds.height + instructionsLabel.bounds.height + 14
    }
    
}

protocol UnifiedPersonalInformationDelegate {
    func didPressReviewVisit(with answer: ReviewAnswer)
    func didPressVisitEdit()
    func didPressAddPersonalInformation()
}

class UnifiedPersonalInformationCell : UICollectionViewCell {
    var title: String = "title" { didSet {
        titleLabel.text = title
    }}
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(titleLabel)
        
        // add constraints
        addVisualConstraint("V:|-14-[title]-14-|", views: ["title": titleLabel])
        addVisualConstraint("H:|-14-[title]-14-|", views: ["title": titleLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 14 + titleLabel.bounds.height + 14
    }
    
}


