//
//  ReviewProgressBar.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 5/21/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

class ReviewProgressBar : UIView {
    var color: UIColor = Constants.colors.primaryDark { didSet {
        filledView.backgroundColor = color
        pointsLabel.textColor = color
        emptyView.backgroundColor = color.withAlphaComponent(0.2)
        nameLabel.textColor = color
    }}
    var filled: Int = 120 { didSet {
        pointsLabel.text = "\(filled)"
        setNeedsLayout()
    }}
    var empty: Int = 60 { didSet {
        setNeedsLayout()
    }}
    var total: Int = 180 { didSet {
        rightLabel.text = "\(total)"
        setNeedsLayout()
    }}
    var desc: String = "" { didSet {
        descriptionLabel.text = desc
    }}
    var name: String = "" { didSet {
        nameLabel.text = name
    }}
    
    var filledView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.colors.midPurple
        return view
    }()
    
    var emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.colors.midPurple.withAlphaComponent(0.2)
        return view
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Visit confirmations"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .heavy)
        label.textColor = Constants.colors.primaryDark
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "You have XX visits to confirm"
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textColor = Constants.colors.descriptionColor
        return label
    }()
    
    internal lazy var pointsLabel: UILabel = {
        let label = UILabel()
        label.text = "\(filled)"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        label.textColor = Constants.colors.midPurple
        return label
    }()
    
    internal lazy var leftLabel: UILabel = {
        let label = UILabel()
        label.text = String(0)
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.descriptionColor
        return label
    }()
    
    internal lazy var rightLabel: UILabel = {
        let label = UILabel()
        label.text = "\(total)"
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.descriptionColor
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let width = frame.width
        let total = CGFloat(filled + empty)
        let widthFilled =  total == 0 ? 0 : width * CGFloat(filled) / total
        let widthEmpty = total == 0 ? width * 0.5 : width * CGFloat(empty) / total
        
//        print("total: \(total), width: \(width), widthFilled: \(widthFilled), widthEmpty: \(widthEmpty)")
        if total == 0 {
            rightLabel.text = ""
        }
        
        nameLabel.frame = CGRect(x: 0, y: 0, width: width, height: 20)
        descriptionLabel.frame = CGRect(x: 0, y: 20, width: width, height: 20)
        
        filledView.frame = CGRect(x: 0, y: 42, width: widthFilled, height: 20)
        emptyView.frame = CGRect(x: widthFilled, y: 42, width: widthEmpty, height: 20)

        leftLabel.frame = CGRect(x: 0, y: 65, width: 100, height: 20)
        rightLabel.frame = CGRect(x: width-100, y: 65, width: 100, height: 20)
        
        if widthFilled < 50 {
            // put the label on the right side with its color
            pointsLabel.frame = CGRect(x: widthFilled+5, y: 42, width: 100, height: 20)
            pointsLabel.textAlignment = .left
        } else if widthFilled > width - 50 {
            // put the label on the left side with white color
            pointsLabel.frame = CGRect(x: widthFilled-105, y: 42, width: 100, height: 20)
            pointsLabel.textColor = .white
            pointsLabel.textAlignment = .right
        } else {
            // put the label below
            pointsLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
            pointsLabel.center = CGPoint(x: widthFilled, y: 75)
            pointsLabel.textAlignment = .center
        }
    }
    
    private func setupViews() {
        addSubview(leftLabel)
        addSubview(rightLabel)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        addSubview(filledView)
        addSubview(emptyView)
        addSubview(pointsLabel)
    }
}
