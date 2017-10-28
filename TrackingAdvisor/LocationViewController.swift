//
//  ViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 10/25/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion
import CoreData


struct UserLocation: Encodable {
    let userID: String
    let longitude: Double
    let latitude: Double
    let magX: Double
    let magY: Double
    let magZ: Double
    let timestamp: Int
    let type: String
}

struct ServerResponse: Decodable {
    let submitted: String
}

enum RequestResult<Value> {
    case success(Value)
    case failure(Error)
}

class LocationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView?
    @IBOutlet weak var lat: UILabel?
    @IBOutlet weak var ts: UILabel?
    @IBOutlet weak var lon: UILabel?
    @IBOutlet weak var pendingLocationsLabel: UILabel?
    
    @IBOutlet weak var sendingDataWheel: UIActivityIndicatorView?
    
    @IBAction func sendDataToServer(_ sender: Any) {
        sendingDataWheel?.startAnimating()
        sendPendingUserLocationsToServer() { (result) in
            self.sendingDataWheel?.stopAnimating()
            switch result {
            case .failure(let error):
                fatalError(error.localizedDescription)
            case .success(let serverResponse):
                print("submitted: \(serverResponse.submitted)")
                self.pendingUserLocations.removeAll()
                self.updateUI()
            }
        }
    }
    
    @IBAction func placeType(_ sender: UISegmentedControl) {
        let placeTypeValues = [
            "train",
            "tube",
            "park",
            "starbucks",
            "mcdonalds",
            "none"]
        
        currentPlaceType = placeTypeValues[sender.selectedSegmentIndex]
    }
    
    // MARK - member variables
    let radius: Double = 10.0
    var locationManager = CLLocationManager()
    var motionManager = CMMotionManager()
    var currentPlaceType: String = "none"
    var pendingUserLocations: [UserLocation] = []
    var currentLocation: UserLocation? { didSet {
            if let loc = currentLocation {
                pendingUserLocations.append(loc)
                updateUI()
            }
        }
    }
    
    // MARK - view lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure the map view delegate
        mapView?.delegate = self
        
        // configure the location manager delegate
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        updateUI()
    }

    @IBAction func startStopLocationMonitoring(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startUpdatingLocation()
            motionManager.startMagnetometerUpdates()
//            mapView.showsUserLocation = true
        } else {
            locationManager.stopUpdatingLocation()
            motionManager.stopMagnetometerUpdates()
//            mapView.showsUserLocation = true
        }
    }
    
    private func dateToSting(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func dateToSting(timestamp: Int) -> String {
        return dateToSting(date: Date(timeIntervalSince1970: Double(timestamp)))
    }
    
    private func updateUI() {
        guard let loc = currentLocation else { return }
        self.lat?.text = String(format:"%.6f", loc.latitude)
        self.lon?.text = String(format:"%.6f", loc.longitude)
        self.ts?.text = dateToSting(timestamp: loc.timestamp)
        
        if pendingUserLocations.count > 0 {
            self.pendingLocationsLabel?.text = "\(pendingUserLocations.count) locations pending"
        } else {
            self.pendingLocationsLabel?.text = ""
        }
        print(dateToSting(timestamp: loc.timestamp))
    }
    
    private func saveLocation(of location: CLLocation, and magneticField: CMMagneticField? = nil) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Location", in: managedContext)!
        let loc = NSManagedObject(entity: entity, insertInto: managedContext)
        
        loc.setValue(location.coordinate.latitude, forKey: "latitude")
        loc.setValue(location.coordinate.longitude, forKey: "longitude")
        loc.setValue(location.timestamp, forKey: "timestamp")
        
        if let mf = magneticField {
            loc.setValue(mf.x, forKey: "magX")
            loc.setValue(mf.y, forKey: "magY")
            loc.setValue(mf.z, forKey: "magZ")
        }
        
        loc.setValue(currentPlaceType, forKey: "type")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    private func sendPendingUserLocationsToServer(completion: ((RequestResult<ServerResponse>) -> Void)?) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "tracemap.herokuapp.com"
        urlComponents.path = "/upload"
        guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
        
        // Specify this request as being a POST method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Make sure that we include headers specifying that our request's HTTP body
        // will be JSON encoded
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        // Now let's encode out UserLocation struct into a JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(pendingUserLocations)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
            print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        } catch {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
            completion?(.failure(error))
        }
        
        // Create and run a URLSession data task with our JSON encoded POST request
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                guard responseError == nil else {
                    completion?(.failure(responseError!))
                    return
                }
                
                guard let jsonData = responseData else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                    completion?(.failure(error))
                    return
                }

                
                // APIs usually respond with the data you just sent in your POST request
                let decoder = JSONDecoder()
                do {
                    let result = try decoder.decode(ServerResponse.self, from: jsonData)
                    completion?(.success(result))

                } catch {
                    completion?(.failure(error))
                }
            }
        }
        task.resume()
    }


    // MARK - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        // zoom the map on this position
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.003, 0.003)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(location.coordinate, span)

        // update the map view
        self.mapView?.setRegion(region, animated: true)
        
        let circle = MKCircle(center: location.coordinate, radius: radius)
        self.mapView?.add(circle)
        
        // save the location and magneticField data in the database
        guard let mf = motionManager.magnetometerData?.magneticField else {
            return
        }
        saveLocation(of: location, and: mf)
        currentLocation = UserLocation(userID: "me",
                                       longitude: location.coordinate.longitude,
                                       latitude: location.coordinate.latitude,
                                       magX: mf.x,
                                       magY: mf.y,
                                       magZ: mf.z,
                                       timestamp: Int(location.timestamp.timeIntervalSince1970),
                                       type: currentPlaceType)
        
        if UIApplication.shared.applicationState == .active {
            print("App is in foreground. New location is \(location.coordinate)")
        } else {
            print("App is backgrounded. New location is \(location.coordinate)")
        }
    }
    
    
    // MARK - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? MKCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKCircleRenderer(circle: circle)
        renderer.fillColor = UIColor.red.withAlphaComponent(0.30)
        renderer.strokeColor = UIColor.white.withAlphaComponent(0.70)
        renderer.lineWidth = 3
        return renderer
    }

}

