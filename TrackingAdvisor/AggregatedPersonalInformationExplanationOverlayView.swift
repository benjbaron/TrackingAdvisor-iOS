//
//  AggregatedPersonalInformationExplanationOverlayView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/4/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

protocol AggregatedPersonalInformationExplanationOverlayDelegate {
    func aggregatedPersonalInformationReview(cat: String, personalInformation: AggregatedPersonalInformation, type: ReviewType, rating: Int32, picIndexPath: IndexPath, personalInformationIndexPath: IndexPath)
    func explanationFeedback(cat: String, personalInformation: AggregatedPersonalInformation)
    func placePersonalInformationReview(personalInformation: PersonalInformation?, rating: Int32)
}

class AggregatedPersonalInformationExplanationOverlayView : UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PersonalInformationCellDelegate {
    
    var showAllQuestions: Bool = false {
        didSet {
            if showAllQuestions {
                personalInformationRatingViewHeight?.isActive = false
                privacyRatingViewHeight?.isActive = false
                personalInformationRatingView.isHidden = false
                privacyRatingView.isHidden = false
            } else {
                personalInformationRatingViewHeight?.isActive = true
                privacyRatingViewHeight?.isActive = true
                personalInformationRatingView.isHidden = true
                privacyRatingView.isHidden = true
            }
        }
    }
    var picIndexPath: IndexPath?
    var indexPath: IndexPath?
    var delegate: AggregatedPersonalInformationExplanationOverlayDelegate?
    var color: UIColor = Constants.colors.orange {
        didSet {
            headerBgView.backgroundColor = color
            dismissButton.setBackgroundColor(color, for: .normal)
            dismissButton.setTitleColor(color, for: .highlighted)
            explanationRatingView.color = color
            privacyFeedbackRow.color = color
            personalInformationRatingView.color = color
            privacyRatingView.color = color
        }
    }
    
    var picid: String?
    var aggregatedPersonalInformation: AggregatedPersonalInformation? {
        didSet {
            titleLabel.text = aggregatedPersonalInformation?.name
            subtitleLabel.text = aggregatedPersonalInformation?.getExplanation()
            if let picid = aggregatedPersonalInformation?.category,
                let pic = PersonalInformationCategory.getPersonalInformationCategory(with: picid) {
                iconView.icon = pic.icon
            }
            if let api = aggregatedPersonalInformation {
                places = api.getExplanationPlaces().sorted(by: {
                    if $0.numberOfVisits == $1.numberOfVisits {
                        return $0.place.name ?? "" > $1.place.name ?? ""
                    } else {
                        return $0.numberOfVisits > $1.numberOfVisits
                    }
                })
            }
            if let explanationRating = aggregatedPersonalInformation?.reviewExplanation {
                explanationRatingView.rating = max(0.0, Float(explanationRating))
            }
            
            if let piRating = aggregatedPersonalInformation?.reviewPersonalInformation {
                personalInformationRatingView.rating = max(0.0, Float(piRating))
            }
            if let privacyRating = aggregatedPersonalInformation?.reviewPrivacy {
                privacyRatingView.rating = max(0.0, Float(privacyRating))
            }
            if let picid = aggregatedPersonalInformation?.category, let pic = PersonalInformationCategory.getPersonalInformationCategory(with: picid) {
                personalInformationRatingView.question = pic.question
            }
            layoutIfNeeded()
        }
    }
    
    private var places: [AggregatedPersonalInformationExplanationPlace] = [] {
        didSet {
            if collectionView != nil {
                collectionView.reloadData()
            }
        }
    }
    
    lazy var iconView: IconView = {
        return IconView(icon: "user-circle", iconColor: .white)
    }()
    
