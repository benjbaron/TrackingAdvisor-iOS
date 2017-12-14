//
//  PositionMapModalViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/8/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class PositionMapModalViewController: UIViewController, MGLMapViewDelegate {

    @IBAction func done(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }

    var filename: String?
    var file: URL?
    var annotations: [MGLPointAnnotation] = []
    
    @IBOutlet weak var map: MGLMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = filename
        map?.delegate = self
        
        map?.zoomLevel = 13
        map?.centerCoordinate = CLLocationCoordinate2D(latitude: 51.524543, longitude: -0.132176)
        
        guard let file = self.file else { return }
        // Read the CSV file
        let data = FileService.shared.read(from: file)
        let lines = data.components(separatedBy: .newlines)
        for line in lines[1...] {
            let fields = line.split(separator: ",")
            if fields.count < 6 {
                continue
            }
            
            let latitude = Double("\(fields[1])")
            let longitude = Double("\(fields[2])")
            let annotationTitle = "\(fields[3])"
            
            let annotation = MGLPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            annotation.title = annotationTitle
            annotations.append(annotation)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func showAnnotations() {
        map?.addAnnotations(annotations)
        map?.showAnnotations(annotations, animated: true)
    }
    
    // MARK: -  MGLMapViewDelegate methods
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
        let reuseIdentifier = "\(annotation.coordinate.longitude)"
        
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
            
            // Set the annotation view’s background color to a value determined by its longitude.
            let color = Constants.colors.primaryDark
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
