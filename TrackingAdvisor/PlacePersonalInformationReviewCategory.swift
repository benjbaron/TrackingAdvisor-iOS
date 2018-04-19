//
//  PlacePersonalInformationReviewCollectionView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/9/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit
import Mapbox


protocol PlacePersonalInformationReviewCategoryDelegate {
    func placePersonalInformationReview(place: Place?, personalInformation: PersonalInformation?, answer: FeedbackType, placeIndexPath: IndexPath, personalInformationIndexPath: IndexPath)
    func deletePlaceFromReviews(place: Place?, at indexPath: IndexPath?)
    func goToNextPlace(currentPlace: Place?, indexPath: IndexPath?)
    func visitedPlace(placeIndexPath: IndexPath)
}


class PlacePersonalInformationReviewCategory : UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PersonalInformationCellDelegate, MGLMapViewDelegate {
    
    var indexPath: IndexPath?
    var delegate: PlacePersonalInformationReviewCategoryDelegate?
    var lastPlace: Bool = false
    var status: Int = -2 { didSet {
        if status == -2 {
            setupInitialContainerView()
        } else if status + 1 == personalInformation?.count {
            setupEndContainerView()
        } else {
            setupCollectionView()
            infoCollectionView.scrollToItem(at: IndexPath(item: status+1, section: 0), at: .centeredHorizontally, animated: false)
            if let c = personalInformation?.count {
                count = c - status
            }
        }
    }}
    var place: Place? { didSet {
        if let place = place {
            personalInformation = place.getOrderedPersonalInformationToReview()
            placeNameLabel.text = place.name
            if let visitCount = place.visits?.count {
                let visitStr = visitCount > 2 ? "\(visitCount) times" : (visitCount == 2 ? "twice" : "once")
                descriptionLabel.text = "You have visited this place \(visitStr)"
            }
            coordinates = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        }
    }}
    var personalInformation: [PersonalInformation]? = [] { didSet {
        if infoCollectionView != nil, let pi = personalInformation {
            infoCollectionView.reloadData()
            count = pi.count
        }
    }}
    var color: UIColor = Constants.colors.midPurple {
        didSet {
            iconView.iconColor = color
            mapView.tintColor = color
            reviewPlaceButton.backgroundColor = color.withAlphaComponent(0.3)
            reviewPlaceButton.setTitleColor(color, for: .normal)
        }
    }
    var coordinates: CLLocationCoordinate2D? {
        didSet {
            if let annotations = mapView.annotations, annotations.count > 0 {
                mapView.removeAnnotations(annotations)
            }
            
            let annotation = MGLPointAnnotation()
            annotation.coordinate = coordinates!
            mapView.addAnnotation(annotation)
            mapView.centerCoordinate = coordinates!
        }
    }
    
    var count: Int = 1 {
        didSet {
            guard let piCount = personalInformation?.count else { return }
            // Update the card count
            if count > piCount {
                cardCountLabel.alpha = 0
            } else {
                cardCountLabel.alpha = 1
                cardCountLabel.text = "\(count) left"
            }
        }
    }

