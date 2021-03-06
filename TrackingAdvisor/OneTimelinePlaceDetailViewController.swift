//
//  OneTimelinePlaceDetailViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/12/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class OneTimelinePlaceDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, PersonalInformationCellDelegate, HeaderReviewVisitDelegate, DataStoreUpdateProtocol {
    
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
        if let vid = visit?.id {
            LogService.shared.log(LogService.types.visitBack,
                                  args: [LogService.args.visitId: vid])
        }
        
        UserUpdateHandler.sendReviewUpdate(reviews: updatedReviews)
        guard let controllers = navigationController?.viewControllers else { return }
        if controllers.count == 2 {
            let vc = controllers[0]
            navigationController?.popToViewController(vc, animated: true)
        } else {
            presentingViewController?.dismiss(animated: true)
        }
    }
    
    var collectionView: UICollectionView!
    lazy var headerView: HeaderPlaceDetail = {
        return HeaderPlaceDetail()
    }()
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    let headerCategoryCellId = "HeaderCategoryCellId"
    var color = Constants.colors.orange { didSet {
        if collectionView != nil {
            collectionView.reloadData()
        }
    }}
    
    var vid: String! {
        didSet {
            visit = DataStoreService.shared.getVisit(for: vid, ctxt: nil)
        }
    }
    var visit: Visit? {
        didSet {
            guard let visit = visit, let place = visit.place else { return }
            headerView.placeName = place.name
            headerView.placeAddress = place.formatAddressString()
            headerView.placeTimes = visit.getTimesPhrase()
            color = place.getPlaceColor()
            headerView.backgroundColor = color
            personalInformation = place.getPersonalInformation()
            picids = personalInformation.keys.sorted(by: { $0 < $1 })
            if collectionView != nil {
                collectionView.reloadData()
            }
        }
    }
    
    var personalInformation: [String: [PersonalInformation]] = [:] {
        didSet {
            for (picid, pis) in personalInformation {
                personalInformation[picid] = pis.sorted(by: { $0.name ?? "" < $1.name ?? "" })
            }
        }
    }
    var picids: [String] = []
    var updatedReviews: [String:Int32] = [:]  // [reviewId : Answer]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        
        DataStoreService.shared.delegate = self
        
        visit = DataStoreService.shared.getVisit(for: vid, ctxt: nil)
        
        setupNavBarButtons()
        updatedReviews.removeAll()
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let vid = visit?.id {
            LogService.shared.log(LogService.types.visitAccess,
                                  args: [LogService.args.visitId: vid])
        }
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .white
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        
        // Register cells types
        collectionView.register(PlacePersonalInformationCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView.register(HeaderPersonalInformationCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        collectionView.register(HeaderCategoryPersonalInformationCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCategoryCellId)
        
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
        
        headerView.addTapGestureRecognizer { [weak self] in
            let viewController = PlaceEditViewController()
            viewController.place = self?.visit?.place
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
        
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return personalInformation.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            let picid = picids[section-1]
            return personalInformation[picid]?.count ?? 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PlacePersonalInformationCell
        
        let picid = picids[indexPath.section-1]
        cell.color = color
        cell.personalInformation = personalInformation[picid]?[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if indexPath.section == 0 {
                let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! HeaderPersonalInformationCell
                headerCell.delegate = self
                headerCell.color = color
                headerCell.hasPersonalInformation = personalInformation.count > 0
                if let place = visit?.place {
                    headerCell.coordinates = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                    headerCell.placeType = place.placetype
                }
                if let visited = visit?.visited {
                    headerCell.setVisited(with: visited)
                }
                return headerCell
            } else {
                let headerCategoryCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCategoryCellId, for: indexPath) as! HeaderCategoryPersonalInformationCell
                
                let picid = picids[indexPath.section-1]
                if let pic = PersonalInformationCategory.getPersonalInformationCategory(with: picid) {
                    headerCategoryCell.color = color
                    headerCategoryCell.name = pic.name
                    headerCategoryCell.icon = pic.icon
                }
                
                return headerCategoryCell
            }
            
        } else {
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // From https://stackoverflow.com/questions/33402596/how-can-i-dynamically-resize-a-header-view-in-a-uicollectionview
        
        if section == 0 {
            // 1 - instanciate a new header
            let headerView = HeaderPersonalInformationCell()
            if let visited = visit?.visited {
                headerView.setVisited(with: visited)
            }
            if let place = visit?.place {
                headerView.placeType = place.placetype
            }
            
            // 2 - set the width through a constraint and layout the view
            headerView.addConstraint(NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: collectionView.frame.width))
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()
            
            // 3 - get the height
            let height = headerView.height()
            
            // 4 - return the correct size
            return CGSize(width: collectionView.frame.width, height: height)
        } else {
            return CGSize(width: collectionView.frame.width, height: 50)
        }
        
    }
    
    
    // MARK: - HeaderReviewVisitDelegate methods
    func didPressReviewVisit(with answer: ReviewAnswer) {
        if let vid = visit?.id {
            DataStoreService.shared.updateVisit(with: vid, visited: answer.rawValue)
            visit?.visited = answer.rawValue
        }
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
    }
    
    func didPressPlaceType(with answer: Int32) {
        if let pid = visit?.place?.id {
            UserUpdateHandler.placeType(for: pid, placeType: answer) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.visit?.place?.placetype = answer
                strongSelf.collectionView.collectionViewLayout.invalidateLayout()
                strongSelf.collectionView.reloadData()
            }
        }
    }
    
    func didPressVisitEdit() {
        presentEditVC()
    }
    
    func didPressAddPersonalInformation() {
        presentAddPIVC(for: nil)
    }
    
    // MARK: - DataStoreUpdateProtocol methods
    func dataStoreDidUpdateReviewAnswer(for reviewId: String?, with answer: Int32) {
        if let reviewId = reviewId {
            updatedReviews[reviewId] = answer
        }
    }
    
    func dataStoreDidUpdate(for day: String?) {
        if let vid = vid {
            print("dataStoreDidUpdate")
            visit = DataStoreService.shared.getVisit(for: vid, ctxt: nil)
        }
    }
    
    func dataStoreDidResetContext() {
        if let vid = vid {
            print("didResetContext")
            visit = DataStoreService.shared.getVisit(for: vid, ctxt: nil)
        }
    }
    
    // MARK: - PersonalInformationCellDelegate methods
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: FeedbackType, indexPath: IndexPath?) {
        // save the feedback in the database
        personalInformation?.rating = answer.rawValue
        if let piid = personalInformation?.id {
            updatedReviews[piid] = answer.rawValue
            DataStoreService.shared.updatePersonalInformationRating(with: piid, rating: answer.rawValue)
            UserStats.shared.updatePlacePersonalInformation()
        }

    }
}

