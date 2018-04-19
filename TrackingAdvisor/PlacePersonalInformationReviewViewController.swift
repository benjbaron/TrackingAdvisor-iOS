//
//  PlacePersonalInformationReviewViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/9/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

class PlacePersonalInformationReviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DataStoreUpdateProtocol, PlacePersonalInformationReviewCategoryDelegate, PersonalInformationReviewHeaderCellDelegate {
    var places: [Place]! = [] {
        didSet {
            for _ in places {
                placesStatus.append(-2)
            }
        }
    }
    var updatedReviews: [String:Int32] = [:]  // [personalinformationid : Rating]
    var updateVisited: [String:Int32] = [:]   // [place : visited]
    var placesStatus: [Int] = [] // [Place index : index path info collection view]
    
    var collectionView: UICollectionView!
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    var color = Constants.colors.midPurple
    
    func goBack() {
        guard let controllers = navigationController?.viewControllers else { return }
        let vc = controllers[controllers.count - 2]
        navigationController?.popToViewController(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        DataStoreService.shared.delegate = self
        
        places = DataStoreService.shared.getAllPlacesToReview(ctxt: nil)
        updatedReviews.removeAll()
        if collectionView != nil {
            collectionView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        if updatedReviews.count > 0 {
            UserUpdateHandler.sendReviewUpdate(reviews: updatedReviews)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LogService.shared.log(LogService.types.reviewPlaces)
        
        places = DataStoreService.shared.getAllPlacesToReview(ctxt: nil)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        
        // Register cells types
        collectionView.register(PlacePersonalInformationReviewCategory.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(PlacePersonalInformationReviewHeaderCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        
        setupViews()
    }
    
    func setupViews() {
        UIApplication.shared.isStatusBarHidden = false
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PlacePersonalInformationReviewCategory
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PlacePersonalInformationReviewCategory
        
        let place = places[indexPath.item]
        cell.place = place
        cell.color = color
        cell.delegate = self
        cell.indexPath = indexPath
        cell.lastPlace = indexPath.item+1 == places.count
        cell.status = placesStatus[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 300)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! PlacePersonalInformationReviewHeaderCell
            headerCell.delegate = self
            headerCell.color = color
            headerCell.numberOfPlacesToReview = places.count
            return headerCell
        } else {
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // 4 - return the correct size
        return CGSize(width: collectionView.frame.width, height: 150)
    }
    
    
    // MARK: - PlacePersonalInformationReviewCategoryDelegate method
    func placePersonalInformationReview(place: Place?, personalInformation: PersonalInformation?, answer: FeedbackType, placeIndexPath: IndexPath, personalInformationIndexPath: IndexPath) {
        if let pi = personalInformation, let piid = pi.id {
            LogService.shared.log(LogService.types.reviewPlacesPi,
                                  args: [LogService.args.piId: piid,
                                         LogService.args.value: String(answer.rawValue)])
            
            placesStatus[placeIndexPath.item] = personalInformationIndexPath.item
            updatedReviews[piid] = answer.rawValue
            personalInformation?.rating = answer.rawValue
            DataStoreService.shared.updatePersonalInformationRating(with: piid, rating: answer.rawValue)
        }
    }
    
    func visitedPlace(placeIndexPath: IndexPath) {
        placesStatus[placeIndexPath.item] = -1
    }
    
    func showEndScreen() {
        let fullScreenView = FullScreenView(frame: view.frame)
        fullScreenView.icon = "galaxy"
        fullScreenView.iconColor = Constants.colors.primaryLight
        fullScreenView.headerTitle = "You're all set!"
        fullScreenView.subheaderTitle = "Thank you for reviewing the places"
        fullScreenView.buttonText = "Go back to your reviews"
        fullScreenView.buttonAction = { [weak self] in
            self?.goBack()
        }
        view.addSubview(fullScreenView)
    }
    
    func deletePlaceFromReviews(place: Place?, at indexPath: IndexPath?) {
        if let idx = indexPath {
            
            updateVisitAtPlace(with: place, visited: 2, at: indexPath) { [weak self] in
                if let count = self?.places.count, idx.item == count {
                    self?.showEndScreen()
                }
            }
        }
    }
    
    func goToNextPlace(currentPlace: Place?, indexPath: IndexPath?) {
        if let idx = indexPath {
            if let pid = currentPlace?.id {
                LogService.shared.log(LogService.types.reviewPlacesNext,
                                      args: [LogService.args.placeId: pid,
                                             LogService.args.value: String(idx.item),
                                             LogService.args.total: String(places.count)])
            }
            
            updateVisitAtPlace(with: currentPlace, visited: 1, at: indexPath) { [weak self] in
                if let count = self?.places.count, idx.item == count {
                    LogService.shared.log(LogService.types.reviewPlacesEndAll)
                    self?.showEndScreen()
                }
            }
        }
    }
    
    private func updateVisitAtPlace(with place: Place?, visited: Int32, at indexPath: IndexPath?, callback: (()->Void)? = nil) {
        // 0: none
        // 1: visited
        // 2: not visited
        
        if let place = place, let pid = place.id, let idx = indexPath {
            LogService.shared.log(LogService.types.reviewPlacesVisited,
                                  args: [LogService.args.placeId: pid,
                                         LogService.args.userChoice: String(visited)])
            
            DataStoreService.shared.updatePlaceReviewed(with: pid, reviewed: true)

            self.places.remove(at: idx.item)
            self.placesStatus.remove(at: idx.item)
            
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [idx])
            }, completion: { [weak self] completed in
                self?.collectionView.reloadData()
                callback?()
            })
        }
    }
    
    // MARK: - PersonalInformationReviewHeaderCellDelegate method {
    func didPressBackButton() {
        goBack()
    }
    
    // MARK: - DataStoreUpdateProtocol methods
    func dataStoreDidUpdateAggregatedPersonalInformation() {
        // get the latest aggregatedPersonalInformation
        places = DataStoreService.shared.getAllPlacesToReview(ctxt: nil)
    }
}

class PlacePersonalInformationReviewHeaderCell : UICollectionViewCell {
    
    var delegate: PersonalInformationReviewHeaderCellDelegate?
    var numberOfPlacesToReview: Int? {
        didSet {
            if numberOfPlacesToReview == 0 {
                subtitle.text = "You have no place to review"
            } else if numberOfPlacesToReview == 1 {
                subtitle.text = "You have one place to review"
            } else if let nb = numberOfPlacesToReview {
                subtitle.text = "You have \(nb) places to review"
            }
        }
    }
    
    @objc fileprivate func tappedBackButton() {
        delegate?.didPressBackButton?()
    }
    
    var color: UIColor = Constants.colors.midPurple { didSet {
        backButton.tintColor = color
        backButton.setTitleColor(color, for: .normal)
    }}
    
    private let mainTitle: UILabel = {
        let label = UILabel()
        label.text = "Place reviews"
        label.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitle: UILabel = {
        let label = UILabel()
        label.text = "You have XX places to review"
        label.font = UIFont.italicSystemFont(ofSize: 16.0)
        label.textColor = Constants.colors.lightGray
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var backButton: UIButton = {
        let l = UIButton(type: .system)
        l.setTitle("Back", for: .normal)
        l.contentHorizontalAlignment = .left
        l.setImage(UIImage(named: "angle-left")!.withRenderingMode(.alwaysTemplate), for: .normal)
        l.tintColor = color
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        l.setTitleColor(color, for: .normal)
        l.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -8)
        l.titleEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        l.backgroundColor = .clear
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedBackButton), for: .touchUpInside)
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
        addSubview(mainTitle)
        addSubview(subtitle)
        addSubview(backButton)
        
        addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        addVisualConstraint("H:|-16-[v0]-|", views: ["v0": subtitle])
        addVisualConstraint("H:|-14-[v0(75)]", views: ["v0": backButton])
        addVisualConstraint("V:|-20-[back(40)][title][subtitle]", views: ["title": mainTitle, "subtitle": subtitle, "back": backButton])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