    lazy var headerBgView: UIView = {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information explanation"
        if AppDelegate.isIPhone5() {
            label.font = UIFont.italicSystemFont(ofSize: 12.0)
        } else {
            label.font = UIFont.italicSystemFont(ofSize: 14.0)
        }
        label.textAlignment = .left
        label.numberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.textColor = Constants.colors.superLightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var privacyFeedbackRow: CommentRow = {
        let row = CommentRow(with: "You can give us a feedback on the explanation", icon: "chevron-right", backgroundColor: .clear, color: color) { [weak self] in
            if let cat = self?.picid, let pi = self?.aggregatedPersonalInformation {
                self?.delegate?.explanationFeedback(cat: cat, personalInformation: pi)
            }
        }
        return row
    }()
    
    lazy var explanationRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How informative is the explanation?") { [weak self] value in
            if let cat = self?.picid, let pi = self?.aggregatedPersonalInformation {
                pi.reviewExplanation = Int32(value)
                if let picIdx = self?.picIndexPath, let idx = self?.indexPath {
                    self?.delegate?.aggregatedPersonalInformationReview(cat: cat, personalInformation: pi, type: .explanation, rating: Int32(value), picIndexPath: picIdx, personalInformationIndexPath: idx)
                }
            }
        }
        row.color = color
        return row
    }()
    
    private var personalInformationRatingViewHeight: NSLayoutConstraint?
    lazy var personalInformationRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How relevant is the personal information?") { [weak self] value in
            if let cat = self?.picid, let pi = self?.aggregatedPersonalInformation {
                pi.reviewPersonalInformation = Int32(value)
                if let picIdx = self?.picIndexPath, let idx = self?.indexPath {
                    self?.delegate?.aggregatedPersonalInformationReview(cat: cat, personalInformation: pi, type: .personalInformation, rating: Int32(value), picIndexPath: picIdx, personalInformationIndexPath: idx)
                }
            }
        }
        row.color = color
        return row
    }()
    
    private var privacyRatingViewHeight: NSLayoutConstraint?
    lazy var privacyRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How sensitive is the personal information?") { [weak self] value in
            if let cat = self?.picid, let pi = self?.aggregatedPersonalInformation {
                pi.reviewPrivacy = Int32(value)
                if let picIdx = self?.picIndexPath, let idx = self?.indexPath {
                    self?.delegate?.aggregatedPersonalInformationReview(cat: cat, personalInformation: pi, type: .privacy, rating: Int32(value), picIndexPath: picIdx, personalInformationIndexPath: idx)
                }
            }
        }
        row.color = color
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
    
    private var collectionView: UICollectionView!
    let cellId = "CellId"
    
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
        self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 50, height: overlayFrame.height - 50)
        self.center = CGPoint(x: overlayFrame.width / 2.0, y: overlayFrame.height / 2.0)
        backgroundColor = .white
        clipsToBounds = true
        layer.cornerRadius = 10
        
        // CollectionView
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(AggregatedPersonalInformationExplanationOverlayCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.backgroundColor = UIColor.white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset = UIEdgeInsets(top: 10.0, left: 0, bottom: 10.0, right: 0)
        addSubview(collectionView)
        
        let vStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        vStackView.axis = .vertical
        vStackView.distribution = .equalSpacing
        vStackView.alignment = .leading
        vStackView.spacing = 2
        
        iconView.widthAnchor.constraint(equalToConstant: 25.0).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        
        let hStackView = UIStackView(arrangedSubviews: [iconView, vStackView])
        hStackView.axis = .horizontal
        hStackView.distribution = .fillProportionally
        hStackView.alignment = .top
        hStackView.spacing = 8
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        headerBgView.addSubview(hStackView)
        
        // add constraints
        headerBgView.addVisualConstraint("H:|-14-[title]-14-|", views: ["title": hStackView])
        if AppDelegate.isIPhone5() {
            headerBgView.addVisualConstraint("V:|-(14@750)-[title]-(10@750)-|", views: ["title": hStackView])
        } else {
            headerBgView.addVisualConstraint("V:|-(28@750)-[title]-(18@750)-|", views: ["title": hStackView])
        }
        addSubview(headerBgView)
        
        addSubview(dividerLineView)
        addSubview(personalInformationRatingView)
        addSubview(privacyRatingView)
        addSubview(explanationRatingView)
        addSubview(privacyFeedbackRow)
        addSubview(dismissButton)
        
        
        addVisualConstraint("H:|[v0]|", views: ["v0": headerBgView])
        addVisualConstraint("H:|[v0]|", views: ["v0": collectionView])
        addVisualConstraint("H:|[v0]|", views: ["v0": dividerLineView])
        addVisualConstraint("H:|[v0]|", views: ["v0": personalInformationRatingView])
        addVisualConstraint("H:|[v0]|", views: ["v0": privacyRatingView])
        addVisualConstraint("H:|[v0]|", views: ["v0": explanationRatingView])
        addVisualConstraint("H:|[v0]|", views: ["v0": privacyFeedbackRow])
        addVisualConstraint("H:|[v0]|", views: ["v0": dismissButton])
        
        if AppDelegate.isIPhone5() {
            addVisualConstraint("V:|[header][collection][line(0.5)]-[info(35@750)][privacy(35@750)][rating(35)][feedback(35)]-[dismiss(45)]|", views: ["header": headerBgView, "collection": collectionView, "line": dividerLineView, "info": personalInformationRatingView, "privacy": privacyRatingView, "rating": explanationRatingView, "feedback": privacyFeedbackRow, "dismiss": dismissButton])
        } else {
            addVisualConstraint("V:|[header][collection][line(0.5)]-[info(40@750)][privacy(40@750)][rating(40)][feedback(40)]-[dismiss(50)]|", views: ["header": headerBgView, "collection": collectionView, "line": dividerLineView, "info": personalInformationRatingView, "privacy": privacyRatingView, "rating": explanationRatingView, "feedback": privacyFeedbackRow, "dismiss": dismissButton])
        }
        
        personalInformationRatingViewHeight = NSLayoutConstraint(item: personalInformationRatingView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        personalInformationRatingViewHeight?.isActive = true
        personalInformationRatingView.isHidden = true
        
        privacyRatingViewHeight = NSLayoutConstraint(item: privacyRatingView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        privacyRatingViewHeight?.isActive = true
        privacyRatingView.isHidden = true
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! AggregatedPersonalInformationExplanationOverlayCell
        cell.delegate = self
        cell.indexPath = indexPath
        cell.color = color
        cell.explanationPlace = places[indexPath.item]
        cell.setupViews()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 1 - instanciate a new cell
        let cell = AggregatedPersonalInformationExplanationOverlayCell()
        let expPlace = places[indexPath.item]
        cell.explanationPlace = expPlace
        
        // 3 - get the height
        let height = cell.height(withConstrainedWidth: frame.width)
        
        print("height: \(height)")
        
        // 4 - return the correct size
        return CGSize(width: frame.width, height: height)
    }
    
    // MARK: - PersonalInformationCellDelegate methods
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: FeedbackType, indexPath: IndexPath?) {
        
        self.delegate?.placePersonalInformationReview(personalInformation: personalInformation, rating: answer.rawValue)
    }
}

