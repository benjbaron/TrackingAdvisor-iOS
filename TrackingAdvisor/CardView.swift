//
//  CardView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 2/12/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit


class InfoCardView: UIView {
    var bigTextColor: UIColor = Constants.colors.primaryDark {
        didSet {
            bigTextLabel.color = bigTextColor
        }
    }
    var bigText: BigText = BigText() {
        didSet {
            bigTextLabel.bigText = bigText
        }
    }
    var descriptionTextColor: UIColor = Constants.colors.primaryLight {
        didSet {
            descriptionTextLabel.textColor = descriptionTextColor
        }
    }
    var descriptionText: String = "" {
        didSet {
            descriptionTextLabel.text = descriptionText
        }
    }
    
    lazy var bigTextLabel: BigLabel = {
        return BigLabel(bigText: bigText, color: bigTextColor)
    }()
    
    lazy var descriptionTextLabel: UILabel = {
        let label = UILabel()
        label.text = descriptionText
        label.textAlignment = .left
        label.numberOfLines = 0
        if AppDelegate.isIPhone5() {
            label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        } else {
            label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        }
        label.textColor = descriptionTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(bigText: BigText, descriptionText: String) {
        self.init(frame: CGRect.zero)
        
        self.bigText = bigText
        self.descriptionText = descriptionText
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 5.0
        self.layer.shadowRadius = 5.0
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.backgroundColor = Constants.colors.superLightGray
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
    }
    
    func setupViews() {
        addSubview(bigTextLabel)
        addSubview(descriptionTextLabel)
                
        // set content compression resistance
        // see: https://krakendev.io/blog/autolayout-magic-like-harry-potter-but-real
//        bigTextLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 200), for: .horizontal)
        descriptionTextLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // setup contraints
        addVisualConstraint("V:|-[v0]-12-|", views: ["v0": bigTextLabel])
        addVisualConstraint("V:|-[v0]-12-|", views: ["v0": descriptionTextLabel])
        addVisualConstraint("H:|-16-[v0(>=60)]-12-[v1]-16-|", views: ["v0": bigTextLabel, "v1": descriptionTextLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

class ReviewCardView: UIView {
    var yesAction: (() -> ())?
    var noAction: (() -> ())?
    var commentAction: (() -> ())?
    
    lazy var questionView: QuestionRow = {
        let row = QuestionRow(with: nil, yesAction: { [weak self] in
            if let action = self?.yesAction { action() }
            }, noAction: { [weak self] in
                if let action = self?.noAction { action() }
        })
        row.selectedColor = textColor
        row.unselectedColor = Constants.colors.superLightGray
        return row
    }()
    lazy var questionEditView: CommentRow = {
        let row = CommentRow(with: commentText, icon: "chevron-right", backgroundColor: UIColor.clear, color: textColor) { [weak self] in
            if let action = self?.commentAction { action() }
        }
        return row
    }()
    
    private var questionEditViewHeight: NSLayoutConstraint?
    private var questionEditViewSpacing: NSLayoutConstraint?
    private var isEditButtonHidden = true
    
    var textColor: UIColor = Constants.colors.primaryDark {
        didSet {
            textLabel.textColor = textColor
            questionView.selectedColor = textColor
            questionEditView.color = textColor
        }
    }
    
    var title: String = "Text goes here" {
        didSet {
            textLabel.text = title
        }
    }
    
    var commentText: String = "Comment text goes here" {
        didSet {
            questionEditView.text = commentText
        }
    }
    
    var selected: ReviewAnswer = .none {
        didSet {
            questionView.selected = selected
            switch selected {
            case .none, .yes:
                hideEdit()
            case .no:
                showEdit()
            }
            layoutIfNeeded()
        }
    }
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = textColor
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(title: String, color: UIColor) {
        self.init(frame: CGRect.zero)
        
        self.title = title
        self.textColor = color
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 5.0
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
    }
    
    func setupViews() {
        addSubview(textLabel)
        addSubview(questionView)
        addSubview(questionEditView)
        
        // set content compression resistance
        // see: https://krakendev.io/blog/autolayout-magic-like-harry-potter-but-real
//        bigTextLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
//        descriptionTextLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        
        // setup contraints
        addVisualConstraint("H:|-12-[v0]-[v1]-12-|", views: ["v0": textLabel, "v1": questionView])
        addVisualConstraint("H:|[v0]|", views: ["v0": questionEditView])
        addVisualConstraint("V:|-12-[v0(40)]", views: ["v0": questionView])
        addVisualConstraint("V:|-12-[v0]", views: ["v0": textLabel])
        addVisualConstraint("V:[v1]-12-|", views: ["v1": questionEditView])
        questionView.centerYAnchor.constraint(equalTo: textLabel.centerYAnchor).isActive = true
        questionEditViewHeight = NSLayoutConstraint(item: questionEditView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        questionEditViewHeight?.isActive = true
        questionEditViewSpacing = NSLayoutConstraint(item: textLabel, attribute: .bottom, relatedBy: .equal, toItem: questionEditView, attribute: .top, multiplier: 1.0, constant: 0.0)
        questionEditViewSpacing?.isActive = true
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func showEdit() {
        questionEditViewHeight?.constant = 40
        questionEditViewSpacing?.constant = -5.0
        isEditButtonHidden = false
    }
    
    func hideEdit() {
        questionEditViewHeight?.constant = 0.0
        questionEditViewSpacing?.constant = 0.0
        isEditButtonHidden = true
    }
    
    func height() -> CGFloat {
        if isEditButtonHidden {
            return 12.0 + 40.0 + 12.0
        } else {
            return 12.0 + 40.0 + 5.0 + questionEditView.height() + 12.0
        }
    }
}

class YesNoCardView: UIView {
    var yesAction: (() -> ())?
    var noAction: (() -> ())?
    
    var color: UIColor = Constants.colors.orange { didSet {
        yesButton.backgroundColor = color
        noButton.backgroundColor = color.withAlphaComponent(0.3)
        noButton.setTitleColor(color, for: .normal)
    }}
    var title: String? { didSet {
        yesButton.setTitle(title, for: .normal)
    }}
    
    private lazy var yesButton: UIButton = {
        let l = UIButton(type: .system)
        l.setTitle(title, for: .normal)
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.numberOfLines = 2
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.setTitleColor(.white, for: .normal)
        l.backgroundColor = color.withAlphaComponent(0.8)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedYesButton), for: .touchUpInside)
        return l
    }()
    
    private lazy var noButton: UIButton = {
        let l = UIButton(type: .system)
        l.setTitle("No", for: .normal)
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.numberOfLines = 2
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.setTitleColor(color, for: .normal)
        l.backgroundColor = color.withAlphaComponent(0.3)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedNoButton), for: .touchUpInside)
        return l
    }()
    
    @objc fileprivate func tappedYesButton() {
        yesAction?()
    }
    
    @objc fileprivate func tappedNoButton() {
        noAction?()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(title: String, color: UIColor) {
        self.init(frame: CGRect.zero)
        
        self.title = title
        self.color = color
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        self.layer.cornerRadius = 5.0
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        
        
        addSubview(yesButton)
        addSubview(noButton)
        
        addVisualConstraint("H:|[yes][no(75)]|", views: ["yes": yesButton, "no": noButton])
        addVisualConstraint("V:|[yes(50@750)]|", views: ["yes": yesButton])
        addVisualConstraint("V:|[no(50@750)]|", views: ["no": noButton])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> Int {
        return 50
    }
    
}

class StatsCardView: UIView {
    var statsOne: BigText! {
        didSet {
            statsOneLabel.bigText = statsOne
        }
    }
    var statsOneColor: UIColor = Constants.colors.primaryDark {
        didSet {
            statsOneLabel.color = statsOneColor
        }
    }
    lazy var statsOneLabel: BigLabel = {
        return BigLabel(bigText: statsOne, color: statsOneColor)
    }()
    
    var statsTwo: BigText! {
        didSet {
            statsTwoLabel.bigText = statsTwo
        }
    }
    var statsTwoColor: UIColor = Constants.colors.primaryDark {
        didSet {
            statsTwoLabel.color = statsTwoColor
        }
    }
    lazy var statsTwoLabel: BigLabel = {
        return BigLabel(bigText: statsTwo, color: statsTwoColor)
    }()
    
    var statsThree: BigText! {
        didSet {
            statsThreeLabel.bigText = statsThree
        }
    }
    var statsThreeColor: UIColor = Constants.colors.primaryDark {
        didSet {
            statsThreeLabel.color = statsThreeColor
        }
    }
    lazy var statsThreeLabel: BigLabel = {
        return BigLabel(bigText: statsThree, color: statsThreeColor)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(statsOne: BigText, statsTwo: BigText, statsThree: BigText) {
        self.init(frame: CGRect.zero)
        
        self.statsOne = statsOne
        self.statsTwo = statsTwo
        self.statsThree = statsThree
        
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 3.0
        self.layer.shadowRadius = 3.0
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.backgroundColor = Constants.colors.superLightGray
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
    }
    
    func setupViews() {
        addSubview(statsOneLabel)
        addSubview(statsTwoLabel)
        addSubview(statsThreeLabel)
        
        // setup contraints
        addVisualConstraint("V:|-[v0]", views: ["v0": statsOneLabel])
        addVisualConstraint("V:|-[v0]", views: ["v0": statsTwoLabel])
        addVisualConstraint("V:|-[v0]", views: ["v0": statsThreeLabel])
        addVisualConstraint("H:|-16-[v0]->=16-[v1]->=16-[v2]-16-|", views: ["v0": statsOneLabel, "v1": statsTwoLabel, "v2": statsThreeLabel], options: .alignAllTop)
        NSLayoutConstraint(item: statsTwoLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        
        var tallestBigLabel:BigLabel = statsOneLabel
        if statsTwoLabel.height > statsOneLabel.height && statsTwoLabel.height > statsThreeLabel.height {
            tallestBigLabel = statsTwoLabel
        } else if statsThreeLabel.height > statsOneLabel.height && statsThreeLabel.height > statsTwoLabel.height {
            tallestBigLabel = statsThreeLabel
        }
        addVisualConstraint("V:[v0]-12-|", views: ["v0": tallestBigLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

struct BigText {
    var bigText: String
    var topExponent: String?
    var smallBottomText: String?
    
    init() {
        self.bigText = ""
    }
    
    init(bigText: String) {
        self.bigText = bigText
    }
    
    init(bigText: String, smallBottomText: String) {
        self.bigText = bigText
        self.smallBottomText = smallBottomText
    }
    
    init(bigText: String, topExponent: String?, smallBottomText: String?) {
        self.bigText = bigText
        self.topExponent = topExponent
        self.smallBottomText = smallBottomText
    }
    
}

class BigLabel: UIView {
    var bigText: BigText! {
        didSet {
            bigTextLabel.text = bigText.bigText
            topExponentLabel.text = bigText.topExponent ?? ""
            smallBottomTextLabel.text = bigText.smallBottomText ?? ""
        }
    }
    var color: UIColor! {
        didSet {
            bigTextLabel.textColor = color
            topExponentLabel.textColor = color
            smallBottomTextLabel.textColor = color.withAlphaComponent(0.7)
        }
    }
    var bigTextLabel: UILabel!
    var topExponentLabel: UILabel!
    var smallBottomTextLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(bigText: BigText, color: UIColor) {
        self.init(frame: CGRect.zero)
        
        self.bigText = bigText
        self.color = color
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        bigTextLabel = UILabel()
        bigTextLabel.text = bigText.bigText
        bigTextLabel.textAlignment = .left
        if AppDelegate.isIPhone5() {
            bigTextLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        } else {
            bigTextLabel.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        }
        bigTextLabel.textColor = color
        bigTextLabel.sizeToFit()
        bigTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        topExponentLabel = UILabel()
        topExponentLabel!.text = bigText.topExponent ?? ""
        topExponentLabel!.textAlignment = .left
        topExponentLabel!.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        topExponentLabel!.textColor = color
        topExponentLabel.numberOfLines = 1
        topExponentLabel!.sizeToFit()
        topExponentLabel!.translatesAutoresizingMaskIntoConstraints = false
        
        smallBottomTextLabel = UILabel()
        smallBottomTextLabel!.text = bigText.smallBottomText ?? ""
        smallBottomTextLabel!.textAlignment = .left
        if AppDelegate.isIPhone5() {
            smallBottomTextLabel!.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        } else {
            smallBottomTextLabel!.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        }
        smallBottomTextLabel!.textColor = color.withAlphaComponent(0.7)
        smallBottomTextLabel.numberOfLines = 0
        smallBottomTextLabel!.sizeToFit()
        smallBottomTextLabel!.translatesAutoresizingMaskIntoConstraints = false
        
        let hstackView = UIStackView(arrangedSubviews: [bigTextLabel,topExponentLabel])
        hstackView.axis = .horizontal
        hstackView.distribution = .equalSpacing
        hstackView.alignment = .top
        hstackView.spacing = 0
        hstackView.translatesAutoresizingMaskIntoConstraints = false
        
        let vstackView = UIStackView(arrangedSubviews: [hstackView,smallBottomTextLabel])
        vstackView.axis = .vertical
        vstackView.distribution = .fill
        vstackView.alignment = .leading
        vstackView.spacing = -5.0
        vstackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vstackView)
        
        // set up the constraints
        addVisualConstraint("V:|[v0]|", views: ["v0": vstackView])
        addVisualConstraint("H:|[v0]|", views: ["v0": vstackView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    lazy var height:CGFloat = {
        return bigTextLabel.bounds.height + smallBottomTextLabel.bounds.height - 5
    }()
    
    lazy var width:CGFloat = {
        return max(bigTextLabel.bounds.width + topExponentLabel.bounds.width, smallBottomTextLabel.bounds.width)
    }()
}

