//
//  OneTimelineViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/6/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

enum MapViewState {
    case folded
    case full
    case half
}

enum PointAnnotationType {
    case original
    case matched
}

class PointAnnotation: MGLPointAnnotation {
    var annotationType: PointAnnotationType?
}

class OneTimelineViewController: UIViewController, UIScrollViewDelegate, MGLMapViewDelegate, TutorialOverlayViewDelegate {
    
    var mapView: MGLMapView!
    var mapViewHeight: NSLayoutConstraint!
    var timeline: ISTimeline!
    
    var mapCloseView: CloseView!
    
    var timelineTitle: String!
    var timelineSubtitle: String!
    var timelineDay: String!
    var canUpdate: Bool = true
    var isAnimating = false
    var isFolding: Bool?
    var freeScroll = false
    var isFolded = true
    var lowerHeight: CGFloat = UIScreen.main.bounds.height - 210.0
    let upperHeight:CGFloat = 125.0
    var lastOffset:CGFloat = 0.0
    var annotations: [String:CustomPointAnnotation] = [:]
    
    var backgroundView: UIView!
    var backgroundMarginView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        timeline = ISTimeline(frame: .zero, showRings: Settings.getShowActivityRings())
        timeline.delegate = self
        timeline.alwaysBounceVertical = true
        timeline.translatesAutoresizingMaskIntoConstraints = false
        timeline.contentInset = UIEdgeInsets(top: upperHeight + 20.0, left: 20.0, bottom: 20.0, right: 20.0)
        
        backgroundView = UIView(frame: .zero)
        backgroundView.backgroundColor = UIColor.white
        
