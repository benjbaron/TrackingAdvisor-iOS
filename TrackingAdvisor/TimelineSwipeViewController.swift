//
//  TimelineSwipeViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/6/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

class TimelineSwipeViewController: UIViewController, EMPageViewControllerDataSource, EMPageViewControllerDelegate, DataStoreUpdateProtocol {
    
    var pageViewController: EMPageViewController?
    var dataStoreService = DataStoreService.shared
    var days: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataStoreService.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setChildController()
    }
    
    private func setChildController() {
        let currentViewController = self.pageViewController?.selectedViewController
        if currentViewController == nil {
            days = DataStoreService.shared.getUniqueVisitDays()
            
            // Instantiate EMPageViewController and set the data source and delegate to 'self'
            let pageViewController = EMPageViewController()
            
            // Or, for a vertical orientation
            // let pageViewController = EMPageViewController(navigationOrientation: .Vertical)
            pageViewController.dataSource = self
            pageViewController.delegate = self
            
            // Set the initially selected view controller
            // IMPORTANT: If you are using a dataSource, make sure you set it BEFORE calling selectViewController:direction:animated:completion
            guard let currentViewController = self.viewController(at: 0) else { return }
            pageViewController.selectViewController(currentViewController, direction: .forward, animated: false, completion: nil)
            
            // Add EMPageViewController to the root view controller
            self.addChildViewController(pageViewController)
            self.view.insertSubview(pageViewController.view, at: 0) // Insert the page controller view below the navigation buttons
            self.pageViewController = pageViewController
            pageViewController.didMove(toParentViewController: self)
        } else {
            if let vc = currentViewController as? OneTimelineViewController {
                vc.reload()
            }
        }
    }

    // MARK: - EMPageViewController Data Source
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.index(of: viewController as! OneTimelineViewController) {
            let beforeViewController = self.viewController(at: viewControllerIndex + 1)
            return beforeViewController
        } else {
            return nil
        }
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.index(of: viewController as! OneTimelineViewController) {
            let afterViewController = self.viewController(at: viewControllerIndex - 1)
            return afterViewController
        } else {
            return nil
        }
    }
    
    func viewController(at index: Int) -> OneTimelineViewController? {
        if (self.days.count == 0) || (index < 0) || (index >= self.days.count) {
            return nil
        }
        
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "OneTimelineViewController") as! OneTimelineViewController
        viewController.timelineTitle = self.days[index]
        viewController.timelineDay = self.days[index]
        return viewController
    }
    
    func index(of viewController: OneTimelineViewController) -> Int? {
        if let day: String = viewController.timelineDay {
            return self.days.index(of: day)
        } else {
            return nil
        }
    }
    
    
    // MARK: - EMPageViewController Delegate
    func em_pageViewController(_ pageViewController: EMPageViewController, willStartScrollingFrom startViewController: UIViewController, destinationViewController: UIViewController) {
        
        let startGreetingViewController = startViewController as! OneTimelineViewController
        let destinationGreetingViewController = destinationViewController as! OneTimelineViewController
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, isScrollingFrom startViewController: UIViewController, destinationViewController: UIViewController, progress: CGFloat) {
        let startGreetingViewController = startViewController as! OneTimelineViewController
        let destinationGreetingViewController = destinationViewController as! OneTimelineViewController
        
        // Ease the labels' alphas in and out
        let absoluteProgress = fabs(progress)
        startGreetingViewController.timeline.alpha = pow(1 - absoluteProgress, 2)
        destinationGreetingViewController.timeline.alpha = pow(absoluteProgress, 2)
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
        let startViewController = startViewController as! OneTimelineViewController?
        let destinationViewController = destinationViewController as! OneTimelineViewController
    }
    
    // MARK: - DataStoreUpdateProtocol
    func dataStoreDidUpdate(for day: String?) {
        print("Called dataStoreDidUpdate for \(day)")
        
        // getting corresponding viewController
        guard let day = day else { return }
        let currentViewController = self.pageViewController?.selectedViewController
        if currentViewController != nil {
            if let vc = currentViewController as? OneTimelineViewController {
                if vc.timelineDay == day {
                    vc.reload()
                }
            }
        }
    }
}
