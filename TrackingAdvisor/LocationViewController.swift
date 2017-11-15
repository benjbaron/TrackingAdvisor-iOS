//
//  ViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 10/25/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import MapKit


struct ServerResponse: Decodable {
    let submitted: String
}

enum RequestResult<Value> {
    case success(Value)
    case failure(Error)
}

enum MapCircleType {
    case point
    case surrounding
    case center
}

class MapCircle: MKCircle {
    var type: MapCircleType = .center
    convenience init(center coord: CLLocationCoordinate2D, radius: CLLocationDistance, type: MapCircleType) {
        self.init(center: coord, radius: radius)
        self.type = type
    }
}

class LocationViewController: UIViewController, MKMapViewDelegate, LocationRegionUpdateProtocol {

    // MARK - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView?
    @IBOutlet weak var lat: UILabel?
    @IBOutlet weak var ts: UILabel?
    @IBOutlet weak var lon: UILabel?
    @IBOutlet weak var steps: UILabel!
    
    // MARK - IBActions
    
    @IBAction func startStopLocationMonitoring(_ sender: UISwitch) {
        if sender.isOn {
            startLocationMonitoring()
            isLocationMonitored = true
            //            mapView.showsUserLocation = true
        } else {
            stopLocationMonitoring()
            isLocationMonitored = false
            //            mapView.showsUserLocation = false
        }
    }
    
    // MARK - member variables
    
    let radius: Double = 10.0
    var locationService = LocationRegionService.shared
    var isLocationMonitored = false
    var currentLocation: UserLocation? { didSet {
            updateUI()
        }
    }
    var sessionConfig:URLSessionConfiguration {
        let backgroundSessionConfig = URLSessionConfiguration.background(withIdentifier: "uk.ac.ucl.trackingadvisor")
        backgroundSessionConfig.isDiscretionary = true
        return backgroundSessionConfig
    }
    
    // MARK - view lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationService.delegate = self
        mapView?.delegate = self
        updateUI()
    }
    
    private func updateUI() {
        guard let loc = currentLocation else { return }
        self.lat?.text = String(format:"%.6f", loc.latitude)
        self.lon?.text = String(format:"%.6f", loc.longitude)
        self.ts?.text = loc.timestampString()
        self.steps.text = String(format:"%.6f", loc.speed)
    }
    
    // MARK - Start / stop location monitoring
    
    private func startLocationMonitoring() {
        locationService.startUpdatingLocation()
    }
    
    private func stopLocationMonitoring() {
        locationService.stopUpdatingLocation()
    }
    
    private func addLocationToMap(_ location: UserLocation) {
        // zoom the map on this position
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.003, 0.003)
        let coordinates = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(coordinates, span)
        
        // remove the previous regions
        if let overlays = self.mapView?.overlays {
            for overlay in overlays {
                print("overlay \(overlay)")
                if let circle = overlay as? MapCircle {
                    if circle.type == .surrounding || circle.type == .center {
                        print("remove overlay")
                        self.mapView?.remove(overlay)
                    }
                }
            }
        }
        
        // add the region overlays
        for region in locationService.currentRegions {
            let circle = MapCircle(center: region.center, radius: region.radius, type: .center)
            self.mapView?.add(circle)
        }
        for region in locationService.regions {
            let circle = MapCircle(center: region.center, radius: region.radius, type: .surrounding)
            self.mapView?.add(circle)
        }
        
        let circle = MapCircle(center: coordinates, radius: radius, type: .point)
        self.mapView?.add(circle)
        
        // update the map view
        self.mapView?.setRegion(region, animated: true)
    }

    
    // MARK - LocationUpdateProtocol
    
    func locationDidUpdate(location: UserLocation, type: LocationRegionUpdateType) {
        addLocationToMap(location)
        currentLocation = location
        
        // Print stats
        let coordinates = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)

        if UIApplication.shared.applicationState == .active {
            print("App is in foreground. New location is \(coordinates)")
        } else {
            print("App is backgrounded. New location is \(coordinates)")
        }
    }
    
    // MARK - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? MapCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKCircleRenderer(circle: circle)
        switch circle.type {
        case .point:
            renderer.fillColor = UIColor.red.withAlphaComponent(0.50)
        case .surrounding:
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.15)
        case .center:
            renderer.fillColor = UIColor.green.withAlphaComponent(0.10)
        }
        renderer.strokeColor = UIColor.white.withAlphaComponent(0.70)
        renderer.lineWidth = 3
        return renderer
    }

}

