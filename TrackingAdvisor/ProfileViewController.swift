//
//  ProfileViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/5/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class ProfileViewController: UIViewController, UIScrollViewDelegate, MGLMapViewDelegate {
    // set a content view inside the scroll view
    // From https://developer.apple.com/library/content/technotes/tn2154/_index.html
    
    
    var numberOfDaysStudy: Int? { didSet {
        studySummary.bigText.bigText = String(numberOfDaysStudy!)
        if numberOfDaysStudy == 1 {
            studySummary.descriptionText = "This is your first day in the study!"
        } else {
            studySummary.descriptionText = "You have been participating in the study for \(numberOfDaysStudy!) days!"
        }
        
        if numberOfDaysStudy! < 2 {
            studySummary.bigText.smallBottomText = "DAY"
        } else {
            studySummary.bigText.smallBottomText = "DAYS"
        }
    }}
    
    var numberofPlacesVisited: Int? { didSet {
        studyStats.statsOne.bigText = String(numberofPlacesVisited!)
        if numberofPlacesVisited! < 2 {
            studyStats.statsOne.smallBottomText = "PLACE\nVISITED"
        } else {
            studyStats.statsOne.smallBottomText = "PLACES\nVISITED"
        }
    }}
    
    var numberOfAggregatedPersonalInformation: Int? { didSet {
        studyStats.statsTwo.bigText = String(numberOfAggregatedPersonalInformation!)
        if numberOfAggregatedPersonalInformation! < 2 {
            studyStats.statsTwo.smallBottomText = "PERSONAL\nINFORMATION"
        }
    }}
    
    var numberOfPlacesToReviewTotal: Int? { didSet {
        studyStats.statsTwo.bigText = String(numberOfPlacesToReviewTotal!)
        if numberOfPlacesToReviewTotal! < 2 {
            studyStats.statsThree.smallBottomText = "PLACE TO\nREVIEW"
        } else {
            studyStats.statsThree.smallBottomText = "PLACES TO\nREVIEW"
        }
    }}
    
    var mapAnnotations: [CustomPointAnnotation] = []

    var scrollView : UIScrollView!
    var contentView : UIView!
    
    var mainTitle: UILabel = {
        let label = UILabel()
        label.text = "About you"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var studySummary: InfoCardView = {
        return InfoCardView(bigText: BigText(bigText: "XX", topExponent: "", smallBottomText: "DAYS"),
                            descriptionText: "You have been participating in the study for XX days!")
    }()
    
    var studyStats: StatsCardView = {
        return StatsCardView(statsOne: BigText(bigText: "0", smallBottomText: "PLACES\nVISITED"),
                             statsTwo: BigText(bigText: "0", smallBottomText: "PERSONAL\nINFORMATION"),
                             statsThree: BigText(bigText: "0", smallBottomText: "PLACES TO\nREVIEW"))
    }()
    
    var mapView: MGLMapView = {
        let map = MGLMapView(frame: CGRect(), styleURL: MGLStyle.lightStyleURL())
        map.zoomLevel = 15
        map.translatesAutoresizingMaskIntoConstraints = false
        map.layer.cornerRadius = 5.0
        map.layer.shadowRadius = 5.0
        map.layer.shadowOpacity = 0.5
        map.layer.shadowOffset = CGSize(width: 5, height: 5)
        map.backgroundColor = Constants.colors.superLightGray
        map.allowsZooming = false
        map.allowsTilting = false
        map.allowsRotating = false
        map.allowsScrolling = false
        
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
        let map = MGLMapView(frame: CGRect(), styleURL: MGLStyle.lightStyleURL())
        map.zoomLevel = 15
        map.backgroundColor = Constants.colors.superLightGray
        map.attributionButton.alpha = 0
        map.logoView.alpha = 0
        
        // Center the map on the visit coordinates
        let coordinates = CLLocationCoordinate2D(latitude: 51.524528, longitude: -0.134524)
        map.centerCoordinate = coordinates
        return map
    }()
    
    var iconExitMapView: RoundIconView = {
        return RoundIconView(image: UIImage(named: "times")!, color: Constants.colors.primaryDark, imageColor: .white)
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        computeData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: self.view.frame)
        scrollView.sizeToFit()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.white
        self.view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.white
        scrollView.addSubview(contentView)
        
        let margins = self.view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: margins.topAnchor)
        ])
        self.view.addVisualConstraint("H:|[scrollView]|", views: ["scrollView" : scrollView])
        self.view.addVisualConstraint("V:[scrollView]|",  views: ["scrollView" : scrollView])
        
        scrollView.addVisualConstraint("H:|[contentView]|", views: ["contentView" : contentView])
        scrollView.addVisualConstraint("V:|[contentView]|", views: ["contentView" : contentView])
        
        // make the width of content view to be the same as that of the containing view.
        self.view.addVisualConstraint("H:[contentView(==mainView)]", views: ["contentView" : contentView, "mainView" : self.view])

        scrollView.delegate = self
        mapView.delegate = self
        
        setupViews()
        computeData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupViews() {
        contentView.addSubview(mainTitle)
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        contentView.addVisualConstraint("V:|-48-[v0(40)]", views: ["v0": mainTitle])

        contentView.addSubview(studySummary)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0":studySummary])
        contentView.addVisualConstraint("V:[v0]-16-[v1]", views: ["v0": mainTitle, "v1":studySummary])
        
        
        contentView.addSubview(studyStats)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0":studyStats])
        contentView.addVisualConstraint("V:[v0]-16-[v1]", views: ["v0": studySummary, "v1":studyStats])
        
        contentView.addSubview(mapView)
        mapView.addTapGestureRecognizer {
            self.animateMapViewIn()
        }
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0":mapView])
        contentView.addVisualConstraint("V:[v0]-16-[v1(250)]-32-|", views: ["v0": studyStats, "v1":mapView])
    }
    
    // MARK: - MGLMapViewDelegate protocol
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let point = annotation as? CustomPointAnnotation,
            
            let image = point.image,
            let reuseIdentifier = point.reuseIdentifier {
            
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
        return true
    }
    
    func animateMapViewIn() {
        if let startingFrame = mapView.superview?.convert(mapView.frame, to: nil) {
            mapView.alpha = 0
            zoomMapView.frame = startingFrame
            zoomMapView.delegate = self
            
            self.view.addSubview(zoomMapView)
            
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.zoomMapView.frame = CGRect(x: 0, y: -1 * UIApplication.shared.statusBarFrame.height, width: self.view.frame.width, height: self.view.frame.height)
            }, completion: { didComplete in
                if didComplete {
                    self.iconExitMapView.frame = CGRect(x: 20, y: UIApplication.shared.statusBarFrame.height + 10, width: 30, height: 30)
                    self.iconExitMapView.addTapGestureRecognizer {
                        self.animateMapViewOut()
                    }
                    self.view.addSubview(self.iconExitMapView)
                    self.zoomMapView.addAnnotations(self.mapAnnotations)
                    self.zoomMapView.showAnnotations(self.mapAnnotations, animated: true)
                }
            })
        }
    }
    
    func animateMapViewOut() {
        if let startingFrame = mapView.superview?.convert(mapView.frame, to: nil) {
            self.iconExitMapView.removeFromSuperview()
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.zoomMapView.frame = startingFrame
            }, completion: { didComplete in
                if didComplete {
                    self.zoomMapView.removeFromSuperview()
                    self.mapView.alpha = 1
                }
            })
        }
    }
    
    func computeData() {
        // get all visits
        let allVisits = DataStoreService.shared.getAllVisits()
        let today = Date()
        
        // compute the number of days since the start of the study
        if let firstVisit = allVisits.first {
            numberOfDaysStudy = today.numberOfDays(to: firstVisit.arrival)! + 1
        }
        
        if allVisits.count == 0 {
            numberOfDaysStudy = 0
            return
        }
        
        // compute the number of places visited
        let placeIds = allVisits.map { $0.placeid! }
        let uniquePlaceIds = Array(Set(placeIds))
        numberofPlacesVisited = uniquePlaceIds.count
        
        let placesToReview = DataStoreService.shared.getAllPlacesToReview(sameContext: true)
        numberOfPlacesToReviewTotal = placesToReview.count
        
        let aggregatedPersonalInformation = DataStoreService.shared.getAllAggregatedPersonalInformation(sameContext: true)
        numberOfAggregatedPersonalInformation = aggregatedPersonalInformation.count
        
        // put all the places in the map
        mapAnnotations.removeAll()
        for v in allVisits {
            guard let p = v.place else { return }
            
            var color = Constants.colors.midPurple
            let dayOfWeek = v.arrival?.dayOfWeek
            if dayOfWeek == 1 || dayOfWeek == 7 {
                color = Constants.colors.orange
            }
            
            let count = mapAnnotations.count + 1
            let pointAnnotation = CustomPointAnnotation(coordinate: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude), title: p.name, subtitle: nil)
            pointAnnotation.reuseIdentifier = "customAnnotation\(count)"
            // This dot image grows in size as more annotations are added to the array.
            pointAnnotation.image = dot(size:20, color: color)
            
            mapAnnotations.append(pointAnnotation)
        }
        
        mapView.addAnnotations(mapAnnotations)
        mapView.showAnnotations(mapAnnotations, animated: false)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


