//
//  MapViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/13/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox
import Alamofire

class MapViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MGLMapViewDelegate, WeekCalendarViewDelegate {
    
    var mapView: MGLMapView!
    var collectionView: UICollectionView!
    var flowLayout: PlaceReviewLayout!
    var weekCalendarView: WeekCalendarView!
    var fullScreenView: FullScreenView?
    fileprivate var alertView: AlertView?
    
    var color = Constants.colors.midPurple
    let cellId = "CellId"
    var daysHidden = false  // default
    var currentIndexPath: IndexPath?
    var selectedAnnotation: String? { didSet {
        if let pid = selectedAnnotation, let annotation = annotations[pid] {
            
            if let idx = places[pid], let coordinates = visits[idx].place?.coordinates,
               let oldPid = oldValue, let oldIdx = places[oldPid], let oldCoordinates = visits[oldIdx].place?.coordinates {
                
                let distance = coordinates.distance(from: oldCoordinates)
                
                if distance <= 5000 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                        self?.mapView.showAnnotations([annotation], animated: true)
                        self?.mapView.selectAnnotation(annotation, animated: false)
                    }
                } else {
                    mapView.setZoomLevel(7.5, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                        self?.mapView.showAnnotations([annotation], animated: true)
                        self?.mapView.selectAnnotation(annotation, animated: false)
                    }
                }
            }
            
            if let currentIdx = currentIndexPath {
                if let currentPid = visits[currentIdx.item].place?.id {
                    if currentPid != pid {
                        if let idx = places[pid] {
                            let indexPath = IndexPath(item: idx, section: 0)
                            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                            currentIndexPath = indexPath
                        }
                    }
                }
            } else {
                let indexPath = IndexPath(item: 0, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                currentIndexPath = indexPath
            }
        }
    }}
    
    var daysViewOffset: CGFloat!
    var daysViewUp: CGPoint!
    var daysViewDown: CGPoint!
    
    var visits: [Visit] = [] { didSet {
        if collectionView != nil {
            collectionView.reloadData()
        }
    }}
    var places: [String:Int] = [:]
    var annotations: [String:MGLAnnotation] = [:]
    var dateSelected: Date?
    
    var days: [String] = []
    
    var rawTrace: [VisitRawTrace]? {
        didSet {
            guard rawTrace != nil, mapView != nil else { return }
            
            var annotations: [CustomPointAnnotation] = []
            for point in rawTrace! {
                let pointAnnotation = CustomPointAnnotation(coordinate: CLLocationCoordinate2D(latitude: point.lon, longitude: point.lat), title: nil, subtitle: nil)
                pointAnnotation.reuseIdentifier = "rawTrace\(point.lon)"
                pointAnnotation.image = dot(size: 15, color: Constants.colors.primaryDark.withAlphaComponent(0.3))
                pointAnnotation.type = "raw"
                
                annotations.append(pointAnnotation)
            }
            
            mapView.addAnnotations(annotations)
        }
    }
    
    var dayLabel: UILabel = {
        let label = UILabel()
        label.text = "Today"
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textAlignment = .center
        label.textColor = Constants.colors.black
        label.backgroundColor = Constants.colors.superLightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var dayStats: DayStats = {
        let view = DayStats()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var daysView: UIView = {
        let view = UIView()
        view.addSubview(weekCalendarView)
        view.addSubview(dayLabel)
        view.addSubview(dayStats)
        view.backgroundColor = Constants.colors.superLightGray
        view.addVisualConstraint("H:|[cal]|", views: ["cal": weekCalendarView])
        view.addVisualConstraint("H:|[day]|", views: ["day": dayLabel])
        view.addVisualConstraint("H:|-10-[stats]-10-|", views: ["stats": dayStats])
        view.addVisualConstraint("V:|[cal(80)][day(30)][stats(20)]-|", views: ["cal": weekCalendarView, "day": dayLabel, "stats": dayStats])
        print("layout daysView")
        return view
    }()

    
    @objc func showDays() {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1,
                       options: [.curveEaseOut], animations: { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.daysHidden {
                strongSelf.daysView.center = strongSelf.daysViewUp
            } else {
                strongSelf.daysView.center = strongSelf.daysViewDown
            }
        }, completion: { [weak self] success in
            guard let strongSelf = self else { return }
            strongSelf.daysHidden = !strongSelf.daysHidden
            strongSelf.daysView.layoutIfNeeded()
        })
    }
    
    @objc func handleDaysViewPanGesture(panGesture: UIPanGestureRecognizer) {
        let velocity = panGesture.velocity(in: view)
        if panGesture.state == .ended {
            if velocity.y < 0 {
                UIView.animate(withDuration: 0.3, animations: { [weak self] () -> Void in
                    guard let strongSelf = self else { return }
                    strongSelf.daysView.center = strongSelf.daysViewDown
                }, completion: { [weak self] success in
                    guard let strongSelf = self else { return }
                    strongSelf.daysHidden = true
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: { [weak self] () -> Void in
                    guard let strongSelf = self else { return }
                    strongSelf.daysView.center = strongSelf.daysViewUp
                }, completion: { [weak self] success in
                    guard let strongSelf = self else { return }
                    strongSelf.daysHidden = false
                })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LogService.shared.log(LogService.types.tabMap)
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.barStyle = .default
        self.tabBarController?.tabBar.isHidden = false
        
        days = DataStoreService.shared.getUniqueVisitDays(ctxt: nil)
        if days.count > 0 {
            weekCalendarView = WeekCalendarView()
            weekCalendarView.delegate = self
            
            setupCollectionView()
            setupMapView()
            setupViews()
            
            weekCalendarView.setToday()
            dayLabel.text = DateHandler.dateToDayLetterString(from: Date())
            
            if let date = dateSelected {
                selectedDate(date: date)
            } else {
                daysView.layoutIfNeeded()
                selectedDate(date: Date())
            }
            
            if mapView != nil, let a = mapView.annotations {
                mapView.showAnnotations(a, animated: true)
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let calendarButton = UIButton()
        calendarButton.setImage(UIImage(named: "calendar")!.withRenderingMode(.alwaysTemplate), for: .normal)
        calendarButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        calendarButton.addTarget(self, action: #selector(showDays), for: .touchUpInside)
        let rightBarButton = UIBarButtonItem(customView: calendarButton)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        self.title = "My Places"
        
        
        days = DataStoreService.shared.getUniqueVisitDays(ctxt: nil)
        if days.count == 0 {
            // the user just installed the app, show an animation
            fullScreenView = FullScreenView(frame: view.frame)
            fullScreenView!.icon = "path"
            fullScreenView!.iconColor = Constants.colors.primaryLight
            fullScreenView!.headerTitle = "Your map, here"
            fullScreenView!.subheaderTitle = "After moving to a few places, you will find a map with the places that you visited here."
            view.addSubview(fullScreenView!)
        }
    }
    
    func setupCollectionView() {
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // register cell type
        collectionView.register(MapVisitCell.self, forCellWithReuseIdentifier: cellId)
    }
    
    func setupMapView() {
        // set up the map view
        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.streetsStyleURL)
        mapView.tintColor = color
        mapView.delegate = self
        mapView.zoomLevel = 15
        mapView?.centerCoordinate = CLLocationCoordinate2D(latitude: 51.524543, longitude: -0.132176)
        mapView.maximumZoomLevel = 14.0
        mapView.attributionButton.alpha = 0
        mapView.logoView.alpha = 0
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupViews() {
        self.view.addSubview(mapView)
        self.view.addSubview(collectionView)
        self.view.addSubview(daysView)
        
        self.view.addVisualConstraint("V:|[map]|", views: ["map" : mapView])
        self.view.addVisualConstraint("H:|[map]|", views: ["map" : mapView])
        self.view.addVisualConstraint("H:|[collection]|", views: ["collection" : collectionView])
        self.view.addVisualConstraint("V:[collection(150)]-60-|", views: ["collection" : collectionView])
        
        let topBarHeight = 0.0 // UIApplication.shared.statusBarFrame.size.height +
//            (self.navigationController?.navigationBar.frame.height ?? 0.0)
        let width = Double(UIScreen.main.bounds.width)
        
        daysView.frame = CGRect(x: 0.0, y: topBarHeight, width: width, height: 80.0+30+28)
        let daysViewPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDaysViewPanGesture))
        daysView.addGestureRecognizer(daysViewPanGesture)
        
        daysViewOffset = -80.0
        daysViewUp = daysView.center
        daysViewDown = CGPoint(x: daysView.center.x ,y: daysView.center.y + daysViewOffset)
        
        collectionView.layoutIfNeeded()
        
        // Setup collection view bounds
        let collectionViewFrame = collectionView.frame
        flowLayout.cellWidth = floor(250)
        flowLayout.cellHeight = floor(collectionViewFrame.height * flowLayout.yCellFrameScaling) // for the tab bar
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - flowLayout.cellHeight) / 2.0)
        
        var offset: CGFloat = 50.0
        if AppDelegate.isIPhone5() {
            offset = 20.0
        }
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = insetX - offset // to show the next cell
        flowLayout.minimumLineSpacing = insetX - offset // to show the next cell
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.isPagingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visits.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MapVisitCell
        let visit = visits[indexPath.item]
        cell.visit = visit
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = collectionView.contentOffset
        visibleRect.size = collectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        guard let indexPath = visibleIndexPath else { return }
        currentIndexPath = indexPath
        
        let visit = visits[indexPath.item]
        if let pid = visit.place?.id {
            selectedAnnotation = pid
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let visit = visits[indexPath.item]
        let controller = OneTimelinePlaceDetailViewController()
        controller.vid = visit.id
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - MGLMapViewDelegate protocol
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        guard let point = annotation as? CustomPointAnnotation, let image = point.image,
              let reuseIdentifier = point.reuseIdentifier, let type = point.type else {
            return nil
        }
        
        if type != "visit" { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            let av = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            av.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            av.image = image
            av.backgroundColor = point.color ?? Constants.colors.midPurple
            
            annotationView = av
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let point = annotation as? CustomPointAnnotation, let image = point.image,
            let reuseIdentifier = point.reuseIdentifier, let type = point.type {
            
            if type != "raw" { return nil }
            
            if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier) {
                // The annotatation image has already been cached, just reuse it.
                return annotationImage
            } else {
                // Create a new annotation image.
                return MGLAnnotationImage(image: image, reuseIdentifier: reuseIdentifier)
            }
        }
        
        // Fallback to the default marker image.
        return nil
    }

    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return false
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if let annotation = annotation as? CustomPointAnnotation {
            if selectedAnnotation != annotation.reuseIdentifier {
                selectedAnnotation = annotation.reuseIdentifier
            }
        }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        if let a = mapView.annotations {
            mapView.showAnnotations(a, animated: true)
        }
    }
    
    // MARK: - WeekCalendarViewDelegate
    func selectedDate(date: Date) {
        // reset all
        annotations.removeAll()
        visits.removeAll()
        places.removeAll()
        currentIndexPath = nil
        dateSelected = date
        
        dayLabel.text = DateHandler.dateToDayLetterString(from: date)
        let day = DateHandler.dateToDayString(from: date)
        
        let allVisits = DataStoreService.shared.getVisits(for: day, ctxt: nil)
        
        if allVisits.count == 0 { return }
        
        visits = allVisits.filter({ $0.visited == 1 })
        let visitsToReview = allVisits.filter({ $0.visited == 0 })
        
        if visits.count == 0 && visitsToReview.count > 0 {
            print("show alert controller")
            // show an alert
            let alertController = AppDelegate.createAlertController(title: "No places to show", message: "You need to review the visits for this day in order to see them. Do you want to review them now?", yesAction: {
                LogService.shared.log(LogService.types.mapReviewPrompt, args: [LogService.args.userChoice: "cancel", LogService.args.day: day])
                AppDelegate.showTimeline(for: day)
            }, noAction: {
                LogService.shared.log(LogService.types.mapReviewPrompt, args: [LogService.args.userChoice: "cancel", LogService.args.day: day])
            })
            self.parent?.present(alertController, animated: true, completion: nil)
        } else if visitsToReview.count > 0 {
            print("show alert view")
            
            if alertView == nil {
                self.collectionView.alpha = 0
                
                // show a view on top of the collection view
                alertView = AlertView(frame: CGRect(x: UIScreen.main.bounds.midX - 125, y: UIScreen.main.bounds.maxY - 280, width: 250, height: 150), yesAction: { [weak self] in
                    LogService.shared.log(LogService.types.mapReviewPrompt, args: [LogService.args.userChoice: "review-place", LogService.args.day: day])
                    self?.alertView?.removeFromSuperview()
                    self?.alertView = nil
                    AppDelegate.showTimeline(for: day)
                    
                }, noAction: { [weak self] in
                    LogService.shared.log(LogService.types.mapReviewPrompt, args: [LogService.args.userChoice: "dismiss", LogService.args.day: day])
                    self?.alertView?.removeFromSuperview()
                    self?.alertView = nil
                    self?.collectionView.alpha = 1
                })
                
                self.view.addSubview(alertView!)
                self.view.bringSubview(toFront: alertView!)
            }
        } else {
            alertView?.removeFromSuperview()
            alertView = nil
            if collectionView != nil {
                collectionView.alpha = 1
            }
        }
        
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        
        var placeSet: Set<Place> = Set<Place>()
        for (index, visit) in visits.enumerated() {
            guard let place = visit.place else { continue }
            
            if placeSet.contains(place) { continue }
            
            if let placeName = place.name, let pid = place.id {
                let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                let point = CustomPointAnnotation(coordinate: coordinate, title: placeName, subtitle: nil)
                point.reuseIdentifier = pid
                point.image = UIImage(named: place.icon ?? "map-marker")!.withRenderingMode(.alwaysTemplate)
                point.type = "visit"
                point.color = place.getPlaceColor()
                annotations[pid] = point
                placeSet.insert(place)
                
                places[pid] = index
            }
        }
        
        let a = Array(annotations.values)
        mapView.addAnnotations(a)
        
        let visit = visits.first
        if let pid = visit?.place?.id {
            selectedAnnotation = pid
        }
        
        if Settings.getShowRawTrace() {
            // getting the raw trace from the server
            getRawTrace(day: day)
        }
        
        let top:CGFloat = self.daysHidden ? 50 : 180
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.mapView.showAnnotations(a,
                                          edgePadding: UIEdgeInsets(top: top, left: 25.0, bottom: 180.0, right: 25.0),
                                          animated: true)
        }
        
        // update the dayStats
        print("update dayStats")
        dayStats.visits = visits
    }
    
    private func getRawTrace(day: String) {
        self.rawTrace?.removeAll()
        
        let parameters: Parameters = [
            "userid": Settings.getUserId() ?? "",
            "day": day
        ]
        
        Alamofire.request(Constants.urls.rawTraceURL, method: .get, parameters: parameters)
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        strongSelf.rawTrace = try decoder.decode([VisitRawTrace].self, from: data)
                    } catch {
                        print("Error serializing the json", error)
                    }
                }
        }
    }
}