protocol HeaderReviewVisitDelegate {
    func didPressReviewVisit(with answer: ReviewAnswer)
    func didPressPlaceType(with answer: Int32)
    func didPressVisitEdit()
    func didPressAddPersonalInformation()
}

class HeaderCategoryPersonalInformationCell : UICollectionViewCell {
    var name: String? { didSet {
        titleLabel.text = name
    }}
    var icon: String? { didSet {
        iconView.icon = icon
        iconView.setNeedsDisplay()
    }}
    var color: UIColor = Constants.colors.orange { didSet {
        iconView.iconColor = color
    }}
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 1
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var iconView: IconView = {
        return IconView(icon: "user-circle", iconColor: color)
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
        addSubview(iconView)
        addVisualConstraint("H:|-14-[icon(25)]-[title]-14-|", views: ["icon": iconView, "title": titleLabel])
        addVisualConstraint("V:|-[v0]-|", views: ["v0": titleLabel])
        iconView.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        iconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
    }

}

class HeaderPersonalInformationCell : UICollectionViewCell, MGLMapViewDelegate {
    var delegate: HeaderReviewVisitDelegate?
    
    var placeType: Int32 = 0 { didSet {
        if placeType == 1 { // 1: Maybe home
            placeTypeView.title = "Set as home"
            placeTypeViewHeight?.isActive = false
        } else if placeType == 3 { // 3: Maybe work
            placeTypeView.title = "Set as work"
            placeTypeViewHeight?.isActive = false
        } else {
            placeTypeViewHeight?.isActive = true
        }
        setNeedsLayout()
    }}
    private var placeTypeViewHeight: NSLayoutConstraint?
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
            placeTypeView.color = color
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
        review.commentText = "It would be great if you could correct the place you visited"

