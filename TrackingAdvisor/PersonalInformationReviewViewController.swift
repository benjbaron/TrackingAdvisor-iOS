//
//  PersonalInformationReviewViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/8/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import Alamofire

class PersonalInformationReviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DataStoreUpdateProtocol, PersonalInformationReviewCategoryDelegate, PersonalInformationReviewHeaderCellDelegate {
    
    var fullScreenView: FullScreenView?
    var pics: [String]! = []
    var personalInformation: [String: Set<AggregatedPersonalInformation>]! = [:]
    var aggregatedPersonalInformation: [AggregatedPersonalInformation]! = [] {
        didSet {
            if aggregatedPersonalInformation.count > 0 {
                personalInformation.removeAll()
                for pi in aggregatedPersonalInformation {
                    if let pic = pi.category {
                        if personalInformation[pic] == nil {
                            personalInformation[pic] = Set()
                        }
                        personalInformation[pic]!.insert(pi)
                    }
                }
                
                pics = personalInformation!.keys.sorted(by: { $0 < $1 })
                self.fullScreenView?.removeFromSuperview()
                if collectionView == nil {
                    self.setupViews()
                }
                collectionView.reloadData()
            }
        }
    }
    var updatedReviews: [String:[Int32]] = [:]  // [personalinformationid : [PersonalInformationReviewType:Rating]]
    var placesToReview: Bool = false
    
    var collectionView: UICollectionView!
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    var color = Constants.colors.orange
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        aggregatedPersonalInformation = DataStoreService.shared.getAllAggregatedPersonalInformation()
        
        UserUpdateHandler.retrieveLatestAggregatedPersonalInformation { [weak self] in
            // show if view is visible
            if self?.viewIfLoaded?.window != nil {
                self?.aggregatedPersonalInformation = DataStoreService.shared.getAllAggregatedPersonalInformation(sameContext: true)
            }
        }
        
        DataStoreService.shared.delegate = self
        
        updatedReviews.removeAll()
        if collectionView != nil {
            collectionView.reloadData()
        }
                
        let places = DataStoreService.shared.getAllPlacesToReview(sameContext: true)
        self.placesToReview = places.count > 0 ? true : false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if updatedReviews.count > 0 {
            UserUpdateHandler.sendPersonalInformationReviewUpdate(reviews: updatedReviews)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if personalInformation.count == 0 {
            fullScreenView = FullScreenView(frame: view.frame)
            fullScreenView!.icon = "rocket"
            fullScreenView!.iconColor = Constants.colors.primaryLight
            fullScreenView!.headerTitle = "Personal information to review"
            fullScreenView!.subheaderTitle = "After moving to a few places, we will ask you to review some personal information we have inferred from the places you visited."
            view.addSubview(fullScreenView!)
        } else {
            fullScreenView?.removeFromSuperview()
            setupViews()
        }
    }
    
