//
//  WeekCalendarView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/15/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

protocol WeekCalendarViewDelegate {
    func selectedDate(date: Date)
}

class WeekCalendarView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WeekCalendarCellDelegate {
    
    var collectionView: UICollectionView!
    var flowLayout: UICollectionViewFlowLayout!
    let cellId = "CellId"
    var days: [String] = []
    var weeks: [Date] = [] { didSet {
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }}
    var dateSelected: Date?
    var selectedDayIndexPath: IndexPath?
    var selectedWeekIndexPath: IndexPath?
    var delegate: WeekCalendarViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        setupViews()
        
        days = DataStoreService.shared.getUniqueVisitDays(ctxt: nil)
        computeWeeks()        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        collectionView.layoutIfNeeded()
    }
    
    func setToday() {
        layoutIfNeeded()
        
        let weekIndexPath = IndexPath(item: weeks.count-1, section: 0)
        collectionView.scrollToItem(at: weekIndexPath, at: .centeredHorizontally, animated: false)
        collectionView.layoutIfNeeded()
        selectedWeekIndexPath = weekIndexPath
        
        if let last = weeks.last {
            if let todayItem = Calendar.current.dateComponents([.day], from: last, to: Date()).day {
                selectedDayIndexPath = IndexPath(item: todayItem, section: 0)
                if let weekCell = collectionView.cellForItem(at: weekIndexPath) as? WeekCalendarCell {
                    weekCell.selectedDayIndexPath = selectedDayIndexPath
                    weekCell.weekCollectionView.selectItem(at: selectedDayIndexPath, animated: false, scrollPosition: .centeredHorizontally)
                }
            }
        }
    }
    
    private func setupViews() {
        // set up the collection view
        let frame = UIScreen.main.bounds
        
        collectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = Constants.colors.superLightGray
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // configure the flow layout
        flowLayout = WeekCalendarLayout()
        flowLayout.itemSize = CGSize(width: frame.width, height: 90)
        flowLayout.minimumInteritemSpacing = 0 // to hide the next cell
        flowLayout.minimumLineSpacing = 0 // to hide the next cell
        flowLayout.scrollDirection = .horizontal
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.isPagingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // register cell type
        collectionView.register(WeekCalendarCell.self, forCellWithReuseIdentifier: cellId)
        
        addSubview(collectionView)
        
        // add constraints
        addVisualConstraint("V:|[collection]|", views: ["collection": collectionView])
        addVisualConstraint("H:|[collection]|", views: ["collection": collectionView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weeks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! WeekCalendarCell
        cell.startOfWeek = weeks[indexPath.item]
        cell.delegate = self
        cell.weekIndexPath = indexPath

        let isSelected = indexPath == selectedWeekIndexPath
        cell.selectedDayIndexPath = isSelected ? self.selectedDayIndexPath : nil
        cell.isSelected = isSelected
        
        return cell
    }
    
    private func computeWeeks() {
        guard let last = days.last,
            let startDate = DateHandler.dateFromDayString(from: last) else { return }
        
        var week: Date!
        if let w = startDate.startOfWeek {
            week = w
        }
        var res: [Date] = []
        while week <= Date() {
            res.append(week)
            if let w = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: week) {
                week = w
            }
        }
        self.weeks = Array(res)
    }
    
    // MARK: - WeekCalendarCellDelegate method
    func selected(date: Date, dayIndexPath: IndexPath, weekIndexPath: IndexPath) {
        self.dateSelected = date
        self.selectedDayIndexPath = dayIndexPath
        self.selectedWeekIndexPath = weekIndexPath
        
        self.delegate?.selectedDate(date: date)
    }
}

