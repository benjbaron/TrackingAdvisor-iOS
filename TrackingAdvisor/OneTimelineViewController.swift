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

class OneTimelineViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var mapViewHeight: NSLayoutConstraint!
    @IBOutlet weak var timeline: ISTimeline!
    
    var timelineTitle: String!
    var isAnimating = false
    var isFolded = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeline.delegate = self
        
        let touchAction = { (point:ISPoint) in
            print("point \(point.title)")
        }
        
        let timelinePoints = [
            ISPoint(title: "06:46 AM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.", pointColor: Constants.primaryLight, lineColor: Constants.primaryDark, touchUpInside: touchAction, icon: UIImage(named: "location")!, iconBg: Constants.primaryLight, fill: true),
            ISPoint(title: "07:00 AM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr.", pointColor: Constants.primaryLight, lineColor: Constants.primaryDark, touchUpInside: touchAction, icon: UIImage(named: "location")!, iconBg: Constants.primaryLight, fill: true),
            ISPoint(title: "07:30 AM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.", pointColor: Constants.white, lineColor: Constants.green, touchUpInside: touchAction, icon:UIImage(named: "location")!, iconBg: Constants.primaryLight, fill: true),
            ISPoint(title: "08:00 AM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt.", pointColor: Constants.primaryLight, lineColor: Constants.primaryDark, touchUpInside: touchAction, icon: UIImage(named: "location")!, iconBg: Constants.primaryLight, fill: true),
            ISPoint(title: "11:30 AM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.", touchUpInside: touchAction),
            ISPoint(title: "02:30 PM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.", touchUpInside: touchAction),
            ISPoint(title: "05:00 PM", description: "Lorem ipsum dolor sit amet.", touchUpInside: touchAction),
            ISPoint(title: "08:15 PM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.", touchUpInside: touchAction),
            ISPoint(title: "11:45 PM", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.", touchUpInside: touchAction)
        ]
        
        timeline.contentInset = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0)
        timeline.points = timelinePoints
        timeline.bubbleArrows = false
        timeline.timelineTitle = timelineTitle
    }
    
    private func foldMapView() {
        isAnimating = true
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