    func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        
        // Register cells types
        collectionView.register(PersonalInformationReviewCategory.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(PersonalInformationReviewHeaderCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        
        let margins = self.view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: margins.topAnchor)
        ])
        self.view.addVisualConstraint("H:|[collection]|", views: ["collection" : collectionView])
        self.view.addVisualConstraint("V:[collection]|", views: ["collection" : collectionView])
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = personalInformation?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PersonalInformationReviewCategory
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationReviewCategory
        
        guard let pi = personalInformation, let pics = pics else { return cell }
        let picid = pics[indexPath.item]
        cell.personalInformationCategory = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
        
        cell.personalInformation = Array(pi[picid]!)
        cell.color = color
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 400)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! PersonalInformationReviewHeaderCell
            headerCell.delegate = self
            headerCell.placesToReview = self.placesToReview
            return headerCell
        } else {
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // 4 - return the correct size
        return CGSize(width: collectionView.frame.width, height: 250)
    }

    
    // MARK: - PersonalInformationReviewCategoryDelegate method
    func personalInformationReview(cat: String, personalInformation: AggregatedPersonalInformation, type: ReviewType, rating: Int32) {
        
        if let piid = personalInformation.id {
            DataStoreService.shared.updatePersonalInformationReview(with: piid, type: type, rating: rating) { [weak self] allRatings in
                self?.updatedReviews[piid] = allRatings
            }
        }
    }
    
    func explanationFeedback(cat: String, personalInformation: AggregatedPersonalInformation) {
        let viewController = ExplanationFeedbackViewController()
        viewController.personalInformation = personalInformation
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showPlaces(cat: String, personalInformation: AggregatedPersonalInformation) {
        print("show places")
        let overlayView = UIView()
        let frame = OverlayView.frame()
        overlayView.frame = CGRect(x: 0, y: 0, width: frame.width - 60, height: frame.height - 100)
        overlayView.center = CGPoint(x: frame.width / 2.0,
                                     y: frame.height / 2.0)
        overlayView.backgroundColor = .white
        overlayView.clipsToBounds = true
        overlayView.layer.cornerRadius = 10
//        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        let placeListView = ArggregatedParsonalInformationPlaceListView()
        overlayView.addSubview(placeListView)
        overlayView.addVisualConstraint("H:|[v0]|", views: ["v0": placeListView])
        overlayView.addVisualConstraint("V:|[v0]|", views: ["v0": placeListView])
        
        OverlayView.shared.showOverlay(with: overlayView)
    }
    
    // MARK: - PersonalInformationReviewHeaderCellDelegate method {
    func didPressReviewLatestPersonalInformation() {
        let viewController = PlacePersonalInformationReviewViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}

@objc protocol PersonalInformationReviewHeaderCellDelegate {
    @objc optional func didPressReviewLatestPersonalInformation()
}

class PersonalInformationReviewHeaderCell : UICollectionViewCell {
    var delegate: PersonalInformationReviewHeaderCellDelegate?
    var placesToReview: Bool = false {
        didSet {
            setColor()
        }
    }
    
    var color: UIColor = Constants.colors.midPurple {
        didSet {
            setColor()
        }
    }
    
    func setColor() {
        if placesToReview {
            placesToReviewButton.setTitle("You have places to review", for: .normal)
            placesToReviewButton.setTitleColor(.white, for: .normal)
            placesToReviewButton.backgroundColor = color
        } else {
            placesToReviewButton.setTitle("There are no places to review", for: .normal)
            placesToReviewButton.setTitleColor(color, for: .normal)
            placesToReviewButton.backgroundColor = color.withAlphaComponent(0.3)
        }
    }
    
    @objc fileprivate func tappedPlacesToReview() {
        if placesToReview {
            delegate?.didPressReviewLatestPersonalInformation?()
        }
    }
    
    private lazy var placesToReviewButton: UIButton = {
        let l = UIButton(type: .system)
        l.layer.cornerRadius = 5.0
        l.layer.masksToBounds = true
        l.setTitle("You have places to review", for: .normal)
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.titleLabel?.textColor = .white
        l.backgroundColor = color
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedPlacesToReview), for: .touchUpInside)
        return l
    }()
    
    private let mainTitle: UILabel = {
        let label = UILabel()
        label.text = "Summary of your personal information"
        label.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        label.textColor = Constants.colors.black
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
        addSubview(mainTitle)
        addSubview(placesToReviewButton)
        
        addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": placesToReviewButton])
        addVisualConstraint("V:|-48-[v0]-14-[v1(64)]", views: ["v0": mainTitle, "v1": placesToReviewButton])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

class ArggregatedParsonalInformationPlaceListView : UIView {
    lazy var headerView: HeaderPlace = {
        let header = HeaderPlace()
        header.backgroundColor = color
        return header
    }()
    
    var color: UIColor = Constants.colors.orange {
        didSet {
            headerView.backgroundColor = color
        }
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
    
    func setupViews() {
        addSubview(headerView)
        
        addVisualConstraint("H:|[v0]|", views: ["v0": headerView])
        addVisualConstraint("V:|[v0]", views: ["v0": headerView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

