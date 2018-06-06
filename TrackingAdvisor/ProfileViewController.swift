//
//  ProfileViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/5/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PersonalInformationReviewCategoryDelegate, DataStoreUpdateProtocol, OverlayViewDelegate {
    
    var updatedReviews: [String:[Int32]] = [:]
    var pics: [String]! = []
    var personalInformation: [String: [AggregatedPersonalInformation]]! = [:]
    var scores: [String:Double] = [:]
    var aggregatedPersonalInformation: [AggregatedPersonalInformation]! = [] {
        didSet {
            if aggregatedPersonalInformation.count > 0 {
                updatedReviews.removeAll()
                personalInformation.removeAll()
                var s: [String: Set<AggregatedPersonalInformation>] = [:]
                for pi in aggregatedPersonalInformation {
                    if let picid = pi.category {
                        if s[picid] == nil {
                            s[picid] = Set()
                        }
                        s[picid]!.insert(pi)
                    }
                    if let piid = pi.id {
                        scores[piid] = pi.score
                    }
                }
                pics = s.keys.sorted(by: { $0 < $1 })
                
                for picid in pics {
                    personalInformation[picid] = s[picid]!.sorted(by: {
                        scores[$0.id!] ?? 1 > scores[$1.id!] ?? 0
                    })
                }
                
                if collectionView == nil {
                    self.setupViews()
                }
                collectionView.reloadData()
            }
        }
    }
    
    var collectionView: UICollectionView!
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    let sectionHeaderCellId = "SectionHeaderCellId"
    var color = Constants.colors.primaryDark
    var selectedIndexPath: IndexPath?
    
    var userStats: UserStats!
    var visitCoordinates: [CLLocationCoordinate2D] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LogService.shared.log(LogService.types.tabProfile)
        
        userStats = UserStats.shared
        
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        aggregatedPersonalInformation = DataStoreService.shared.getAggregatedPersonalInformationReviewed(ctxt: nil)
        let uniquePlaces = Array(Set(DataStoreService.shared.getAllVisitsConfirmed(ctxt: nil).map { $0.place! }))
        visitCoordinates = uniquePlaces.map({ CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
        
        DataStoreService.shared.delegate = self
        
        collectionView.reloadData()
        
        if userStats.numberOfAggregatedPersonalInformationToReview > 0 {
            // show an alert
            let alertController = AppDelegate.createAlertController(title: "Personal information to review", message: "You have some personal information to review. Do you want to review them now?", yesAction: { [unowned self] in
                LogService.shared.log(LogService.types.aggPIReviewPrompt, args: [LogService.args.userChoice: "yes", LogService.args.aggPItoReview: String(self.userStats.numberOfAggregatedPersonalInformationToReview), LogService.args.aggPIReviewed: String(self.userStats.totNumberOfAggregatedPersonalInformation)])
                AppDelegate.showPersonalInformationReviews()
            }, noAction: {
                LogService.shared.log(LogService.types.aggPIReviewPrompt, args: [LogService.args.userChoice: "cancel", LogService.args.aggPItoReview: String(self.userStats.numberOfAggregatedPersonalInformationToReview), LogService.args.aggPIReviewed: String(self.userStats.totNumberOfAggregatedPersonalInformation)])
            })
            self.parent?.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if updatedReviews.count > 0 {
            UserUpdateHandler.sendPersonalInformationReviewUpdate(reviews: updatedReviews)
        }
    }
    
    func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset =  UIEdgeInsets(top: 0, left: 16.0, bottom: 14.0, right: 16.0)
        
        // Register cells types
        collectionView.register(ProfilePersonalInformatonCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(ProfileHeaderCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        collectionView.register(ProfileSectionHeaderCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: sectionHeaderCellId)
        
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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return pics.count + 1 // including the header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        
        let pic = pics[section-1]
        return personalInformation[pic]!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ProfilePersonalInformatonCell
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ProfilePersonalInformatonCell
        
        let picid = pics[indexPath.section-1]
        let pi = self.personalInformation[picid]![indexPath.item]
        cell.personalInformation = pi
        cell.numberOfDaysStudy = userStats.numberOfDaysStudy
        cell.score = scores[pi.id!]
        cell.color = color
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 42.0) / 2.0
        return CGSize(width: width, height: 75.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let section = indexPath.section
            if section == 0 {
                let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! ProfileHeaderCell
                headerCell.color = color
                headerCell.parent = self
                headerCell.visitCoordinates = visitCoordinates
                headerCell.userStats = userStats
                return headerCell
            } else {
                let sectionHeaderCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionHeaderCellId, for: indexPath) as! ProfileSectionHeaderCell
                let picid = pics[section-1]
                let pic = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
                sectionHeaderCell.personalInformationCategory = pic
                sectionHeaderCell.color = color
                return sectionHeaderCell
            }
        } else {
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // 4 - return the correct size
        if section == 0 {
            return CGSize(width: collectionView.frame.width, height: 650)
        } else {
            return CGSize(width: collectionView.frame.width, height: 75)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let picid = pics[indexPath.section-1]
        if let pi = personalInformation[picid]?[indexPath.item] {
            self.selectedIndexPath = indexPath
            
            let overlayView = AggregatedPersonalInformationExplanationOverlayView()
            overlayView.color = color
            overlayView.picIndexPath = indexPath
            overlayView.indexPath = indexPath
            overlayView.delegate = self
            overlayView.picid = picid
            overlayView.aggregatedPersonalInformation = pi
            overlayView.showAllQuestions = true
            
            if let piid = pi.id {
                LogService.shared.log(LogService.types.profilePiOverlay,
                                      args: [LogService.args.piId: piid])
            }
            
            OverlayView.shared.delegate = self
            OverlayView.shared.showOverlay(with: overlayView)
        }
    }
    
    // MARK: - OverlayViewDelegate methods
    func overlayViewDismissed() {
        if updatedReviews.count > 0 {
            // get the cell and move it to the appropriate place
            if let idx = selectedIndexPath {
                let picid = pics[idx.section-1]
                if let pi = self.personalInformation[picid]?[idx.item], let piid = pi.id {
                    // update the score
                    let score = pi.score
                    scores[piid] = score
                    if let cell = collectionView.cellForItem(at: idx) as? ProfilePersonalInformatonCell {
                        cell.score = score
                    }
                    
                    // determine the new position in the category
                    let count = self.personalInformation[picid]!.count
                    var newItemIdx = count-1
                    var lastScore: Double? = nil
                    for (index,api) in self.personalInformation[picid]!.enumerated() {
                        if api.id == piid { continue }
                        let apiScore = scores[api.id!]!
                        if apiScore < score {
                            newItemIdx = index
                            lastScore = apiScore
                            break
                        }
                    }
                    
                    if lastScore != nil && newItemIdx > idx.item {
                        newItemIdx -= 1
                    }
                    // move the item to the new index
                    let newIndexPath = IndexPath(item: newItemIdx, section: idx.section)
                    collectionView.moveItem(at: idx, to: newIndexPath)
                    // update the personal information order
                    let tmp = personalInformation[picid]!.remove(at: idx.item)
                    personalInformation[picid]!.insert(tmp, at: newIndexPath.item)
                }
            }
            
            UserUpdateHandler.sendPersonalInformationReviewUpdate(reviews: updatedReviews)
            updatedReviews.removeAll()
        }
        
        self.selectedIndexPath = nil
    }
    
    // MARK: - PersonalInformationReviewCategoryDelegate methods
    
    func personalInformationReview(cat: String, personalInformation: AggregatedPersonalInformation, type: ReviewType, rating: Int32, picIndexPath: IndexPath, personalInformationIndexPath: IndexPath) {
        
        if let piid = personalInformation.id {
            LogService.shared.log(LogService.types.profilePiReview,
                                  args: [LogService.args.piId: piid,
                                         LogService.args.reviewType: String(type.rawValue),
                                         LogService.args.value: String(rating)])
            
            DataStoreService.shared.updatePersonalInformationReview(with: piid, type: type, rating: rating) { [unowned self] allRatings in
                self.updatedReviews[piid] = allRatings
                UserStats.shared.updateAggregatedPersonalInformation()
            }
        }
    }
    
    func explanationFeedback(cat: String, personalInformation: AggregatedPersonalInformation) {
        OverlayView.shared.hideOverlayView()
        let viewController = ExplanationFeedbackViewController()
        viewController.personalInformation = personalInformation
        viewController.color = color
        
        if let piid = personalInformation.id {
            LogService.shared.log(LogService.types.profilePiFeedback,
                                  args: [LogService.args.piId: piid])
        }
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - DataStoreUpdateProtocol methods
    func dataStoreDidUpdateAggregatedPersonalInformation() {
        // get the latest aggregatedPersonalInformation
        aggregatedPersonalInformation = DataStoreService.shared.getAggregatedPersonalInformationReviewed(ctxt: nil)
    }
    
    func dataStoreDidUpdate(for day: String?) {
        aggregatedPersonalInformation = DataStoreService.shared.getAggregatedPersonalInformationReviewed(ctxt: nil)
    }
}


class ProfileHeaderCell: UICollectionViewCell, MGLMapViewDelegate {
    var parent: ProfileViewController?
    
    var color: UIColor = Constants.colors.orange { didSet {
        iconExitMapView.color = color
    }}
    
    var userStats: UserStats? { didSet {
        if let stats = userStats {
            progressBar.level = stats.level
            progressBar.points = stats.score
            let (minVal, maxVal) = UserStats.getLevelBounds(level: stats.level)
            progressBar.minValue = minVal
            progressBar.maxValue = maxVal
            progressBar.progress = Float((stats.score - minVal)) / Float((maxVal - minVal))
            
            if stats.numberOfAggregatedPersonalInformationReviewed == 0 {
                yourPISubTitle.text = "After visiting some places and reviewing the personal information associated to the places, you will be able to find the personal information below."
            }
        }
    }}
    
    var visitsSource: MGLShapeSource? { didSet {
        setHeatmap()
    }}
    var visitCoordinates: [CLLocationCoordinate2D] = [] { didSet {
        if visitCoordinates.count > 0, let multiPoints = MGLPointCollectionFeature(coordinates: &visitCoordinates, count: UInt(visitCoordinates.count)) {
            visitsSource = MGLShapeSource(identifier: "visits", features: [multiPoints], options: nil)
        }
    }}
    
    var mainTitle: UILabel = {
        let label = UILabel()
        label.text = "About you"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var progressBar: LevelProgressBar = {
        return LevelProgressBar()
    }()
    
    var yourMapTitle: UILabel = {
        let label = UILabel()
        label.text = "Your map"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var yourMapSubTitle: UILabel = {
        let label = UILabel()
        label.text = "You can find below a heatmap of the visits you made while you have been participating in the study."
        label.numberOfLines = 3
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.textColor = Constants.colors.descriptionColor
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var yourPITitle: UILabel = {
        let label = UILabel()
        label.text = "Your personal information"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var yourPISubTitle: UILabel = {
        let label = UILabel()
        label.text = "You can find below a summary of the different personal information we have infered from the places you have visited. Tap on them to get more information."
        label.numberOfLines = 4
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.textColor = Constants.colors.descriptionColor
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var mapView: MGLMapView = {
        let map = MGLMapView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), styleURL: MGLStyle.darkStyleURL)
        map.zoomLevel = 2
        map.translatesAutoresizingMaskIntoConstraints = false
        map.layer.cornerRadius = 5.0
        map.layer.shadowRadius = 5.0
        map.layer.shadowOpacity = 0.5
        map.layer.shadowOffset = CGSize(width: 5, height: 5)
        map.backgroundColor = Constants.colors.superLightGray
        map.allowsZooming = false
        map.allowsScrolling = false
        map.allowsTilting = false
        map.allowsRotating = false
        
        map.attributionButton.alpha = 0
        map.logoView.alpha = 0
        
        map.clipsToBounds = true
        map.layer.masksToBounds = true
        
        // Center the map on the visit coordinates
        let coordinates = CLLocationCoordinate2D(latitude: 51.524528, longitude: -0.134524)
        map.centerCoordinate = coordinates
        return map
    }()
    
    var zoomMapView: MGLMapView = {
        let map = MGLMapView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), styleURL: MGLStyle.darkStyleURL)
        map.zoomLevel = 10
        map.backgroundColor = Constants.colors.superLightGray
        map.attributionButton.alpha = 0
        map.logoView.alpha = 0
        map.allowsTilting = false
        map.allowsRotating = false
        
        // Center the map on the visit coordinates
        let coordinates = CLLocationCoordinate2D(latitude: 51.524528, longitude: -0.134524)
        map.centerCoordinate = coordinates
        return map
    }()
    
    lazy var iconExitMapView: RoundIconView = {
        return RoundIconView(image: UIImage(named: "times")!, color: Constants.colors.primaryLight, imageColor: .white)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        mapView.delegate = self
        
        addSubview(mainTitle)
        addVisualConstraint("H:|[v0]|", views: ["v0": mainTitle])
        addVisualConstraint("V:|-48-[v0(40)]", views: ["v0": mainTitle])
        
        addSubview(progressBar)
        addVisualConstraint("H:|[v0]|", views: ["v0": progressBar])
        addVisualConstraint("V:[v0]-30-[v1(70)]", views: ["v0": mainTitle, "v1": progressBar])
        progressBar.addTapGestureRecognizer { [unowned self] in
            self.showUserStatsOverlay()
        }
        
        addSubview(yourMapTitle)
        addVisualConstraint("H:|[v0]|", views: ["v0": yourMapTitle])
        
        addSubview(yourMapSubTitle)
        addVisualConstraint("H:|[v0]|", views: ["v0": yourMapSubTitle])
        
        addSubview(mapView)
        addVisualConstraint("H:|[v0]|", views: ["v0": mapView])
        
        addSubview(yourPITitle)
        addVisualConstraint("H:|[v0]|", views: ["v0": yourPITitle])
        
        addSubview(yourPISubTitle)
        addVisualConstraint("H:|[v0]|", views: ["v0": yourPISubTitle])
        
        addVisualConstraint("V:|-48-[title(40)]-30-[level(70)]-16-[mt][mst]-[map(250)]-(>=16)-[pit][pist]|", views: ["title": mainTitle, "level": progressBar, "mt": yourMapTitle, "mst": yourMapSubTitle, "map": mapView, "pit": yourPITitle, "pist": yourPISubTitle])
        
        mapView.addTapGestureRecognizer { [unowned self] in
            self.animateMapViewIn()
        }
    }
    

    func animateMapViewIn() {
        LogService.shared.log(LogService.types.profileMap)
        
        if let startingFrame = mapView.superview?.convert(mapView.frame, to: nil), let parent = parent {
            mapView.alpha = 0
            zoomMapView.frame = startingFrame
            zoomMapView.delegate = self
            
            parent.view.addSubview(zoomMapView)
            
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: { [unowned self] in
                self.zoomMapView.frame = CGRect(x: 0, y: -1 * UIApplication.shared.statusBarFrame.height, width: parent.view.frame.width, height: parent.view.frame.height)
            }, completion: { [unowned self] didComplete in
                if didComplete {
                    self.iconExitMapView.frame = CGRect(x: 20, y: UIApplication.shared.statusBarFrame.height + 10, width: 30, height: 30)
                    self.iconExitMapView.addTapGestureRecognizer {
                        self.animateMapViewOut()
                    }
                    parent.view.addSubview(self.iconExitMapView)
                    if self.visitCoordinates.count == 0 {
                        return
                    }
                    
                    if let multiPoints = MGLPointCollectionFeature(coordinates: &self.visitCoordinates, count: UInt(self.visitCoordinates.count)) {
                        let source = MGLShapeSource(identifier: "visits-big", features: [multiPoints], options: nil)
                        
                        if self.zoomMapView.style?.layer(withIdentifier: "visits-big-heat") == nil, self.zoomMapView.style?.source(withIdentifier: "visits-big") == nil {
                                
                            let layer = MGLHeatmapStyleLayer(identifier: "visits-big-heat", source: source)
                            layer.heatmapRadius = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                                               [0: 5,
                                                                6: 10])
                            layer.heatmapWeight = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:(magnitude, 'linear', nil, %@)",
                                                               [0: 0,
                                                                6: 1])
                            layer.heatmapIntensity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                                                  [0: 1,
                                                                   9: 2])
                            
                            layer.heatmapOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                                                [0: 0.75,
                                                                 10: 0.75,
                                                                 12: 0])
                            
                            let circleLayers = MGLCircleStyleLayer(identifier: "visits-big-circles", source: source)
                            circleLayers.circleColor = NSExpression(forConstantValue: Constants.colors.lightOrange)
                            circleLayers.circleOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                                                      [0: 0,
                                                                       11: 0,
                                                                       13: 1])
                            
                            self.zoomMapView.style?.addSource(source)
                            self.zoomMapView.style?.addLayer(layer)
                            self.zoomMapView.style?.addLayer(circleLayers)
                            if let coordinates = source.shape?.coordinate {
                                self.zoomMapView.centerCoordinate = coordinates
                                self.zoomMapView.zoomLevel = 5
                            }
                        }
                    }
                }
            })
        }
    }
    
    func animateMapViewOut() {
        if let startingFrame = mapView.superview?.convert(mapView.frame, to: nil) {
            self.iconExitMapView.removeFromSuperview()
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: { [unowned self] in
                self.zoomMapView.frame = startingFrame
            }, completion: { [unowned self] didComplete in
                if didComplete {
                    self.zoomMapView.removeFromSuperview()
                    self.mapView.alpha = 1
                }
            })
        }
    }
    
    func showUserStatsOverlay() {
        let overlayView = UserStatsOverlayView()
        overlayView.color = color
        OverlayView.shared.showOverlay(with: overlayView)
    }
    
    // MARK: -  MGLMapViewDelegate methods
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        setHeatmap()
    }
    
    private func setHeatmap() {
        if visitCoordinates.count > 0 &&
           self.mapView.style?.layer(withIdentifier: "visits-heat") == nil,
           let source = visitsSource {
            
            // set a heatmap layer
            // https://www.mapbox.com/ios-sdk/api/4.0.0/Classes/MGLHeatmapStyleLayer.html
            
            let layer = MGLHeatmapStyleLayer(identifier: "visits-heat", source: source)
            layer.heatmapWeight = NSExpression(forConstantValue: 0.2)
            layer.heatmapIntensity = NSExpression(forConstantValue: 0.1)
            layer.heatmapRadius = NSExpression(forConstantValue: 7)
            layer.heatmapOpacity = NSExpression(forConstantValue: 0.75)
            
            mapView.style?.addSource(source)
            mapView.style?.addLayer(layer)
            mapView.centerCoordinate = source.shape!.coordinate
            mapView.layoutIfNeeded()
        }
    }
}