class AggregatedPersonalInformationExplanationOverlayCell : UICollectionViewCell {
    var delegate: PersonalInformationCellDelegate?
    var indexPath: IndexPath?
    var explanationPlace: AggregatedPersonalInformationExplanationPlace? {
        didSet {
            if let expPlace = explanationPlace {
                titleLabel.text = expPlace.place.name
                if let icon = expPlace.place.icon {
                    iconView.image =  UIImage(named: icon)!.withRenderingMode(.alwaysTemplate)
                }
                let nov = expPlace.numberOfVisits
                let visitStr = nov > 2 ? "\(nov) times" : (nov == 2 ? "twice" : "once")
                explanationLabel.text = "You visited this place \(visitStr)."
                
                feedbackRow.selectedFeedback = FeedbackType(rawValue: expPlace.pi.rating)!
                
                layoutIfNeeded()
            }
        }
    }
    var color: UIColor = Constants.colors.lightOrange {
        didSet {
            iconView.color = color
            feedbackRow.selectedColor = color
            feedbackRow.unselectedColor = color.withAlphaComponent(0.3)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var iconView: RoundIconView = {
        let iconDiameter: CGFloat = AppDelegate.isIPhone5() ? 25.0 : 30.0
        return RoundIconView(image: UIImage(named: "map-marker")!, color: color, imageColor: .white, diameter: iconDiameter, scale: 0.6)
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Place"
        if AppDelegate.isIPhone5() {
            label.font = UIFont.boldSystemFont(ofSize: 14)
        } else {
            label.font = UIFont.boldSystemFont(ofSize: 15)
        }
        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .left
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var explanationLabel: UILabel = {
        let label = UILabel()
        label.text = "Explanations"
        if AppDelegate.isIPhone5() {
            label.font = UIFont.italicSystemFont(ofSize: 12)
        } else {
            label.font = UIFont.italicSystemFont(ofSize: 13)
        }
        label.textColor = Constants.colors.lightGray
        label.numberOfLines = 0
        label.textAlignment = .left
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var feedbackRow: FeedbackRowUltraCondensed = {
        let iconDiameter: CGFloat = AppDelegate.isIPhone5() ? 25.0 : 30.0
        let row = FeedbackRowUltraCondensed(onChange: { [weak self] feedback in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.didPressPersonalInformationReview(personalInformation: strongSelf.explanationPlace?.pi, answer: feedback, indexPath: strongSelf.indexPath)

        }, iconDiameter: iconDiameter)
        if let rating = self.explanationPlace?.pi.rating {
            row.selectedFeedback = FeedbackType(rawValue: rating)!
        }
        row.selectedColor = color
        row.unselectedColor = color.withAlphaComponent(0.3)
        return row
    }()
    
    func setupViews() {
        let vStackView = UIStackView(arrangedSubviews: [titleLabel, explanationLabel])
        vStackView.axis = .vertical
        vStackView.distribution = .equalSpacing
        vStackView.alignment = .leading
        vStackView.spacing = 2
        
        let iconDiameter: CGFloat = AppDelegate.isIPhone5() ? 25.0 : 30.0
        
        iconView.widthAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        
        let hStackView = UIStackView(arrangedSubviews: [iconView, vStackView])
        hStackView.axis = .horizontal
        hStackView.distribution = .fillProportionally
        hStackView.alignment = .top
        hStackView.spacing = 10
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStackView)
        addSubview(feedbackRow)
        
        addVisualConstraint("H:|-14-[v0]-[feedback]-14-|", views: ["v0": hStackView, "feedback": feedbackRow])
        addVisualConstraint("V:|-[v0]-|", views: ["v0": hStackView])
        feedbackRow.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        feedbackRow.widthAnchor.constraint(equalToConstant: iconDiameter).isActive = true
    }
    
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        var w = width - 46.0
        if AppDelegate.isIPhone5() {
            w -= 50.0 // 25.0 + 25.0
        } else {
            w -= 60.0 // 30.0 + 30.0
        }
        
        print("width: \(w), title: \(titleLabel.text!.height(withConstrainedWidth: w, font: titleLabel.font)), explanation: \(explanationLabel.text!.height(withConstrainedWidth: w, font: explanationLabel.font))")
        
        
        
        return 20.0 // 8 + 8 + 2
            + titleLabel.text!.height(withConstrainedWidth: w, font: titleLabel.font)
            + explanationLabel.text!.height(withConstrainedWidth: w, font: explanationLabel.font)
    }
}
