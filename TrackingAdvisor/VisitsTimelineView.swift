//
//  VisitsTimelineView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 5/21/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

protocol VisitsTimelineViewDelegate {
    func selectedDate(day: String)
}

class VisitsTimelineView : UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var collectionView: UICollectionView!
    var flowLayout: UICollectionViewFlowLayout!
    var delegate: VisitsTimelineViewDelegate?
    let cellId = "CellId"
    var daySelected: String?
    var days: [String] = [] { didSet {
        let dayStr = days.count > 1 ? "days" : "day"
        descriptionLabel.text = "You have participated in the study for \(days.count) \(dayStr)."
    }}
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        let dayStr = days.count > 1 ? "days" : "day"
        label.text = "You have participated in the study for \(days.count) \(dayStr)."
        label.numberOfLines = 2
        label.textAlignment = .left
        if AppDelegate.isIPhone5() {
            label.font = UIFont.italicSystemFont(ofSize: 12)
        } else {
            label.font = UIFont.italicSystemFont(ofSize: 14)
        }
        label.textColor = Constants.colors.primaryDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var actionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .black)
        label.textColor = Constants.colors.darkRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        days = DataStoreService.shared.getUniqueVisitDays(ctxt: nil)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        actionLabel.layoutIfNeeded()
        descriptionLabel.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        
        // reset all elements
        collectionView.reloadData()
        actionLabel.text = ""
        let dayStr = days.count > 1 ? "days" : "day"
        descriptionLabel.text = "You have participated in the study for \(days.count) \(dayStr)."
        daySelected = nil
    }
    
    private func setupViews() {
        print("visitsTimeline - setupViews")
        let frame = UIScreen.main.bounds
        backgroundColor = .clear
        
        collectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 50, height: 100)
        flowLayout.minimumInteritemSpacing = 0 // to hide the next cell
        flowLayout.minimumLineSpacing = 0 // to hide the next cell
        flowLayout.scrollDirection = .horizontal
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.isPagingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 16.0)
        
        // register cell type
        collectionView.register(VisitsTimelineCellView.self, forCellWithReuseIdentifier: cellId)
        
        addSubview(collectionView)
        addSubview(descriptionLabel)
        addSubview(actionLabel)
        
        // add constraints
        addVisualConstraint("V:|[description]-12-[collection(100)]-12-[action(30)]", views: ["collection": collectionView, "description": descriptionLabel, "action": actionLabel])
        addVisualConstraint("H:|[collection]|", views: ["collection": collectionView])
        addVisualConstraint("H:|-16-[description]-16-|", views: ["description": descriptionLabel])
        addVisualConstraint("H:|-16-[action]-16-|", views: ["action": actionLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
        
        actionLabel.addTapGestureRecognizer { [unowned self] in
            if let day = self.daySelected {
                AppDelegate.showTimeline(for: day)
            }
        }
        print("visitsTimeline - end setupViews")
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! VisitsTimelineCellView
        cell.day = days[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let day = days[indexPath.item]
        delegate?.selectedDate(day: day)
        if let date = DateHandler.dateFromDayString(from: day) {
            let visits = DataStoreService.shared.getVisits(for: day, ctxt: nil)
            let uniquePlaces = Set(visits.map({ $0.placeid! }))
            let numberOfVisitsToConfirm = visits.filter({ $0.visited == 0 }).count
            
            let visitStr = visits.count > 1 ? "visits" : "visit"
            let placeStr = uniquePlaces.count > 1 ? "places" : "place"
            let str = "On \(date.customDateLetter), you made \(visits.count) \(visitStr) at \(uniquePlaces.count) \(placeStr)."
            descriptionLabel.text = str
            
            if numberOfVisitsToConfirm > 0 {
                let visitToConfirmStr = numberOfVisitsToConfirm > 1 ? "visits" : "visit"
                let actionStr = "You have \(numberOfVisitsToConfirm) \(visitToConfirmStr) left to confirm ‣"
                actionLabel.text = actionStr
                actionLabel.textColor = Constants.colors.darkRed
            } else {
                actionLabel.text = "Go to the day ‣"
                actionLabel.textColor = Constants.colors.primaryDark
            }
            self.daySelected = day
        }
    }
}

fileprivate class VisitsTimelineCellView : UICollectionViewCell {
    var day: String? { didSet {
        guard let day = day else { return }
        if let date = DateHandler.dateFromDayString(from: day) {
            let components = Calendar.current.dateComponents([.day, .month], from: date)
            if let day = components.day {
                dayLabel.text = "\(day)"
            }
            monthLabel.text = "\(date.monthShortName.uppercased())"
        }
        
        // get the visits for the day
        let visits = DataStoreService.shared.getVisits(for: day, ctxt: nil)
        numberOfVisitsToConfirm = visits.filter({ $0.visited == 0 }).count
        numberOfVisitsConfirmed = visits.filter({ $0.visited == 1 }).count
        
        setNeedsLayout()
    }}
    
    override var isSelected: Bool { didSet {
        if isSelected {
            dayLabel.textColor = Constants.colors.darkRed
            monthLabel.textColor = Constants.colors.darkRed
            visitsConfirmedView.backgroundColor = Constants.colors.darkRed
            visitsNotConfirmedView.backgroundColor = Constants.colors.darkRed.withAlphaComponent(0.4)
        } else {
            dayLabel.textColor = Constants.colors.primaryDark
            monthLabel.textColor = Constants.colors.primaryDark
            visitsConfirmedView.backgroundColor = Constants.colors.primaryDark
            visitsNotConfirmedView.backgroundColor = Constants.colors.primaryLight
        }
    }}
    
    var numberOfVisitsToConfirm: Int = 0
    var numberOfVisitsConfirmed: Int = 0
    
    var dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .heavy)
        label.text = "28"
        label.textAlignment = .center
        label.textColor = Constants.colors.primaryDark
        return label
    }()
    
    var monthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .light)
        label.text = "05"
        label.textAlignment = .center
        label.textColor = Constants.colors.primaryDark
        return label
    }()
    
    var baseline: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var visitsConfirmedView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.colors.primaryDark
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var visitsNotConfirmedView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.colors.primaryLight
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let height = frame.height
        let width = frame.width
        
        let confirmedHeight: CGFloat = min(54.0, 3.0 * CGFloat(numberOfVisitsConfirmed))
        let notConfirmedHeight: CGFloat = min(54.0, 3.0 * CGFloat(numberOfVisitsToConfirm))
        
        monthLabel.frame = CGRect(x: 0, y: height-15, width: width, height: 15)
        dayLabel.frame = CGRect(x: 0, y: height-34, width: width, height: 20)
        baseline.frame = CGRect(x: 0, y: height-40, width: width, height: 1)
        visitsConfirmedView.frame = CGRect(x: 5, y: height-(40+confirmedHeight),
                                           width: width-10, height: confirmedHeight)
        visitsNotConfirmedView.frame = CGRect(x: 5, y: height-(40+notConfirmedHeight+confirmedHeight),
                                              width: width-10, height: notConfirmedHeight)
    }
    
    private func setupViews() {
        addSubview(visitsConfirmedView)
        addSubview(visitsNotConfirmedView)
        addSubview(baseline)
        addSubview(dayLabel)
        addSubview(monthLabel)
    }
}
