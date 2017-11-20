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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        if isAnimating { return }
        
        
        if !isFolded && y > 10.0 {
            isAnimating = true
            
            UIView.animate(withDuration: 0.2, animations: {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x,
                                                    y: -scrollView.contentInset.top),
                                            animated: false)
            }, completion: { completed in
                if completed {
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
            })
            
        } else if isFolded && y < -50.0 {
            isAnimating = true
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.mapViewHeight.constant = 300
                self?.view.layoutIfNeeded()
            }, completion: { completed in
                if completed {
                    self.isAnimating = false
                    self.isFolded = false
                }
            })
        }
    }
    
    /*
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let y = scrollView.contentOffset.y
        isScrolling = false
        let heightDiff = mapViewHeight.constant - previousMapViewHeight
        print("scrollViewDidEndDragging - \(y), \(previousMapViewState), \(mapViewHeight.constant), \(heightDiff)")
        
        if y < -60.0 { // scrolling downwards
//            if previousMapViewState == .folded && mapViewHeight.constant < 100 {
                print("\t 1")
                mapViewHeight.constant = 350
                mapViewState = .half
//            } else if (previousMapViewState == .folded || previousMapViewState == .half) && mapViewHeight.constant > 100 {
//                print("\t 2")
//                mapViewHeight.constant = 200
//                mapViewState = .full
//            }
        }
//        } else if y > 0.0 { // scrolling upwards
////            if (previousMapViewState == .full && mapViewHeight.constant > 100) {
////                print("\t 3")
//                mapViewHeight.constant = 0
//                mapViewState = .half
////            } else if (previousMapViewState == .full || previousMapViewState == .half) && mapViewHeight.constant < 100 {
////                print("\t 4")
////                mapViewH/eight.constant = 0
////                mapViewState = .folded
////            }
//        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
        previousMapViewState = mapViewState
        previousMapViewHeight = mapViewHeight.constant
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
