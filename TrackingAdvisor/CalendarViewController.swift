//
//  CalendarViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/1/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {
    
    var isShowingMapCalendarContainer = false
    
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var timelineViewContainer: UIView!
    @IBOutlet weak var mapViewContainer: UIView!
    @IBAction func toggleContainerViews(_ sender: UIBarButtonItem) {
        print("toggle \(self.isShowingMapCalendarContainer)")
        if isShowingMapCalendarContainer {
            UIView.animate(withDuration: 0.0, animations: {
                self.mapViewContainer.alpha = 0
                self.timelineViewContainer.alpha = 1
            }, completion: { finished in
                self.isShowingMapCalendarContainer = false
            })
        } else {
            UIView.animate(withDuration: 0.0, animations: {
                self.mapViewContainer.alpha = 1
                self.timelineViewContainer.alpha = 0
            }, completion: { finished in
                self.isShowingMapCalendarContainer = true
            })
        }
    }
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.calendar.select(Date())
        
        self.view.addGestureRecognizer(self.scopeGesture)
        self.calendar.scope = .month
        
        // Do any additional setup after loading the view.
    }
    
    // MARK:- UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
//        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
//        if shouldBegin {
//            let velocity = self.scopeGesture.velocity(in: self.view)
//            switch self.calendar.scope {
//            case .month:
//                return velocity.y < 0
//            case .week:
//                return velocity.y > 0
//            }
//        }
//        return shouldBegin
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
//        mapViewContainer.layoutIfNeeded()
//        print("bounds changed - \(bounds.height), \(mapViewContainer.bounds.height)")
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("did select date \(self.dateFormatter.string(from: date))")
        let selectedDates = calendar.selectedDates.map({self.dateFormatter.string(from: $0)})
        print("selected dates is \(selectedDates)")
        if monthPosition == .next || monthPosition == .previous {
            calendar.setCurrentPage(date, animated: true)
        }
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        print("\(self.dateFormatter.string(from: calendar.currentPage))")
    }
    
    // MARK:- UITableViewDataSource
    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 10
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
//        return cell
//    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        print("prepare for segue")
//        segue.destination.view.translatesAutoresizingMaskIntoConstraints = false
//
//        var ctrl:MapCalendarContainerViewController?
//        ctrl = segue.destination as? MapCalendarContainerViewController
//        if ctrl != nil {
//            ctrl!.height.constant = mapViewContainer.frame.height
//            print("passed -- \(ctrl!)")
//            print("size -- \(ctrl!.view.frame) -- \(ctrl!.height.constant)")
//        }
    }
}

