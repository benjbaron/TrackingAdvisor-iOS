//
//  PersonalInformationReviewCategory.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/7/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import FloatRatingView

protocol PersonalInformationReviewCategoryDelegate {
    func personalInformationReview(cat: String, personalInformation: AggregatedPersonalInformation, type: ReviewType, rating: Int32)
    func explanationFeedback(cat: String, personalInformation: AggregatedPersonalInformation)
}

class PersonalInformationReviewCategory: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PersonalInformationReviewCellDelegate {
    
    var delegate: PersonalInformationReviewCategoryDelegate?
    var personalInformationCategory: PersonalInformationCategory? {
        didSet {
            if let name = personalInformationCategory?.name {
                nameLabel.text = name
            }
            if let icon = personalInformationCategory?.icon {
                iconView.icon = icon
            }
        }
    }
    var personalInformation: [AggregatedPersonalInformation]? = [] { didSet {
        if let pi = personalInformation {
            personalInformation = pi.sorted(by: {
                $0.name ?? "" < $1.name ?? ""
            })
            infoCollectionView.reloadData()
            count = 1
        }
    }}
    var color: UIColor? {
        didSet { iconView.iconColor = color }
    }
    var count: Int = 1 {
        didSet {
            guard let piCount = personalInformation?.count else { return }
            // Update the card count
            if count > piCount {
                cardCountLabel.alpha = 0
            } else {
                cardCountLabel.alpha = 1
                cardCountLabel.text = "\(count) out of \(piCount)"
            }
        }
    }
    
    fileprivate let cellId = "infoCellId"
    fileprivate let cellAddId = "infoCellAddId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let iconView: IconView = {
        return IconView(icon: "user-circle", iconColor: Constants.colors.primaryLight)
    }()
    
    var flowLayout: PlaceReviewLayout!
    var infoCollectionView: UICollectionView!
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cardCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "X out of Y"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func setupViews() {
        backgroundColor = UIColor.clear
        
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        flowLayout.xCellFrameScaling = 0.96
        infoCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewLayout())
        infoCollectionView.dataSource = self
        infoCollectionView.delegate = self
        infoCollectionView.backgroundColor = .white
        infoCollectionView.showsHorizontalScrollIndicator = false
        infoCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // register cell type
        infoCollectionView.register(PersonalInformationReviewCell.self, forCellWithReuseIdentifier: cellId)
        
        addSubview(infoCollectionView)
        addSubview(dividerLineView)
        addSubview(nameLabel)
        addSubview(iconView)
        addSubview(cardCountLabel)
        
        addVisualConstraint("H:|-14-[icon(20)]-[text]-14-|", views: ["icon": iconView, "text": nameLabel])
        iconView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": dividerLineView])
        addVisualConstraint("H:|[v0]|", views: ["v0": infoCollectionView])
        addVisualConstraint("H:|[v0]|", views: ["v0": cardCountLabel])
        addVisualConstraint("V:|[nameLabel(30)][v0]-[v2]-[v1(0.5)]-0.5-|", views: ["v0": infoCollectionView, "v1": dividerLineView, "nameLabel": nameLabel, "v2": cardCountLabel])
        
        infoCollectionView.layoutIfNeeded()
        
        // Setup collection view bounds
        let collectionViewFrame = infoCollectionView.frame
        flowLayout.cellWidth = floor(collectionViewFrame.width * flowLayout.xCellFrameScaling)
        flowLayout.cellHeight = floor(collectionViewFrame.height * flowLayout.yCellFrameScaling)
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - flowLayout.cellHeight) / 2.0)
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = insetX
        flowLayout.minimumLineSpacing = insetX
        
        infoCollectionView.collectionViewLayout = flowLayout
        infoCollectionView.isPagingEnabled = false
        infoCollectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = personalInformation?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationReviewCell
        cell.personalInformation = personalInformation?[indexPath.item]
        cell.color = color!
        cell.delegate = self
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = infoCollectionView.contentOffset
        visibleRect.size = infoCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath = infoCollectionView.indexPathForItem(at: visiblePoint)
        guard let indexPath = visibleIndexPath else { return }
        
        count = indexPath.item + 1
    }
    
    // PersonalInformationReviewCellDelegate methods
    func didReviewPersonalInformation(personalInformation: AggregatedPersonalInformation?, type: ReviewType, rating: Int32) {
        guard let pi = personalInformation, let cat = personalInformation?.category else { return }
        delegate?.personalInformationReview(cat: cat, personalInformation: pi, type: type, rating: rating)
    }
    
    func didTapFeedbackExplanation(for personalInformation: AggregatedPersonalInformation) {
        guard let cat = personalInformation.category else { return }
        delegate?.explanationFeedback(cat: cat, personalInformation: personalInformation)
    }
}


protocol PersonalInformationReviewCellDelegate {
    func didReviewPersonalInformation(personalInformation: AggregatedPersonalInformation?, type: ReviewType, rating: Int32)
    func didTapFeedbackExplanation(for personalInformation: AggregatedPersonalInformation)
}