        return review
    }()
    private lazy var placeTypeView: YesNoCardView = {
        let card = YesNoCardView(title: "Set as home", color: Constants.colors.primaryLight)
        let yesAction: ()->() = { [weak self] in
            if self?.placeType == 1 {
                self?.delegate?.didPressPlaceType(with: 2) // 2: Home
            } else if self?.placeType == 3 {
                self?.delegate?.didPressPlaceType(with: 4) // 4: Work
            }
        }
        let noAction: ()->() = { [weak self] in
            self?.delegate?.didPressPlaceType(with: 0) // 0: None
        }
        card.noAction = noAction
        card.yesAction = yesAction
        
        return card
    }()
    
    private lazy var mapView: MGLMapView = {
        let map = MGLMapView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), styleURL: MGLStyle.lightStyleURL)
        map.delegate = self
        map.tintColor = color
        map.zoomLevel = 14
        map.attributionButton.alpha = 0
        map.allowsRotating = false
        map.allowsTilting = false
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
        addSubview(placeTypeView)
        addSubview(mapView)
        addSubview(addPersonalInformationLabel)
        
        // add constraints
        addVisualConstraint("V:|-14-[map(125)]-14-[review]-14-[type]-14-[title][instructions]-14-[addPI(64)]-14-|", views: ["map": mapView, "review": visitReviewView, "type": placeTypeView, "title": titleLabel, "instructions": instructionsLabel, "addPI": addPersonalInformationLabel])
        addVisualConstraint("H:|-14-[map]-14-|", views: ["map" : mapView])
        addVisualConstraint("H:|-14-[review]-14-|", views: ["review": visitReviewView])
        addVisualConstraint("H:|-14-[type]-14-|", views: ["type": placeTypeView])
        addVisualConstraint("H:|-14-[title]-14-|", views: ["title": titleLabel])
        addVisualConstraint("H:|-14-[instructions]-14-|", views: ["instructions": instructionsLabel])
        addVisualConstraint("H:|-14-[addPI]-14-|", views: ["addPI": addPersonalInformationLabel])
        
        placeTypeViewHeight = NSLayoutConstraint(item: placeTypeView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        placeTypeViewHeight?.isActive = true
        
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
        var height = 14 + mapView.bounds.height + 14 + visitReviewView.height()  + 14 + titleLabel.bounds.height + 14 + addPersonalInformationLabel.bounds.height + 28
        
        if let instructionText = instructionsLabel.text {
            height += instructionText.height(withConstrainedWidth: frame.width - 28,
                                                           font: instructionsLabel.font)
        }
        
        if placeType == 1 || placeType == 3 {
            height += 50 + 14 // add the placeTypeView
        }
        
        return height
    }
    
    func setVisited(with visited: Int32) {
        visitReviewView.selected = ReviewAnswer(rawValue: visited)!
        UserStats.shared.updateVisitConfirmed()
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

class PlacePersonalInformationCell : UICollectionViewCell {
    var indexPath: IndexPath?
    var delegate: PersonalInformationCellDelegate?
    var personalInformation: PersonalInformation? { didSet {
        if let pi = personalInformation {
            nameLabel.text = pi.name
            if let f = FeedbackType(rawValue: pi.rating) {
                feedback = f
            }
        }
    }}
    
    var color: UIColor = Constants.colors.orange { didSet {
        feedbackView.selectedColor = color
        feedbackView.unselectedColor = color.withAlphaComponent(0.3)
    }}
    
    var feedback: FeedbackType = .none { didSet {
        feedbackView.selectedFeedback = feedback
    }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.italicSystemFont(ofSize: 16.0)
        label.textColor = .black
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var feedbackView: FeedbackRowCondensed = {
        let row = FeedbackRowCondensed(onChange: { [weak self] feedback in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didPressPersonalInformationReview(personalInformation: strongSelf.personalInformation, answer: feedback, indexPath: strongSelf.indexPath)
        })
        row.selectedFeedback = feedback
        row.selectedColor = color
        row.unselectedColor = color.withAlphaComponent(0.3)
        return row
    }()
    
    private func setupViews() {
        addSubview(nameLabel)
        addSubview(feedbackView)
        addVisualConstraint("H:|-14-[name][feedback(106)]-14-|", views: ["name": nameLabel, "feedback": feedbackView])
        nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        feedbackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}



