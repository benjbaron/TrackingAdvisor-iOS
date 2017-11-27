//
//  TimelineSwipeViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/6/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

class TimelineSwipeViewController: UIViewController, EMPageViewControllerDataSource, EMPageViewControllerDelegate {
    
    var pageViewController: EMPageViewController?
    
    var titles: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the titles of the pages
        titles = DataStoreService.shared.getUniqueVisitDays()
        print("viewDidLoad: \(titles)")
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let currentViewController = self.pageViewController?.selectedViewController as? OneTimelineViewController else { return }
        
        currentViewController.reload()
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
        if (self.titles.count == 0) || (index < 0) || (index >= self.titles.count) {
            return nil
        }
        
        print("viewController at index \(index)")
        let viewController = self.storyboard!.instantiateViewController(withIdentifier: "OneTimelineViewController") as! OneTimelineViewController
        viewController.timelineTitle = self.titles[index]
        print("viewController(at index): \(viewController.timelineTitle)")
        return viewController
    }
    
    func index(of viewController: OneTimelineViewController) -> Int? {
        if let title: String = viewController.timelineTitle {
            return self.titles.index(of: title)
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
}

extension Formatter {
    static let customDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    static let time:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    static let weekdayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "cccc"
        return formatter
    }()
    static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter
    }()
}

extension Date {
    var customDate: String {
        return Formatter.customDate.string(from: self)
    }
    var customTime: String {
        return Formatter.time.string(from: self)
    }
    var weekdayName: String {
        return Formatter.weekdayName.string(from: self)
    }
    var monthName: String {
        return Formatter.month.string(from: self)
    }
}

extension String {
    var customDate: Date? {
        return Formatter.customDate.date(from: self)
    }
}
