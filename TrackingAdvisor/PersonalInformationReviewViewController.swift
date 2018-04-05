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
    
    func goBack() {
        guard let controllers = navigationController?.viewControllers else { return }
        let vc = controllers[controllers.count - 2]
        navigationController?.popToViewController(vc, animated: true)
    }
    
    var fullScreenView: FullScreenView?
    var pics: [String]! = [] { didSet {
        for _ in pics {
            picStatus.append(-1)
        }
    }}
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
    var picStatus: [Int] = [] // PIC index
    
    var collectionView: UICollectionView!
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    var color = Constants.colors.orange
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        aggregatedPersonalInformation = DataStoreService.shared.getAggregatedPersonalInformationToReview(sameContext: true)
        
        // update with the latest
        UserUpdateHandler.retrieveLatestAggregatedPersonalInformation { [weak self] in
            // show if view is visible
            if self?.viewIfLoaded?.window != nil {
                self?.aggregatedPersonalInformation = DataStoreService.shared.getAggregatedPersonalInformationToReview(sameContext: true)
            }
        }
        
        DataStoreService.shared.delegate = self
        
        updatedReviews.removeAll()
        if collectionView != nil {
            collectionView.reloadData()
        }
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
        return pics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PersonalInformationReviewCategory
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationReviewCategory
        
        guard let pi = personalInformation else { return cell }
        let picid = pics[indexPath.item]
        cell.personalInformationCategory = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
        
        cell.personalInformation = Array(pi[picid]!)
        cell.color = color
        cell.delegate = self
        cell.indexPath = indexPath
        cell.lastPI = indexPath.item+1 == pics.count
        cell.status = picStatus[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 350)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! PersonalInformationReviewHeaderCell
            headerCell.delegate = self
            headerCell.color = color
            return headerCell
        } else {
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // 4 - return the correct size
        return CGSize(width: collectionView.frame.width, height: 175)
    }

    
    // MARK: - PersonalInformationReviewCategoryDelegate method
    func personalInformationReview(cat: String, personalInformation: AggregatedPersonalInformation, type: ReviewType, rating: Int32, picIndexPath: IndexPath, personalInformationIndexPath: IndexPath) {
        
        if let piid = personalInformation.id {
            picStatus[picIndexPath.item] = personalInformationIndexPath.item
            
            DataStoreService.shared.updatePersonalInformationReview(with: piid, type: type, rating: rating) { [weak self] allRatings in
                self?.updatedReviews[piid] = allRatings
            }
        }
    }
    
    func explanationFeedback(cat: String, personalInformation: AggregatedPersonalInformation) {
        
        OverlayView.shared.hideOverlayView()
        let viewController = ExplanationFeedbackViewController()
        viewController.personalInformation = personalInformation
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showPlaces(cat: String, personalInformation: AggregatedPersonalInformation, picIndexPath: IndexPath, personalInformationIndexPath: IndexPath) {
        let overlayView = AggregatedPersonalInformationExplanationOverlayView()
        overlayView.color = color
        overlayView.picIndexPath = picIndexPath
        overlayView.indexPath = personalInformationIndexPath
        overlayView.delegate = self
        overlayView.picid = cat
        overlayView.aggregatedPersonalInformation = personalInformation
        OverlayView.shared.showOverlay(with: overlayView)
    }
    
    func goToNextPersonalInformation(currentPersonalInformation: AggregatedPersonalInformation?, picIndexPath: IndexPath?, personalInformationIndexPath: IndexPath?) {
        if let picIdx = picIndexPath, let piIdx = personalInformationIndexPath {
            picStatus[picIdx.item] = piIdx.item
        }
    }
    
    func goToNextPersonalInformationCategory(picIndexPath: IndexPath?) {
        if let idx = picIndexPath {
            self.picStatus.remove(at: idx.item)
            self.pics.remove(at: idx.item)
            
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [idx])
            }, completion: { [weak self] completed in
                self?.collectionView.reloadData()
                
                if let count = self?.pics.count, idx.item == count {
                    self?.showEndScreen()
                }
            })
        }
        
    }
    
    // MARK: - PersonalInformationReviewHeaderCellDelegate method {
    func didPressBackButton() {
        goBack()
    }
    
    func showEndScreen() {
        let fullScreenView = FullScreenView(frame: view.frame)
        fullScreenView.icon = "galaxy"
        fullScreenView.iconColor = Constants.colors.primaryLight
        fullScreenView.headerTitle = "You're all set!"
        fullScreenView.subheaderTitle = "Thank you for reviewing the personal information"
        fullScreenView.buttonText = "Go back to your reviews"
        fullScreenView.buttonAction = { [weak self] in
            self?.goBack()
        }
        view.addSubview(fullScreenView)
    }
}

@objc protocol PersonalInformationReviewHeaderCellDelegate {
    @objc optional func didPressBackButton()
}

class PersonalInformationReviewHeaderCell : UICollectionViewCell {
    var delegate: PersonalInformationReviewHeaderCellDelegate?
    
    @objc fileprivate func tappedBackButton() {
        delegate?.didPressBackButton?()
    }
    
    var color: UIColor = Constants.colors.orange { didSet {
        backButton.tintColor = color
        backButton.setTitleColor(color, for: .normal)
    }}
    
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
    
    private let mainTitle: UILabel = {
        let label = UILabel()
        label.text = "Personal information review"
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
        addSubview(backButton)
        
        addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        addVisualConstraint("H:|-14-[v0(75)]", views: ["v0": backButton])
        addVisualConstraint("V:|-20-[v1(40)][v0]", views: ["v0": mainTitle, "v1": backButton])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
