//
//  UserStatsOvelayView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 5/20/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

class UserStatsOverlayView : UIView {
    var color: UIColor = Constants.colors.midPurple
    
    lazy var headerBgView: UIView = {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var badgeView: UserStatsBagdeView = {
        let view = UserStatsBagdeView()
        view.level = UserStats.shared.level
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Level \(UserStats.shared.level)"
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var barChart: UserStatsBarChartView = {
        return UserStatsBarChartView()
    }()
    
    lazy var scoreTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Your score"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.textColor = Constants.colors.midPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "\(UserStats.shared.score) points"
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .heavy)
        label.textAlignment = .right
        label.numberOfLines = 1
        label.textColor = Constants.colors.midPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var daysScore: UserStatsDetailRow = {
        let row = UserStatsDetailRow()
        row.color = Constants.colors.darkRed.withAlphaComponent(0.85)
        row.score = UserStats.shared.numberOfDaysStudy * 5
        row.item = "Participation duration"
        let dayStr = UserStats.shared.numberOfDaysStudy != 1 ? "days" : "day"
        row.desc = "Each day you participate in the study is worth 5 points. You have been participating in the study for \(UserStats.shared.numberOfDaysStudy) \(dayStr)."
        return row
    }()
    
    lazy var visitsScore: UserStatsDetailRow = {
        let row = UserStatsDetailRow()
        row.color = Constants.colors.primaryDark.withAlphaComponent(0.85)
        row.score = UserStats.shared.numberOfVisitsConfirmed * 2
        row.item = "Visit confirmations"
        let visitStr = UserStats.shared.numberOfVisitsConfirmed != 1 ? "visits" : "visit"
        row.desc = "Each visit you confirm is worth 2 points. You have confirmed \(UserStats.shared.numberOfVisitsConfirmed) \(visitStr)."
        return row
    }()
    
    lazy var placesScore: UserStatsDetailRow = {
        let row = UserStatsDetailRow()
        row.color = Constants.colors.midPurple.withAlphaComponent(0.85)
        row.score = UserStats.shared.numberOfPlacePersonalInformationReviewed * 1
        row.item = "Place reviews"
        let placeStr = UserStats.shared.numberOfPlacePersonalInformationReviewed != 1 ? "places" : "place"
        row.desc = "Each place you review is worth 1 point. You have reviewed \(UserStats.shared.numberOfPlacePersonalInformationReviewed) \(placeStr)."
        return row
    }()
    
    lazy var apiScore: UserStatsDetailRow = {
        let row = UserStatsDetailRow()
        row.color = Constants.colors.orange.withAlphaComponent(0.85)
        row.score = UserStats.shared.numberOfAggregatedPersonalInformationReviewed * 3
        row.item = "Personal information\nreviews"
        row.desc = "Each personal information you review is worth 3 points. You have reviewed \(UserStats.shared.numberOfAggregatedPersonalInformationReviewed) personal information."
        return row
    }()
    
    private lazy var dismissButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.layer.masksToBounds = true
        btn.setTitle("Dismiss", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        btn.setTitleColor(Constants.colors.superLightGray, for: .normal)
        btn.setTitleColor(color, for: .highlighted)
        btn.setBackgroundColor(color, for: .normal)
        btn.setBackgroundColor(Constants.colors.lightGray, for: .highlighted)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tappedDismissButton), for: .touchUpInside)
        return btn
    }()
    
    @objc fileprivate func tappedDismissButton() {
        OverlayView.shared.hideOverlayView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        // setup the view itself
        let overlayFrame = OverlayView.frame()
        
        if AppDelegate.isIPhoneX() {
            self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 75, height: overlayFrame.height - 300)
            self.center = CGPoint(x: overlayFrame.width / 2.0, y: overlayFrame.height / 2.0 - 50.0)
        } else if AppDelegate.isIPhone5() {
            self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 50, height: overlayFrame.height - 125)
            self.center = CGPoint(x: overlayFrame.width / 2.0, y: overlayFrame.height / 2.0 - 25.0)
        } else if AppDelegate.isIPhone6Plus() {
            self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 75, height: overlayFrame.height - 250)
            self.center = CGPoint(x: overlayFrame.width / 2.0, y: overlayFrame.height / 2.0 - 25.0)
        } else {
            self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 75, height: overlayFrame.height - 150)
            self.center = CGPoint(x: overlayFrame.width / 2.0, y: overlayFrame.height / 2.0 - 25.0)
        }

        // create a content view
        let contentView = UIView()
        contentView.frame = CGRect(x: 0, y: 50, width: self.frame.width, height: self.frame.height)
        contentView.backgroundColor = .white
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 10
        addSubview(contentView)

        headerBgView.addSubview(titleLabel)
        
        // add constraints
        headerBgView.addVisualConstraint("H:|-14-[title]-14-|", views: ["title": titleLabel])
        if AppDelegate.isIPhone5() {
            headerBgView.addVisualConstraint("V:|-(14@750)-[title]-(10@750)-|", views: ["title": titleLabel])
        } else {
            headerBgView.addVisualConstraint("V:|-(55@750)-[title]-(18@750)-|", views: ["title": titleLabel])
        }
        contentView.addSubview(headerBgView)
        contentView.addSubview(dismissButton)
        contentView.addSubview(scoreLabel)
        contentView.addSubview(scoreTextLabel)
        contentView.addSubview(barChart)
        contentView.addSubview(daysScore)
        contentView.addSubview(visitsScore)
        contentView.addSubview(placesScore)
        contentView.addSubview(apiScore)
        self.addSubview(badgeView)
        
        contentView.addVisualConstraint("H:|[v0]|", views: ["v0": headerBgView])
        contentView.addVisualConstraint("H:|-14-[v0]", views: ["v0": scoreTextLabel])
        contentView.addVisualConstraint("H:[v0]-14-|", views: ["v0": scoreLabel])
        contentView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": barChart])
        contentView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": daysScore])
        contentView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": visitsScore])
        contentView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": placesScore])
        contentView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": apiScore])
        contentView.addVisualConstraint("H:|[v0]|", views: ["v0": dismissButton])
        badgeView.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
        badgeView.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
        badgeView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        self.addVisualConstraint("V:|[v0]", views: ["v0": badgeView])
        
        scoreLabel.bottomAnchor.constraint(equalTo: barChart.topAnchor, constant: -3.0).isActive = true
        
        if AppDelegate.isIPhone5() {
            contentView.addVisualConstraint("V:|[header]-14-[scoreText]-3-[chart(30)]-20-[day]-14-[visit]-14-[place]-14-[api]-(>=14)-[dismiss(45)]|", views: ["header": headerBgView, "scoreText": scoreTextLabel, "chart": barChart, "day": daysScore, "visit": visitsScore, "place": placesScore, "api": apiScore, "dismiss": dismissButton])
        } else {
            contentView.addVisualConstraint("V:|[header]-14-[scoreText]-3-[chart(30)]-20-[day]-14-[visit]-14-[place]-14-[api]-(>=14)-[dismiss(50)]|", views: ["header": headerBgView, "scoreText": scoreTextLabel, "chart": barChart, "day": daysScore, "visit": visitsScore, "place": placesScore, "api": apiScore, "dismiss": dismissButton])
        }
    }
}