class ProfileSectionHeaderCell: UICollectionViewCell {
    var color: UIColor = Constants.colors.orange {
        didSet { iconView.iconColor = color }
    }
    var personalInformationCategory: PersonalInformationCategory? {
        didSet {
            if let name = personalInformationCategory?.name {
                nameLabel.text = name
            }
            if let icon = personalInformationCategory?.icon {
                iconView.icon = icon
            }
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 25, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let iconView: IconView = {
        return IconView(icon: "user-circle", iconColor: Constants.colors.primaryLight)
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(nameLabel)
        addSubview(iconView)
        
        addVisualConstraint("H:|[icon(25)]-[text]|", views: ["icon": iconView, "text": nameLabel])
        iconView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        addVisualConstraint("V:|[nameLabel]|", views: ["nameLabel": nameLabel])
    }
}

class ProfilePersonalInformatonCell: UICollectionViewCell {
    var score: Double? { didSet {
        updateColor()
    }}
    var numberOfDaysStudy: Int?
    var personalInformation: AggregatedPersonalInformation? {
        didSet {
            if let piName = personalInformation?.name {
                nameLabel.text = piName
            }
        }
    }
    
    var color: UIColor = Constants.colors.orange {
        didSet {
            updateColor()
        }
    }
    
    private func updateColor() {
        if let score = score, let len = numberOfDaysStudy {
            let alpha = min(CGFloat(score) / (CGFloat(len) * 100.0), 1.0)
            backgroundColor = color.withAlphaComponent(alpha)
            if alpha > 0.4 {
                nameLabel.textColor = .white
            } else {
                nameLabel.textColor = color
            }
        } else {
            backgroundColor = color.withAlphaComponent(0.0)
            nameLabel.textColor = color
        }
    }
    
    lazy private var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.textColor = color
        label.numberOfLines = 2
        label.textAlignment = .center
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
        layer.cornerRadius = 10
        backgroundColor = color.withAlphaComponent(0.3)
        
        contentView.addSubview(nameLabel)
        
        contentView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": nameLabel])
        contentView.addVisualConstraint("V:|-14-[v0]-14-|", views: ["v0": nameLabel])
    }
}

class LevelProgressBar : UIView {
    var progress: Float = 0.33 { didSet { progressBarView.progress = progress }}
    var minValue: Int = 5000 { didSet { leftLabel.text = String(minValue) }}
    var maxValue: Int = 10000 { didSet { rightLabel.text = String(maxValue) }}
    var level: Int = 6 { didSet { levelLabel.text = "Level \(level)" }}
    var points: Int = 5432 { didSet { pointsLabel.text = "\(points) points ‣" }}
    