class MapVisitCell: UICollectionViewCell {
    var visit: Visit? { didSet {
        if let placeName = visit?.place?.name {
            nameLabel.text = placeName
        }
        if let placeDescription = visit?.getShortDescription() {
            descriptionLabel.text = placeDescription
        }
        if let icon = visit?.place?.icon {
            iconView.icon = icon
        } else {
            iconView.icon = "map-marker"
        }
        if let color = visit?.place?.getPlaceColor() {
            self.color = color
        }
    }}
    
    var color: UIColor = Constants.colors.midPurple {
        didSet {
            self.headerView.backgroundColor = color
            self.nameLabel.textColor = .white
            self.iconView.iconColor = .white
            self.contentView.backgroundColor = Constants.colors.superLightGray
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var iconView: IconView = {
        let iv = IconView(icon: "map-marker", iconColor: .white)
        return iv
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "place name"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Description of the visit at this place."
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.numberOfLines = 4
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func setupViews() {
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 1.0
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath

        
        headerView.addSubview(nameLabel)
        headerView.addSubview(iconView)
        headerView.addVisualConstraint("H:|-14-[icon]-[v0]-|", views: ["icon": iconView, "v0": nameLabel])
        headerView.addVisualConstraint("V:|-[v0]-|", views: ["v0": nameLabel])
        iconView.widthAnchor.constraint(equalToConstant: 25.0).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        iconView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        
        contentView.addSubview(headerView)
        contentView.addSubview(descriptionLabel)
        
        contentView.addVisualConstraint("H:|[v0]|", views: ["v0": headerView])
        contentView.addVisualConstraint("H:|-[v0]-|", views: ["v0": descriptionLabel])
        contentView.addVisualConstraint("V:|[v0(60)]-[v1]", views: ["v0": headerView, "v1": descriptionLabel])
    }
}

fileprivate class AlertView: UIView {
    
    var yesAction: (()->())?
    var noAction: (()->())?
    
    var color: UIColor = Constants.colors.midPurple { didSet {
        yesBtn.backgroundColor = color.withAlphaComponent(0.8)
        noBtn.backgroundColor = color.withAlphaComponent(0.3)
        noBtn.setTitleColor(color, for: .normal)
    }}
    
    var title: UILabel = {
        let label = UILabel()
        label.text = "Missing places"
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var label: UILabel = {
        let label = UILabel()
        label.text = "Some places are missing because you haven't reviewed them. Do you want to review them now?"
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var yesBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.numberOfLines = 1
        btn.layer.masksToBounds = true
        btn.setTitle("Yes", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = color.withAlphaComponent(0.8)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tappedYesButton), for: .touchUpInside)
        return btn
    }()
    
    lazy var noBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.numberOfLines = 1
        btn.layer.masksToBounds = true
        btn.setTitle("No", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        btn.setTitleColor(color, for: .normal)
        btn.backgroundColor = color.withAlphaComponent(0.3)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tappedNoButton), for: .touchUpInside)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    convenience init(frame: CGRect, yesAction: (()->())?, noAction: (()->())?) {
        self.init(frame: frame)
        self.yesAction = yesAction
        self.noAction = noAction
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tappedYesButton(sender: UIButton) {
        yesAction?()
    }
    
    @objc func tappedNoButton(sender: UIButton) {
        noAction?()
    }
    
    private func setupViews() {
        let contentView = UIView()
        contentView.frame = bounds
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = Constants.colors.superLightGray
        addSubview(contentView)
        bringSubview(toFront: contentView)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 1.0
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        
        contentView.addSubview(title)
        contentView.addSubview(label)
        contentView.addSubview(yesBtn)
        contentView.addSubview(noBtn)
        contentView.addVisualConstraint("H:|-[title]-|", views: ["title": title])
        contentView.addVisualConstraint("H:|-[label]-|", views: ["label": label])
        contentView.addVisualConstraint("H:|[ybtn][nbtn]|", views: ["ybtn": yesBtn, "nbtn": noBtn])
        contentView.addVisualConstraint("V:|-[title][label]-10-[btn(40)]|", views: ["title": title, "label": label, "btn": yesBtn])
        contentView.addVisualConstraint("V:|-[title][label]-10-[btn(40)]|", views: ["title": title, "label": label, "btn": noBtn])
        yesBtn.widthAnchor.constraint(equalTo: noBtn.widthAnchor, multiplier: 1.0).isActive = true
    }
}

class DayStats: UIView {
    var visits: [Visit]? { didSet {
        updateUI()
    }}
    let nbIntervals: CGFloat = 96.0
    let intervalDuration: TimeInterval = 900 // 15-min intervals
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, visits: [Visit]) {
        self.init(frame: frame)
        self.visits = visits
        updateUI()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func updateUI() {
        guard let visits = visits else { return }
        
        // remove all the subviews
        for view in subviews {
            view.removeFromSuperview()
        }
        
        let intervalSize:CGFloat = frame.width / nbIntervals
        let height: CGFloat = 20.0
        
        for visit in visits {
            if let d = visit.departure, let a = visit.arrival {
                let indexStart = floor(abs(a.timeIntervalSince(a.startOfDay)) / intervalDuration)
                var indexEnd = floor(abs(d.timeIntervalSince(d.startOfDay)) / intervalDuration)
                if indexEnd == indexStart { continue }
                
                if indexEnd == Double(nbIntervals)-1 {
                    indexEnd = Double(nbIntervals)
                }
                
                let intervalFrame = CGRect(x: CGFloat(indexStart)*intervalSize, y: 0,
                                           width: CGFloat((indexEnd - indexStart))*intervalSize, height: height)
                let view = UIView(frame: intervalFrame)
                view.backgroundColor = visit.place?.getPlaceColor()
                addSubview(view)
            }
        }
    }
}