class UserStatsBagdeView : UIView {
    var level: Int = 1 { didSet {
        setNeedsDisplay()
    }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        backgroundColor = .clear
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func draw(_ rect: CGRect) {
        let diameter = min(bounds.width, bounds.height) - 2
        let scale = diameter / 50.0
        let minX = bounds.minX + ((bounds.width - diameter) * 0.5).rounded(.down)
        let minY = bounds.minY + ((bounds.height - diameter) * 0.5).rounded(.down)
        
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Shadow Declarations
        let shadow = NSShadow()
        shadow.shadowColor = Constants.colors.lightPurple.withAlphaComponent(0.50)
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        shadow.shadowBlurRadius = 4
        let shadow2 = NSShadow()
        shadow2.shadowColor = UIColor.black.withAlphaComponent(0.3)
        shadow2.shadowOffset = CGSize(width: 3, height: 3)
        shadow2.shadowBlurRadius = 5
        
        //// Polygon Drawing
        let polygonPath = UIBezierPath()
        polygonPath.move(to: CGPoint(x: 24.88, y: 0.5))
        polygonPath.addLine(to: CGPoint(x: 47.25, y: 12.75))
        polygonPath.addLine(to: CGPoint(x: 47.25, y: 37.25))
        polygonPath.addLine(to: CGPoint(x: 24.88, y: 49.5))
        polygonPath.addLine(to: CGPoint(x: 2.5, y: 37.25))
        polygonPath.addLine(to: CGPoint(x: 2.5, y: 12.75))
        polygonPath.addLine(to: CGPoint(x: 24.88, y: 0.5))
        polygonPath.close()
        
        polygonPath.apply(CGAffineTransform(translationX: minX / scale, y: minY / scale))
        polygonPath.apply(CGAffineTransform(scaleX: scale, y: scale))
        
        context.saveGState()
        context.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: (shadow.shadowColor as! UIColor).cgColor)
        Constants.colors.midPurple.setFill()
        polygonPath.fill()
        context.restoreGState()
        
        Constants.colors.midPurple.setStroke()
        polygonPath.lineWidth = 1
        polygonPath.lineCapStyle = .round
        polygonPath.lineJoinStyle = .round
        polygonPath.stroke()
        
        //// Text Drawing
        let textRect = CGRect(x: 2.5, y: 2.5, width: bounds.width-2.5, height: bounds.height-2.5)
        let textTextContent = "\(level)"
        context.saveGState()
        context.setShadow(offset: shadow2.shadowOffset, blur: shadow2.shadowBlurRadius, color: (shadow2.shadowColor as! UIColor).cgColor)
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        let textFontAttributes = [
            .font: UIFont.systemFont(ofSize: 35, weight: .black),
            .foregroundColor: Constants.colors.lightPurple,
            .paragraphStyle: textStyle,
            ] as [NSAttributedStringKey: Any]
        
        let textTextHeight: CGFloat = textTextContent.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: textRect)
        textTextContent.draw(in: CGRect(x: textRect.minX, y: textRect.minY + (textRect.height - textTextHeight) / 2, width: textRect.width, height: textTextHeight), withAttributes: textFontAttributes)
        context.restoreGState()
        context.restoreGState()
    }
}