class PersonalInformationReviewCell: UICollectionViewCell {
    var delegate: PersonalInformationReviewCellDelegate?
    var personalInformation: AggregatedPersonalInformation? {
        didSet {
            if let name = personalInformation?.name {
                nameLabel.text = name
                layoutIfNeeded()
            }
            if let explanation = personalInformation?.getExplanation() {
                explanationLabel.text = explanation
            }
            if let piRating = personalInformation?.reviewPersonalInformation {
                personalInformationRatingView.rating = max(1.0, Float(piRating))
            }
            if let explanationRating = personalInformation?.reviewExplanation {
                explanationRatingView.rating = max(1.0, Float(explanationRating))
            }
            if let privacyRating = personalInformation?.reviewPrivacy {
                privacyRatingView.rating = max(1.0, Float(privacyRating))
            }
            if let picid = personalInformation?.category, let pic = PersonalInformationCategory.getPersonalInformationCategory(with: picid) {
                personalInformationRatingView.question = pic.question
            }
        }
    }
    var color: UIColor? = UIColor.orange {
        didSet {
            bgView.backgroundColor = color!.withAlphaComponent(0.3)
            nameLabel.textColor = color!
            explanationLabel.textColor = color!
            dividerLineView.backgroundColor = color!
            personalInformationRatingView.color = color
            explanationRatingView.color = color
            privacyRatingView.color = color
            privacyFeedbackRow.color = color
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = color!.withAlphaComponent(0.3)
        return v
    }()
    
    lazy var dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = color
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var explanationLabel: UILabel = {
        let label = UILabel()
        label.text = "Explanations"
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.textColor = color
        label.numberOfLines = 3
        label.textAlignment = .center
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var personalInformationRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How relevant is the personal information?") { [weak self] value in
            print("personalInformationRating changed \(value)")
            if let pi = self?.personalInformation {
                pi.reviewPersonalInformation = Int32(value)
                self?.delegate?.didReviewPersonalInformation(personalInformation: pi, type: .personalInformation, rating: Int32(value))
            }
        }
        row.color = color
        return row
    }()
    
    lazy var explanationRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How informative is the explanation?") { [weak self] value in
            print("explanationRating changed \(value)")
            if let pi = self?.personalInformation {
                pi.reviewExplanation = Int32(value)
                self?.delegate?.didReviewPersonalInformation(personalInformation: pi, type: .explanation, rating: Int32(value))
            }
        }
        row.color = color
        return row
    }()
    
    lazy var privacyRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How sensitive is the personal information?") { [weak self] value in
            print("privacyRating changed \(value)")
            if let pi = self?.personalInformation {
                pi.reviewPrivacy = Int32(value)
                self?.delegate?.didReviewPersonalInformation(personalInformation: pi, type: .privacy, rating: Int32(value))
            }
        }
        row.color = color
        return row
    }()
    
    lazy var privacyFeedbackRow: CommentRow = {
        let row = CommentRow(with: "You can give us some feedback on the explanation", icon: "chevron-right", backgroundColor: .clear, color: color) { [weak self] in
            print("tapped on privacyFeedbackRow")
            if let pi = self?.personalInformation {
                self?.delegate?.didTapFeedbackExplanation(for: pi)
            }
        }
        return row
    }()
    
    func setupViews() {
        // for performance improvements
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        addSubview(bgView)
        bgView.addSubview(nameLabel)
        bgView.addSubview(explanationLabel)
        bgView.addSubview(dividerLineView)
        bgView.addSubview(personalInformationRatingView)
        bgView.addSubview(explanationRatingView)
        bgView.addSubview(privacyRatingView)
        bgView.addSubview(privacyFeedbackRow)
        
        addVisualConstraint("H:|-[v0]-|", views: ["v0": nameLabel])
        addVisualConstraint("H:|-[v0]-|", views: ["v0": explanationLabel])
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": dividerLineView])
        addVisualConstraint("H:|[v0]|", views: ["v0": personalInformationRatingView])
        addVisualConstraint("H:|[v0]|", views: ["v0": explanationRatingView])
        addVisualConstraint("H:|[v0]|", views: ["v0": privacyRatingView])
        addVisualConstraint("H:|[v0]|", views: ["v0": privacyFeedbackRow])
        
        addVisualConstraint("V:|-10-[v0]-[v1]-10-[v2(0.5)]-15-[v3(40)]-[v4(40)]-[v5(40)]", views: ["v0": nameLabel, "v1": explanationLabel, "v2": dividerLineView, "v3": personalInformationRatingView, "v4": explanationRatingView, "v5": privacyRatingView])
        addVisualConstraint("V:[v3(40)]-10-|", views: ["v3": privacyFeedbackRow])
        
        addVisualConstraint("H:|[v0]|", views: ["v0": bgView])
        addVisualConstraint("V:|[v0]|", views: ["v0": bgView])
    }
    
    func height() -> CGFloat {
        return 10 + 50 + 90 + 10 + 0.5 + 10 + 40 + 8 + 40 + 8 + 40 + 8 + 40 + 10
    }
}



