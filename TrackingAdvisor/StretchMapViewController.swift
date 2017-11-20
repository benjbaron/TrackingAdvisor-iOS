//
//  StretchMapViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/20/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

enum HeaderState {
    case folded
    case full
    case half
}

class StretchMapViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    
    var headerState = HeaderState.folded
    var isScrolling = false
    var previousHeaderState = HeaderState.folded
    var previousHeight:CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        if y < 0.0 && headerHeight.constant <= 200 {
            headerHeight.constant += abs(y)
        }
        
        if y > 0.0 && headerHeight.constant >= 0 {
            headerHeight.constant -= abs(y)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        isScrolling = false
        let heightDiff = headerHeight.constant - previousHeight
        print("scrollViewDidEndDragging - \(previousHeaderState), \(headerHeight.constant), \(heightDiff)")
        
        if heightDiff > 5.0 { // scrolling downwards
            if previousHeaderState == .folded && headerHeight.constant < 100 {
                print("\t 1")
                headerHeight.constant = 100
                headerState = .half
            } else if (previousHeaderState == .folded || previousHeaderState == .half) && headerHeight.constant > 100 {
                print("\t 2")
                headerHeight.constant = 200
                headerState = .full
            }
        } else if heightDiff < -5.0 { // scrolling upwards
            if (previousHeaderState == .full && headerHeight.constant > 100) {
                print("\t 3")
                headerHeight.constant = 100
                headerState = .half
            } else if (previousHeaderState == .full || previousHeaderState == .half) && headerHeight.constant < 100 {
                print("\t 4")
                headerHeight.constant = 0
                headerState = .folded
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
        previousHeaderState = headerState
        previousHeight = headerHeight.constant
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