class UserStatsBarChartView : UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        let width = frame.width
        let height = frame.height
        let score = max(1.0, CGFloat(UserStats.shared.score))
        let daysScore = CGFloat(UserStats.shared.numberOfDaysStudy) * 5.0
        let placeScore = CGFloat(UserStats.shared.numberOfPlacePersonalInformationReviewed) * 1.0
        let apiScore = CGFloat(UserStats.shared.numberOfAggregatedPersonalInformationReviewed) * 3.0
        let visitsScore = CGFloat(UserStats.shared.numberOfVisitsConfirmed) * 2.0
        
        var x:CGFloat = 0.0
        let dayView = UIView()
        dayView.frame = CGRect(x: x, y: 0, width: daysScore/score * width, height: height)
        dayView.backgroundColor = Constants.colors.darkRed.withAlphaComponent(0.85)
        x += daysScore/score * width
        
        let visitsView = UIView()
        visitsView.frame = CGRect(x: x, y: 0, width: visitsScore/score * width, height: height)
        visitsView.backgroundColor = Constants.colors.primaryDark.withAlphaComponent(0.85)
        x += visitsScore/score * width
        
        let placeView = UIView()
        placeView.frame = CGRect(x: x, y: 0, width: placeScore/score * width, height: height)
        placeView.backgroundColor = Constants.colors.midPurple.withAlphaComponent(0.85)
        x += placeScore/score * width
        
        let apiView = UIView()
        apiView.frame = CGRect(x: x, y: 0, width: apiScore/score * width, height: height)
        apiView.backgroundColor = Constants.colors.orange.withAlphaComponent(0.85)
        
        addSubview(dayView)
        addSubview(visitsView)
        addSubview(placeView)
        addSubview(apiView)
    }
}

class UserStatsDetailRow : UIView {
    var color: UIColor = Constants.colors.midPurple { didSet {
        itemLabel.textColor = color
        scoreLabel.textColor = color
    }}
    
    var item: String = "" { didSet {
        itemLabel.text = item
    }}
    
    var score: Int = 1 { didSet {
        scoreLabel.text = "\(score) points"
    }}
    
    var desc: String = "" { didSet {
        descriptionLabel.text = desc
    }}
    
    lazy private var itemLabel: UILabel = {
        let label = UILabel()
        label.text = "Item"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .left
        label.numberOfLines = 2
        label.textColor = Constants.colors.midPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "XX points"
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .heavy)
        label.textAlignment = .right
        label.numberOfLines = 1
        label.textColor = Constants.colors.midPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Description"
        label.font = UIFont.italicSystemFont(ofSize: 10.0)
        label.textAlignment = .left
        label.numberOfLines = 3
        label.textColor = Constants.colors.descriptionColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        addSubview(itemLabel)
        addSubview(scoreLabel)
        addSubview(descriptionLabel)
        
        addVisualConstraint("H:|[v0]", views: ["v0": itemLabel])
        addVisualConstraint("H:[v0]|", views: ["v0": scoreLabel])
        addVisualConstraint("H:|[v0]|", views: ["v0": descriptionLabel])
        addVisualConstraint("V:|[v0]-3-[v1]|", views: ["v0": itemLabel, "v1": descriptionLabel])
        scoreLabel.topAnchor.constraint(equalTo: itemLabel.topAnchor).isActive = true
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