    fileprivate let cellId = "placeCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let iconView: IconView = {
        return IconView(icon: "map-marker", iconColor: Constants.colors.primaryLight)
    }()
    
    let placeNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Place name"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Place description"
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var mapView: MGLMapView = {
        let map = MGLMapView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), styleURL: MGLStyle.lightStyleURL())
        map.delegate = self
        map.tintColor = color
        map.zoomLevel = 14
        map.attributionButton.alpha = 0
        map.allowsZooming = false
        map.allowsTilting = false
        map.allowsRotating = false
        map.allowsScrolling = false
        
        map.layer.cornerRadius = 5.0
        map.backgroundColor = .white
        map.clipsToBounds = true
        map.layer.masksToBounds = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private lazy var reviewPlaceButton: UIButton = {
        let l = UIButton(type: .system)
        l.layer.cornerRadius = 5.0
        l.layer.masksToBounds = true
        l.setTitle("Review this place", for: .normal)
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.numberOfLines = 2
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.setTitleColor(color, for: .normal)
        l.backgroundColor = color.withAlphaComponent(0.3)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedVisitedPlaceButton), for: .touchUpInside)
        return l
    }()
    
    private lazy var nextPlaceButton: UIButton = {
        let l = UIButton(type: .system)
        l.layer.cornerRadius = 5.0
        l.layer.masksToBounds = true
        if self.lastPlace {
            l.setTitle("Finish", for: .normal)
        } else {
            l.setTitle("Next place", for: .normal)
        }
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.numberOfLines = 2
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.setTitleColor(color, for: .normal)
        l.backgroundColor = color.withAlphaComponent(0.3)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedNextPlaceButton), for: .touchUpInside)
        return l
    }()
    
    private lazy var cardCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "\(count) left"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    @objc fileprivate func tappedVisitedPlaceButton() {
        // remove all the subviews from the container view
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        
        if let idx = indexPath {
            delegate?.visitedPlace(placeIndexPath: idx)
        }
        
        // show the personal information collection view
        self.setupCollectionView()
        self.infoCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        if let c = personalInformation?.count {
            count = c
        }
    }
    
    @objc fileprivate func tappedNextPlaceButton() {
        self.delegate?.goToNextPlace(currentPlace: place, indexPath: indexPath)
    }
    
    var flowLayout: PlaceReviewLayout!
    var infoCollectionView: UICollectionView!
    var containerView: UIView!
    
    func setupCollectionView() {
        // remove all the subviews from the container view
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        flowLayout.xCellFrameScaling = 0.85
        flowLayout.yCellFrameScaling = 0.95
        infoCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewLayout())
        infoCollectionView.dataSource = self
        infoCollectionView.delegate = self
        infoCollectionView.backgroundColor = .white
        infoCollectionView.showsHorizontalScrollIndicator = false
        infoCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // register cell type
        infoCollectionView.register(PersonalInformationCell.self, forCellWithReuseIdentifier: cellId)
        
        // add the collectionview to the container view
        containerView.addSubview(infoCollectionView)
        containerView.addSubview(cardCountLabel)
        containerView.addVisualConstraint("H:|[v0]|", views: ["v0": cardCountLabel])
        containerView.addVisualConstraint("H:|[v0]|", views: ["v0": infoCollectionView])
        containerView.addVisualConstraint("V:|[v0]-(-14)-[v1]|", views: ["v0": infoCollectionView, "v1": cardCountLabel])
        
        infoCollectionView.layoutIfNeeded()
        
        // Setup collection view bounds
        let collectionViewFrame = infoCollectionView.frame
        flowLayout.cellWidth = floor(collectionViewFrame.width * flowLayout.xCellFrameScaling)
        flowLayout.cellHeight = floor(collectionViewFrame.height * flowLayout.yCellFrameScaling)
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - flowLayout.cellHeight) / 2.0)
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
        infoCollectionView.collectionViewLayout = flowLayout
        infoCollectionView.isPagingEnabled = false
        infoCollectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
    
    func setupInitialContainerView() {
        // remove all the subviews from the container view
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        
        containerView.addSubview(mapView)
        containerView.addSubview(reviewPlaceButton)
        
        containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": reviewPlaceButton])
        containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": mapView])
        
        containerView.addVisualConstraint("V:|[v0]-10-[v1(64)]-|", views: ["v0": mapView, "v1": reviewPlaceButton])
        
        containerView.layoutIfNeeded()
        
        mapView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100.0).isActive = true
    }
    
    func setupEndContainerView() {
        // remove all the subviews from the container view
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        
        // setup the text
        let label = UILabel()
        label.text = "Thank you for reviewing the personal information"
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        
        // setup the next place button
        containerView.addSubview(nextPlaceButton)
        containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": nextPlaceButton])
        containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": label])
        containerView.addVisualConstraint("V:|-14-[v0]-[v1(64)]-14-|", views: ["v0": label, "v1": nextPlaceButton])
    }
    
    func setupViews() {
        backgroundColor = UIColor.clear
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        
        let vStackView = UIStackView(arrangedSubviews: [placeNameLabel, descriptionLabel])
        vStackView.axis = .vertical
        vStackView.distribution = .equalSpacing
        vStackView.alignment = .leading
        vStackView.spacing = 2
        
        iconView.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        
        let hStackView = UIStackView(arrangedSubviews: [iconView, vStackView])
        hStackView.axis = .horizontal
        hStackView.distribution = .fillProportionally
        hStackView.alignment = .center
        hStackView.spacing = 8
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStackView)
        
        // add constraints
        addVisualConstraint("H:|[v0]|", views: ["v0": containerView])
        addVisualConstraint("H:|-14-[title]-14-|", views: ["title": hStackView])
        addVisualConstraint("V:|[title(60)][v0]|", views: ["title": hStackView, "v0": containerView])
        
        setupInitialContainerView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = personalInformation?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationCell
        
        cell.color = color // color must be declared before the personal information
        cell.personalInformation = personalInformation?[indexPath.item]
        cell.indexPath = indexPath
        cell.delegate = self
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = infoCollectionView.contentOffset
        visibleRect.size = infoCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath = infoCollectionView.indexPathForItem(at: visiblePoint)
        guard let indexPath = visibleIndexPath else { return }
        
        if let c = personalInformation?.count {
            count = c - indexPath.item
        }
    }
    
    // MARK: - PersonalInformationCellDelegate methods
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: FeedbackType, indexPath: IndexPath?) {
        if let pi = personalInformation, let indexPath = indexPath, let piCount = self.personalInformation?.count {
            // scroll to next item
            if piCount > indexPath.item + 1 {
                infoCollectionView.scrollToItem(at: IndexPath(item: indexPath.item+1, section:indexPath.section), at: .centeredHorizontally, animated: true)
                count -= 1
            } else {
                setupEndContainerView()
            }

            if let placeIdx = self.indexPath {
                delegate?.placePersonalInformationReview(place: place, personalInformation: pi, answer: answer, placeIndexPath: placeIdx, personalInformationIndexPath: indexPath)
            }
        }
    }
    
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