protocol WeekCalendarCellDelegate {
    func selected(date: Date, dayIndexPath: IndexPath, weekIndexPath: IndexPath)
}
fileprivate class WeekCalendarCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var startOfWeek: Date? { didSet {
        weekDates.removeAll()
        if let start = startOfWeek {
            for i in 0..<7 {
                if let date = Calendar.current.date(byAdding: .day, value: i, to: start) {
                    weekDates.append(date)
                }
            }
        }
    }}
    var weekDates: [Date] = [] { didSet {
        weekCollectionView.reloadData()
    }}
    
    var weekCollectionView: UICollectionView!
    let cellId = "weekDayCellId"
    var delegate: WeekCalendarCellDelegate?
    var weekIndexPath: IndexPath?
    var selectedDayIndexPath: IndexPath? { didSet {
        weekCollectionView.selectItem(at: selectedDayIndexPath, animated: false, scrollPosition: .centeredHorizontally)
    }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        print("WeekDayCalendarCell - setupViews")
        // configure the flow layout
        let flowLayout = UICollectionViewFlowLayout()
        let cellWidth = ((UIScreen.main.bounds.width) - 20) / 7
        flowLayout.itemSize = CGSize(width: cellWidth, height: 80)
        
        flowLayout.minimumInteritemSpacing = 0 // to show the next cell
        flowLayout.minimumLineSpacing = 0 // to show the next cell

        // set up the collection view
        weekCollectionView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        weekCollectionView.dataSource = self
        weekCollectionView.delegate = self
        weekCollectionView.backgroundColor = .clear
        weekCollectionView.showsHorizontalScrollIndicator = false
        weekCollectionView.translatesAutoresizingMaskIntoConstraints = false
        weekCollectionView.isPagingEnabled = false
        weekCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        // register cell type
        weekCollectionView.register(WeekDayCalendarCell.self, forCellWithReuseIdentifier: cellId)
        
        addSubview(weekCollectionView)
        
        // add constraints
        addVisualConstraint("V:|[collection]|", views: ["collection": weekCollectionView])
        addVisualConstraint("H:|[collection]|", views: ["collection": weekCollectionView])
        
        translatesAutoresizingMaskIntoConstraints = false

    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7 // number of days per week
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = weekCollectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! WeekDayCalendarCell
        cell.date = weekDates[indexPath.item]
        cell.isSelected = isSelected && (indexPath == self.selectedDayIndexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedIdx = selectedDayIndexPath { // manually deselect the date
            let cell = collectionView.cellForItem(at: selectedIdx) as! WeekDayCalendarCell
            cell.isSelected = false
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as! WeekDayCalendarCell
        cell.isSelected = true
        selectedDayIndexPath = indexPath
        if let weekIndexPath = weekIndexPath {
            self.delegate?.selected(date: weekDates[indexPath.item], dayIndexPath: indexPath, weekIndexPath: weekIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let date = weekDates[indexPath.item]
        return date <= Date()
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let date = weekDates[indexPath.item]
        return date <= Date()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if indexPath == selectedDayIndexPath {
            let cell = collectionView.cellForItem(at: indexPath) as! WeekDayCalendarCell
            cell.isSelected = true
        }
    }
}

fileprivate class WeekDayCalendarCell: UICollectionViewCell {
    override var isSelected: Bool {
        didSet {
            if date == nil || date! > Date() {
                circleView.alpha = 0
                return
            }
            
            let isToday = Date().startOfDay == date
            circleView.alpha = isSelected ? 1.0 : (isToday ? 0.3 : 0.0)
            weekDayNumberLabel.textColor = isSelected ? .white : (isToday ? .white : .black)
        }
    }
    
    var date: Date? { didSet {
        guard let date = date else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        weekDayLetterLabel.text = String(formatter.string(from: date).prefix(1))
        
        formatter.dateFormat = "d"
        weekDayNumberLabel.text = formatter.string(from: date)
        
        if date > Date() {
            weekDayNumberLabel.textColor = Constants.colors.lightGray
            weekDayLetterLabel.textColor = Constants.colors.lightGray
        } else {
            weekDayNumberLabel.textColor = .black
            weekDayLetterLabel.textColor = .black
        }
    }}
    
    private lazy var weekDayLetterLabel: UILabel = {
        let label = UILabel()
        label.text = "M"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.textColor = Constants.colors.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var weekDayNumberLabel: UILabel = {
        let label = UILabel()
        label.text = "28"
        label.font = UIFont.systemFont(ofSize: 20.0)
        label.textAlignment = .center
        label.textColor = Constants.colors.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var circleView: UIView = {
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 35, height: 35))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 0
        
        let view = UIView()
        view.layer.addSublayer(shapeLayer)
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
    
    private func setupViews() {
        addSubview(weekDayLetterLabel)
        addSubview(weekDayNumberLabel)
        insertSubview(circleView, belowSubview: weekDayNumberLabel)
        
        addVisualConstraint("H:|[letter]|", views: ["letter": weekDayLetterLabel])
        addVisualConstraint("H:|[number]|", views: ["number": weekDayNumberLabel])
        addVisualConstraint("V:|-[letter]-[number]-|", views: ["letter": weekDayLetterLabel, "number": weekDayNumberLabel])
        
        circleView.widthAnchor.constraint(equalToConstant: 35.0).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 35.0).isActive = true
        circleView.centerXAnchor.constraint(equalTo: weekDayNumberLabel.centerXAnchor).isActive = true
        circleView.centerYAnchor.constraint(equalTo: weekDayNumberLabel.centerYAnchor).isActive = true
        
        circleView.alpha = 0
    }
}

class WeekCalendarLayout: UICollectionViewFlowLayout {
    var cellWidth: CGFloat = 50
    var cellHeight: CGFloat = 50
    
    override init() {
        super.init()
        
        scrollDirection = .horizontal
        itemSize = CGSize(width: cellWidth, height: cellHeight)
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func prepare() {
        super.prepare()
        
        // rate at which we scroll the collection view
        collectionView?.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // forces to recalculate the attribtues every time the collection view's bounds changes
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }
        
        var newOffset = CGPoint()
        let width = itemSize.width + minimumLineSpacing
        
        var offset = proposedContentOffset.x + collectionView.contentInset.left
        
        if velocity.x > 0 {
            // user is scrolling to the right
            offset = width * ceil(offset / width)
        } else if velocity.x == 0 {
            // user did not scroll strongly enough
            offset = width * round(offset / width)
        } else if velocity.x < 0 {
            // user is scrolling to the left
            offset = width * floor(offset / width)
        }
        
        newOffset.x = offset - collectionView.contentInset.left
        newOffset.y = proposedContentOffset.y // does not change
        
        return newOffset
    }
}
