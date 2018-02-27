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

class OneTimelineViewController: UIViewController, UIScrollViewDelegate, MGLMapViewDelegate {

    @IBOutlet weak var mapView: MGLMapView?
    @IBOutlet weak var mapViewHeight: NSLayoutConstraint!
    @IBOutlet weak var timeline: ISTimeline!
    
    var timelineTitle: String!
    var timelineSubtitle: String!
    var timelineDay: String!
    var isAnimating = false
    var isFolded = true
    var annotations: [PointAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeline.delegate = self
        timeline.alwaysBounceVertical = true
        mapView?.delegate = self
        
        timeline.contentInset = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0)
        mapView?.zoomLevel = 13
        mapView?.centerCoordinate = CLLocationCoordinate2D(latitude: 51.524543, longitude: -0.132176)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UserUpdateHandler.retrieveLatestUserUpdates(for: DateHandler.dateToDayString(from: Date()))
        reload()
    }
    
    func reload() {
        guard let timeline = self.timeline else { return }
        
        let visits = DataStoreService.shared.getVisits(for: timelineDay)
                
        let touchAction = { [weak self] (point:ISPoint) in
            guard let strongSelf = self else { return }
            
            // Load the place detail view and the navigation controller
            let controller = OneTimelinePlaceDetailViewController()
            controller.visit = point.visit
            
            let controllerNavigation = UINavigationController(rootViewController: controller)
            controllerNavigation.modalTransitionStyle = .crossDissolve
            controllerNavigation.modalPresentationStyle = .fullScreen
            strongSelf.present(controllerNavigation, animated: true, completion: nil)
            // TODO: Implement a push-style animation
        }
        
        let feebackTouchAction = { [weak self] (point: ISPoint) in
            guard let strongSelf = self else { return }
            let controller = PlaceFinderMapTableViewController()
            controller.visit = point.visit
            
            let controllerNavigation = UINavigationController(rootViewController: controller)
            controllerNavigation.modalTransitionStyle = .crossDissolve
            controllerNavigation.modalPresentationStyle = .fullScreen
            strongSelf.present(controllerNavigation, animated: true, completion: nil)
        }
        
        let addPlaceTouchAction = { [weak self] (pt1: ISPoint, pt2: ISPoint) in
            guard let strongSelf = self else { return }
            let controller = PlaceFinderMapTableViewController()
            controller.color = Constants.colors.primaryDark
            controller.name = "Add a place"
            controller.address = "Pick a place with the map and search bar below"
            controller.startDate = pt1.visit?.departure
            controller.endDate = pt2.visit?.arrival
            controller.showDeleteButton = false
            controller.type = .add
            if let place1 = pt1.visit?.place, let place2 = pt2.visit?.place {
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        
        var timelinePoints: [ISPoint] = []
        var count = 0
        for visit in visits {
            let arrivalTime = dateFormatter.string(from: visit.arrival!)
            let departureTime = dateFormatter.string(from: visit.departure!)
            var icon = UIImage(named: "location")!
            let placeName = visit.place!.name!
            let placePersonalInformationIcons = visit.place?.getPersonalInformationIcons()
            let times = "Visited from \(arrivalTime) to \(departureTime)"
            
            if placeName == "Home" {
                icon = UIImage(named: "home")!.withRenderingMode(.alwaysTemplate)
            }
            
            let lineColor = Constants.colors.primaryDark
            
            var showFeedback = true
            if visit.review?.answer == .yes {
                showFeedback = false
            }
            
            let point = ISPoint(title: placeName, description: times, descriptionSupp: placePersonalInformationIcons, pointColor: Constants.colors.primaryLight, lineColor: lineColor, touchUpInside: touchAction, feedbackTouchUpInside: feebackTouchAction, addPlaceTouchUpInside: addPlaceTouchAction, icon: icon, iconBg: Constants.colors.primaryLight, fill: true, showFeedback: showFeedback)
            
            point.visit = visit
            timelinePoints.append(point)
            
            let matchedAnnotation = PointAnnotation()
            matchedAnnotation.coordinate = CLLocationCoordinate2D(latitude: (visit.place?.latitude)!, longitude: (visit.place?.longitude)!)
            matchedAnnotation.title = title
            matchedAnnotation.annotationType = .matched
            annotations.append(matchedAnnotation)
            
            count += 1
        }
        
        timeline.points = timelinePoints
        timeline.bubbleArrows = false
        timeline.timelineTitle = timelineTitle
        timeline.timelineSubtitle = timelineSubtitle
    }
    
    private func showAnnotations() {
        mapView?.addAnnotations(annotations)
        mapView?.showAnnotations(annotations, animated: true)
    }
    
    private func hideAnnotations() {
        mapView?.removeAnnotations(annotations)
    }
    
    private func foldMapView() {
        isAnimating = true
        self.hideAnnotations()
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.mapViewHeight.constant = 0
            self?.view.layoutIfNeeded()
            }, completion: { c in
                if c {
                    self.isAnimating = false
                    self.isFolded = true
                }
        })
    }
    
    private func unfoldMapView() {
        isAnimating = true
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.mapViewHeight.constant = 350
            self?.view.layoutIfNeeded()
            }, completion: { completed in
                if completed {
                    self.isAnimating = false
                    self.isFolded = false
                    self.showAnnotations()
                }
        })
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isAnimating { return }
        let y = scrollView.contentOffset.y
        if !isFolded && y > 350 {
            foldMapView()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if isAnimating { return }
        let y = scrollView.contentOffset.y
        
        if !isFolded && y < -50.0 {
            foldMapView()
        } else if isFolded && y < -50.0 {
            unfoldMapView()
        }
    }
    
    // MARK: -  MGLMapViewDelegate methods
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard let pointAnnotation = annotation as? PointAnnotation else {
            return nil
        }
        
        // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
        let reuseIdentifier = "\(pointAnnotation.coordinate.longitude)"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
            
            // Set the annotation view’s background color to a value determined by its longitude.
            var color = Constants.colors.primaryDark
            if pointAnnotation.annotationType == .matched {
                color = Constants.colors.primaryLight
            }
            annotationView!.backgroundColor = color
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
        print("called dataStoreDidUpdate")
        if day != nil && day == timelineDay {
            reload()
        }
    }
    
    
}

// MGLAnnotationView subclass
class CustomAnnotationView: MGLAnnotationView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force the annotation view to maintain a constant size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Use CALayer’s corner radius to turn this view into a circle.
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Animate the border width in/out, creating an iris effect.
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.duration = 0.1
        layer.borderWidth = selected ? frame.width / 4 : 2
        layer.add(animation, forKey: "borderWidth")
    }
}
