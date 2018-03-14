//
//  TimelineSwipeViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/6/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

class TimelineSwipeViewController: UIViewController, EMPageViewControllerDataSource, EMPageViewControllerDelegate, DataStoreUpdateProtocol {
    
    var fullScreenView: FullScreenView?
    var pageViewController: EMPageViewController?
    var dataStoreService = DataStoreService.shared
    var days: [String] = [] { didSet {
        if days.count > 0 {
            fullScreenView?.removeFromSuperview()
        }
    }}
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dataStoreService.delegate = self
        
        setChildController()
    }
    
    private func setChildController() {
        let currentViewController = self.pageViewController?.selectedViewController
        if currentViewController == nil {
            days = DataStoreService.shared.getUniqueVisitDays()
            
            if days.count == 0 && fullScreenView == nil {
                // the user just installed the app, show an animation
                fullScreenView = FullScreenView(frame: view.frame)
                fullScreenView!.icon = "walking"
                fullScreenView!.iconColor = Constants.colors.primaryLight
                fullScreenView!.headerTitle = "Your timeline, here"
                fullScreenView!.subheaderTitle = "After moving to a few places, you will find your timeline with the places that you visited here."
                view.addSubview(fullScreenView!)
            } else {
                setupPageViewcontroller()
            }
        } else {
            if let vc = currentViewController as? OneTimelineViewController {
                vc.reload()
            }
        }
    }
    
    private func setupPageViewcontroller() {
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
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let day = self.days[index]
        let date = formatter.date(from: day)!
        let title = date.dayAgo(since: Date())
        let subtitle = DateHandler.dateToDayLetterString(from: date)
    
        viewController.timelineTitle = title
        viewController.timelineSubtitle = subtitle
        viewController.timelineDay = day
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
    
    func em_pageViewController(_ pageViewController: EMPageViewController, isScrollingFrom startViewController: UIViewController, destinationViewController: UIViewController, progress: CGFloat) {
        let startGreetingViewController = startViewController as! OneTimelineViewController
        let destinationGreetingViewController = destinationViewController as! OneTimelineViewController
        
        // Ease the labels' alphas in and out
        let absoluteProgress = fabs(progress)
        startGreetingViewController.timeline.alpha = pow(1 - absoluteProgress, 2)
        destinationGreetingViewController.timeline.alpha = pow(absoluteProgress, 2)
    }
    
    
    // MARK: - DataStoreUpdateProtocol
    func dataStoreDidUpdate(for day: String?) {
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