        backgroundMarginView = UIView(frame: .zero)
        backgroundMarginView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        
        mapView = MGLMapView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), styleURL: MGLStyle.streetsStyleURL)
        mapView.zoomLevel = 15
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 51.524543, longitude: -0.132176)
        mapView.maximumZoomLevel = 15.0
        mapView.allowsRotating = false
        mapView.allowsTilting = false
        mapView.delegate = self
        mapView.userTrackingMode = .none
        
        // setup views
        self.view.addSubview(mapView)
        self.view.addSubview(backgroundMarginView)
        self.view.addSubview(backgroundView)
        self.view.addSubview(timeline)
        
        self.view.addVisualConstraint("H:|[timeline]|", views: ["timeline": timeline])
        self.view.addVisualConstraint("V:|[timeline]|", views: ["timeline": timeline])
        
        // Adapt lowerHeight depending on the phone type
        if AppDelegate.isIPhoneX() {
            lowerHeight -= 65.0
        }

        mapView.frame = CGRect(x: 0,y: -175,
                               width: UIScreen.main.bounds.width, height: lowerHeight)
        
        backgroundView.frame = CGRect(x: 0, y: upperHeight,
                                      width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        backgroundMarginView.frame = CGRect(x: 0, y: upperHeight-10.0,
                                      width: UIScreen.main.bounds.width, height: 5.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LogService.shared.log(LogService.types.timelineDay,
                              args: [LogService.args.day: timelineDay])
        
        let numberOfVisitsToReview = DataStoreService.shared.getNumberOfVisitsToReview(for: timelineDay, ctxt: nil)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateTimelineBadge(with: numberOfVisitsToReview)
        
        reload()
        
        if !Settings.getTutorial() {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                let overlayView = TutorialOverlayView()
                overlayView.delegate = self
                OverlayView.shared.delegate = overlayView
                OverlayView.shared.showOverlay(with: overlayView)
            }
        }
    }
    
    // MARK: - TutorialOverlayViewDelegate method
    func tutorialFinished() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateTabBadges()
        Settings.staveTutorial(value: true)
        reload()
    }
    
    func reload() {
        guard let timeline = self.timeline else { return }
        
        let visits = DataStoreService.shared.getVisits(for: timelineDay, ctxt: nil)
        updateLastVisit(from: visits)
        annotations.removeAll()
        
        let touchAction = { [weak self] (point:ISPoint) in
            guard let strongSelf = self else { return }
            
            // Load the place detail view and the navigation controller
            let controller = OneTimelinePlaceDetailViewController()
            controller.vid = point.visit?.id
            
            let controllerNavigation = UINavigationController(rootViewController: controller)
            controllerNavigation.modalTransitionStyle = .crossDissolve
            controllerNavigation.modalPresentationStyle = .fullScreen
            strongSelf.present(controllerNavigation, animated: true, completion: nil)
            // TODO: Implement a push-style animation
        }
        
        let feedbackTouchAction = { [weak self] (point: ISPoint) in
            guard let strongSelf = self else { return }
            
            let controller = PlaceFinderMapTableViewController()
            controller.visit = point.visit
            
            if let vid = point.visit?.id {
                LogService.shared.log(LogService.types.timelineFeedback,
                                      args: [LogService.args.day: strongSelf.timelineDay,
                                             LogService.args.visitId: vid,
                                             LogService.args.value: "edit"])
            }
            
            let controllerNavigation = UINavigationController(rootViewController: controller)
            controllerNavigation.modalTransitionStyle = .crossDissolve
            controllerNavigation.modalPresentationStyle = .fullScreen
            strongSelf.present(controllerNavigation, animated: true, completion: nil)
        }
        
        let visitValidatedTouchAction = { [weak self] (_ point: ISPoint?) in
            guard let strongSelf = self else { return }
            
            if let vid = point?.visit?.id, let pid = point?.visit?.place?.id {
                point?.visit?.visited = 1
                LogService.shared.log(LogService.types.timelineFeedback,
                                      args: [LogService.args.day: strongSelf.timelineDay,
                                             LogService.args.visitId: vid,
                                             LogService.args.value: "yes"])
                UserUpdateHandler.visitedVisit(for: vid) {
                    DataStoreService.shared.updateVisit(with: vid, visited: 1)
                    let numberOfVisitsToReview = DataStoreService.shared.getNumberOfVisitsToReview(for: strongSelf.timelineDay, ctxt: nil)
                    timeline.numberOfVisitsToReview = numberOfVisitsToReview
                    
                    // update the user stats
                    UserStats.shared.updateVisitConfirmed()
                    UserStats.shared.updatePlacePersonalInformation()
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.updateTimelineBadge(with: numberOfVisitsToReview)
                    
                    // update the map
                    if let a = strongSelf.annotations[pid] {
                        a.color = Constants.colors.midPurple
                        strongSelf.showAnnotations()
                    }
                }
            }
        }
        
        let visitRemovedTouchAction = { [weak self] (_ point: ISPoint?) in
            guard let strongSelf = self else { return }
            
            if let vid = point?.visit?.id, let pid = point?.visit?.place?.id {
                LogService.shared.log(LogService.types.timelineFeedback,
                                      args: [LogService.args.day: strongSelf.timelineDay,
                                             LogService.args.visitId: vid,
                                             LogService.args.value: "delete"])
                UserUpdateHandler.deleteVisit(for: vid) {
                    DataStoreService.shared.deleteVisit(vid: vid, ctxt: nil)
                    let numberOfVisitsToReview = DataStoreService.shared.getNumberOfVisitsToReview(for: strongSelf.timelineDay, ctxt: nil)
                    timeline.numberOfVisitsToReview = numberOfVisitsToReview
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.updateTimelineBadge(with: numberOfVisitsToReview)
                    UserStats.shared.updateVisitConfirmed()
                    
                    // update the map
                    if let a = strongSelf.annotations[pid] {
                        strongSelf.annotations.removeValue(forKey: pid)
                        strongSelf.mapView.removeAnnotation(a)
                    }
                }
            }
        }
        
        let addPlaceTouchAction = { [weak self] (pt1: ISPoint?, pt2: ISPoint?) in
            guard let strongSelf = self else { return }
            
            let controller = PlaceFinderMapTableViewController()
            controller.color = Constants.colors.primaryDark
            controller.name = "Add a place"
            controller.address = "Pick a place with the map and search bar below"
            
            if let startPt = pt1 {
                controller.startDate = startPt.visit?.arrival?.startOfDay
                controller.endDate = startPt.visit?.arrival
            }
            if let endPt = pt2 {
                controller.startDate = endPt.visit?.departure
                controller.endDate = endPt.visit?.departure?.endOfDay
            }
            if let startPt = pt1, let endPt = pt2 {
                controller.startDate = startPt.visit?.departure
                controller.endDate = endPt.visit?.arrival
            }
            
            controller.showDeleteButton = false
            controller.type = .add
            if let place1 = pt1?.visit?.place {
                controller.latitude = place1.latitude
                controller.longitude = place1.longitude
            }
            if let place2 = pt2?.visit?.place {
                controller.latitude = place2.latitude
                controller.longitude = place2.longitude
            }
            if let place1 = pt1?.visit?.place, let place2 = pt2?.visit?.place {
                let coords = CLLocationCoordinate2D.middlePoint(of: [
                    CLLocationCoordinate2D(latitude: place1.latitude, longitude: place1.longitude),
                    CLLocationCoordinate2D(latitude: place2.latitude, longitude: place2.longitude) ])
                controller.latitude = coords.latitude
                controller.longitude = coords.longitude
            }
            
            let controllerNavigation = UINavigationController(rootViewController: controller)
            controllerNavigation.modalTransitionStyle = .crossDissolve
            controllerNavigation.modalPresentationStyle = .fullScreen
            strongSelf.present(controllerNavigation, animated: true, completion: nil)
        }
        
        let updateTimelineTouchAction = { [weak self] (sender: UIButton) in
            guard let strongSelf = self else { return }
            if !strongSelf.canUpdate { return }
            
            LogService.shared.log(LogService.types.timelineUpdate,
                                  args: [LogService.args.day: strongSelf.timelineDay])
            
            strongSelf.canUpdate = false
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.canUpdate = true
            }
            UserUpdateHandler.retrieveLatestUserUpdates(for: strongSelf.timelineDay, force: true) {
                DataStoreService.shared.resetContext()
                strongSelf.reload()
                let numberOfVisitsToReview = DataStoreService.shared.getNumberOfVisitsToReview(for: strongSelf.timelineDay, ctxt: nil)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.updateTimelineBadge(with: numberOfVisitsToReview)
                UserStats.shared.updateVisitConfirmed()
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        
        var timelinePoints: [ISPoint] = []
        var placeSet: Set<String> = Set<String>()
        var count = 0
        for visit in visits {
            guard let arrival = visit.arrival, let departure = visit.departure,
                  let placeName = visit.place?.name, let pid = visit.place?.id else { continue }
            
            let arrivalTime = dateFormatter.string(from: arrival)
            let departureTime = dateFormatter.string(from: departure)
            var icon = UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate)
            if let placeIcon = visit.place?.icon {
                icon = UIImage(named: placeIcon)!.withRenderingMode(.alwaysTemplate)
            }
            let placePersonalInformationIcons = visit.place?.getPersonalInformationIcons()
            let times = "Visited from \(arrivalTime) to \(departureTime)"
                        
            let lineColor = Constants.colors.primaryDark
            
            var label: String?
            var labelColor: UIColor?
            if let placeType = visit.place?.placetype {
                if placeType == 1 {
                    label = "Home"
                    labelColor = Constants.colors.primaryLight
                } else if placeType == 3 {
                    label = "Work"
                    labelColor = Constants.colors.primaryLight
                } else if placeType == 4 {
                    label = "Work"
                    labelColor = Constants.colors.primaryDark
                }
            }
            
            var showFeedback = true
            if visit.visited != 0 {
                showFeedback = false
            }
            
            let point = ISPoint(
                title: placeName,
                label: label,
                description: times,
                descriptionSupp: placePersonalInformationIcons,
                pointColor: Constants.colors.primaryLight,
                lineColor: lineColor,
                labelColor: labelColor,
                touchUpInside: touchAction,
                feedbackTouchUpInside: feedbackTouchAction,
                addPlaceTouchUpInside: addPlaceTouchAction,
                icon: icon,
                iconBg: Constants.colors.primaryLight,
                fill: true,
                showFeedback: showFeedback)
            
            point.visit = visit
            timelinePoints.append(point)
            
            if !placeSet.contains(pid) {
                let coordinate = CLLocationCoordinate2D(latitude: (visit.place?.latitude) ?? 0.0, longitude: (visit.place?.longitude) ?? 0.0)
                let annotation = CustomPointAnnotation(coordinate: coordinate, title: placeName, subtitle: nil)
                annotation.image = icon
                if visit.visited == 0 {
                    annotation.color = Constants.colors.lightGray
                } else if visit.visited == 1 {
                    annotation.color = Constants.colors.midPurple
                }
                annotation.reuseIdentifier = pid
                annotations[pid] = annotation
                placeSet.insert(pid)
            }
            
            count += 1
        }
        
        timeline.showRings = Settings.getShowActivityRings() && ActivityService.isServiceActivated()
        timeline.points = timelinePoints
        timeline.bubbleArrows = false
        timeline.timelineTitle = timelineTitle
        timeline.timelineSubtitle = timelineSubtitle
        timeline.timelineUpdateTouchAction = updateTimelineTouchAction
        timeline.timelimeAddPlaceFirstTouchAction = addPlaceTouchAction
        timeline.timelimeAddPlaceLastTouchAction = addPlaceTouchAction
        timeline.timelineValidatedPlaceTouchAction = visitValidatedTouchAction
        timeline.timelineRemovedPlaceTouchAction = visitRemovedTouchAction
        timeline.numberOfVisitsToReview = DataStoreService.shared.getNumberOfVisitsToReview(for: timelineDay, ctxt: nil)
        
        if !ActivityService.isServiceActivated() {
            print("reload timeline - Activity services are not activated")
            return
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let strongSelf = self else { return }
                // get the pedometer data for the current day
                let pedometerData = DataStoreService.shared.getPedometerData(for: strongSelf.timelineDay, ctxt: nil)
                
                let steps = pedometerData.map({ $0.numberOfSteps }).reduce(0, +)
                let time = pedometerData.map({ $0.duration }).reduce(0, +)
                var distance = pedometerData.map({ $0.distance / 1000 }).reduce(0, +)
                
                if Settings.getPedometerUnit()?.lowercased() == "miles" {
                    distance /= 1.60934
                }
                
                let stepsProgress = Double(steps) / Double(Settings.getPedometerStepsGoal())
                let timeProgress = Double(time) / Double(Settings.getPedometerTimeGoal())
                let distanceProgress = Double(distance) / Double(Settings.getPedometerDistanceGoal())
                
                timeline.ringDistanceUnit = Settings.getPedometerUnit() ?? "miles"
                timeline.ringSteps = Int(steps)
                timeline.ringTime = time
                timeline.ringDistance = distance
                timeline.ringStepsProgress = stepsProgress
                timeline.ringTimeProgress = timeProgress
                timeline.ringDistanceProgress = distanceProgress
            }
        }
        
        showAnnotations()
    }
    
    private func updateLastVisit(from visits: [Visit]) {
        if  let lastVisit = visits.last,
            let lon = lastVisit.place?.longitude,
            let lat = lastVisit.place?.latitude,
            let lastKnownLocation = Settings.getLastKnownLocation() {
            
            let now = Date()
            let todayStr = DateHandler.dateToDayString(from: now)
            // if distance within the last known location
            let visitLocation = CLLocation(latitude: lat, longitude: lon)
            let distance = visitLocation.distance(from: lastKnownLocation)
            
            if todayStr == timelineDay && distance <= 50 {
                lastVisit.departure = now
            }
        }
    }
    
    private func showAnnotations() {
        if let a = mapView.annotations {
            for annotation in a {
                mapView.removeAnnotation(annotation)
            }
        }
        
        let a = Array(annotations.values)
        mapView?.addAnnotations(a)
        mapView?.showAnnotations(a, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y
        
        var headerFrame = mapView.frame
        
        let factor = 150.0 / (lowerHeight - upperHeight)
        let yMapOffset = max(-150.0, min(25, -150.0 - (upperHeight + scrollOffset) * factor))
                
        if (self.lastOffset > scrollOffset) && (scrollOffset < -1*upperHeight - 35.0) && (scrollOffset > -1*lowerHeight + 15.0) {
            // move up
            isFolding = false
        }
        else if (self.lastOffset < scrollOffset) && (scrollOffset < -1*upperHeight - 35.0) && (scrollOffset > -1*lowerHeight + 15.0) {
            // move down
            isFolding = true
        }
        
        if scrollOffset > -1*upperHeight + 50.0 {
            freeScroll = true
        } else {
            freeScroll = false
        }
        
        // Update the mapView parallax effect
        if scrollOffset < 0 {
            headerFrame = CGRect(x: mapView.frame.origin.x, y: yMapOffset,
                                 width: mapView.frame.size.width, height: lowerHeight-20.0)

            mapView.frame = headerFrame
        }
        
        backgroundView.frame = CGRect(x: 0, y: max(0.0,-1*(scrollOffset+20.0)), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        backgroundMarginView.frame = CGRect(x: 0, y: max(-10.0,-1*(scrollOffset+25.0)), width: UIScreen.main.bounds.width, height: 5.0)
        lastOffset = scrollOffset
        
        if scrollOffset <= -1*lowerHeight {
            self.view.bringSubview(toFront: mapView)
            self.view.bringSubview(toFront: backgroundMarginView)
        } else {
            self.view.sendSubview(toBack: mapView)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        setContentOffset(scrollView)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        setContentOffset(scrollView)
    }
    
    func setContentOffset(_ scrollView: UIScrollView) {
        guard let isFolding = isFolding, !freeScroll else { return }
        
        let anchor = isFolding ? -1*(upperHeight+20.0) : -1*lowerHeight
            
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: anchor), animated: true)
        
        scrollView.isScrollEnabled = true
        isFolded = !isFolded
    }

    
    // MARK: -  MGLMapViewDelegate methods
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        guard let point = annotation as? CustomPointAnnotation,
            let image = point.image, let color = point.color,
            let reuseIdentifier = point.reuseIdentifier else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            let av = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            av.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            av.image = image
            av.backgroundColor = color
            
            annotationView = av
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        showAnnotations()
    }
    
    // DataStoreUpdateProtocol methods
    func dataStoreDidUpdate(for day: String?) {
        if day != nil && day == timelineDay {
            reload()
        }
    }
}

// MGLAnnotationView subclass
class CustomAnnotationView: MGLAnnotationView {
    var image: UIImage?
    var wasSelected = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force the annotation view to maintain a constant size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Use CALayer’s corner radius to turn this view into a circle.
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        layer.contentsScale = UIScreen.main.scale
        
        if let image = image {
            let imageView = UIImageView(image: image)
            imageView.tintColor = .white
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 5, y: 5, width: frame.width-10, height: frame.height-10)
            
            addSubview(imageView)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if !selected && !wasSelected {
            return
        }
        
        let scaleAnimate = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimate.fromValue = selected ? 1 : 1.25
        scaleAnimate.toValue = selected ? 1.25 : 1
        scaleAnimate.duration = 0.2
        scaleAnimate.isRemovedOnCompletion = false
        scaleAnimate.fillMode = kCAFillModeForwards
        layer.add(scaleAnimate, forKey: "transform.scale")
        wasSelected = true
    }
}