    internal lazy var progressBarView: UIProgressView = {
        let pg = UIProgressView()
        pg.progress = self.progress
        pg.progressTintColor = Constants.colors.midPurple
        pg.translatesAutoresizingMaskIntoConstraints = false
        return pg
    }()
    
    internal lazy var leftLabel: UILabel = {
        let label = UILabel()
        label.text = String(minValue)
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.descriptionColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal lazy var rightLabel: UILabel = {
        let label = UILabel()
        label.text = String(maxValue)
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.descriptionColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.text = "Level \(level)"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .heavy)
        label.textColor = Constants.colors.midPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    internal lazy var pointsLabel: UILabel = {
        let label = UILabel()
        label.text = "\(points) points ‣"
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        label.textColor = Constants.colors.midPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
        addSubview(progressBarView)
        addSubview(leftLabel)
        addSubview(rightLabel)
        addSubview(levelLabel)
        addSubview(pointsLabel)
        
        addVisualConstraint("H:|[v0]|", views: ["v0": progressBarView])
        addVisualConstraint("H:|[v0]", views: ["v0": leftLabel])
        addVisualConstraint("H:[v0]|", views: ["v0": rightLabel])
        addVisualConstraint("H:|[v0]", views: ["v0": levelLabel])
        addVisualConstraint("H:[v0]|", views: ["v0": pointsLabel])
        addVisualConstraint("V:|[v0]-5-[v1(10)]-2-[v2]", views: ["v0": levelLabel, "v1": progressBarView, "v2": leftLabel])
        addVisualConstraint("V:|[v0]-5-[v1(10)]-2-[v2]", views: ["v0": pointsLabel, "v1": progressBarView, "v2": rightLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

