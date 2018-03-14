//
//  PlacePersonalInformationReviewViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/9/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

class PlacePersonalInformationReviewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DataStoreUpdateProtocol, PlacePersonalInformationReviewCategoryDelegate {
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
    var color = Constants.colors.orange
    
    func goBack() {
        guard let controllers = navigationController?.viewControllers else { return }
        let vc = controllers[0]
        navigationController?.popToViewController(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        DataStoreService.shared.delegate = self
        
        places = DataStoreService.shared.getAllPlacesToReview()
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
        
        places = DataStoreService.shared.getAllPlacesToReview()
        
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
        fullScreenView.buttonText = "Go back to the personal information"
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
            updateVisitAtPlace(with: currentPlace, visited: 1, at: indexPath) { [weak self] in
                if let count = self?.places.count, idx.item == count {
                    self?.showEndScreen()
                }
            }
        }
    }
    
    private func updateVisitAtPlace(with place: Place?, visited: Int32, at indexPath: IndexPath?, callback: (()->Void)? = nil) {
        // 0: none
        // 1: visited
        // 2: not visited
        
        if let place = place, let pid = place.id, let idx = indexPath, let visits = place.visits {
            DataStoreService.shared.updatePlaceReviewed(with: pid, reviewed: true)
            for case let visit as Visit in visits {
                if let vid = visit.id {
                    DataStoreService.shared.updateVisit(with: vid, visited: visited)
                }
            }
            
            self.updateVisited[pid] = visited
            self.places.remove(at: idx.item)
            self.placesStatus.remove(at: idx.item)
            
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [idx])
            }, completion: { completed in
                self.collectionView.reloadData()
                callback?()
            })
        }
    }
}

class PlacePersonalInformationReviewHeaderCell : UICollectionViewCell {
    
    private let mainTitle: UILabel = {
        let label = UILabel()
        label.text = "Personal information to review"
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
        
        addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        addVisualConstraint("V:|-48-[v0]", views: ["v0": mainTitle])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
