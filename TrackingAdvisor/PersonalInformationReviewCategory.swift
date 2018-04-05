//
//  PersonalInformationReviewCategory.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/7/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import FloatRatingView

@objc protocol PersonalInformationReviewCategoryDelegate {
    func personalInformationReview(cat: String, personalInformation: AggregatedPersonalInformation, type: ReviewType, rating: Int32, picIndexPath: IndexPath, personalInformationIndexPath: IndexPath)
    func explanationFeedback(cat: String, personalInformation: AggregatedPersonalInformation)
    @objc optional func showPlaces(cat: String, personalInformation: AggregatedPersonalInformation, picIndexPath: IndexPath, personalInformationIndexPath: IndexPath)
    @objc optional func goToNextPersonalInformation(currentPersonalInformation: AggregatedPersonalInformation?, picIndexPath: IndexPath?, personalInformationIndexPath: IndexPath?)
    @objc optional func goToNextPersonalInformationCategory(picIndexPath: IndexPath?)
}

class PersonalInformationReviewCategory: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PersonalInformationReviewCellDelegate {
    
    var indexPath: IndexPath?  // picIndexPath
    var delegate: PersonalInformationReviewCategoryDelegate?
    var lastPI: Bool = false
    var status: Int = -1 { didSet {
        guard let picid = personalInformationCategory?.picid else { return }
        print("\(picid) - status \(status)")
        if status+1 == personalInformation.count {
            print("\(picid) - end container \(personalInformation.count)")
            setupEndContainerView()
        } else {
            setupCollectionView()
            infoCollectionView.scrollToItem(at: IndexPath(item: status+1, section: 0), at: .centeredHorizontally, animated: false)
            count = personalInformation.count - (status+1)
            print("\tcount: \(count)")
        }
    }}
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
    var personalInformation: [AggregatedPersonalInformation] = [] { didSet {
        personalInformation = personalInformation.sorted(by: {
            $0.name ?? "" < $1.name ?? ""
        })
        if infoCollectionView != nil {
            infoCollectionView.reloadData()
        }
        count = personalInformation.count
    }}
    var color: UIColor = Constants.colors.orange {
        didSet { iconView.iconColor = color }
    }
    var count: Int = 1 {
        didSet {
            guard let picid = personalInformationCategory?.picid else { return }
            let piCount = personalInformation.count
            print("\(picid) - \(count) / \(piCount)")
            // Update the card count
            if count > piCount {
                cardCountLabel.alpha = 0
            } else {
                cardCountLabel.alpha = 1
                if count == 1 {
                    cardCountLabel.text = "Last one"
                } else {
                    cardCountLabel.text = "\(count) left"
                }
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
    var containerView: UIView!
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cardCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "\(count) left"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nextPIButton: UIButton = {
        let l = UIButton(type: .system)
        l.layer.cornerRadius = 5.0
        l.layer.masksToBounds = true
        if self.lastPI {
            l.setTitle("Finish", for: .normal)
        } else {
            l.setTitle("Next personal information", for: .normal)
        }
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.numberOfLines = 2
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.setTitleColor(color, for: .normal)
        l.backgroundColor = color.withAlphaComponent(0.3)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedNextPIButton), for: .touchUpInside)
        return l
    }()
    
    @objc fileprivate func tappedNextPIButton() {
        self.delegate?.goToNextPersonalInformationCategory?(picIndexPath: indexPath)
    }
    
    func setupCollectionView() {
        print("setupCollectionView")
        // remove all subviews from the container view
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        flowLayout.xCellFrameScaling = 0.96
        infoCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewLayout())
        infoCollectionView.dataSource = self
        infoCollectionView.delegate = self
        infoCollectionView.backgroundColor = .white
        infoCollectionView.showsHorizontalScrollIndicator = false
        infoCollectionView.translatesAutoresizingMaskIntoConstraints = false
        infoCollectionView.isScrollEnabled = false
        
        // register cell type
        infoCollectionView.register(PersonalInformationReviewCell.self, forCellWithReuseIdentifier: cellId)
        
        // add the collectionview to the container view
        containerView.addSubview(infoCollectionView)
        containerView.addSubview(cardCountLabel)
        containerView.addVisualConstraint("H:|[v0]|", views: ["v0": cardCountLabel])
        containerView.addVisualConstraint("H:|[v0]|", views: ["v0": infoCollectionView])
        containerView.addVisualConstraint("V:|[v0][v1]|", views: ["v0": infoCollectionView, "v1": cardCountLabel])
        
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
    
    func setupEndContainerView() {
        // remove all the subviews from the container view
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        
        // setup the text
        let label = UILabel()
        label.text = "Thank you for reviewing the personal information"
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        
        // setup the next place button
        containerView.addSubview(nextPIButton)
        containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": nextPIButton])
        containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": label])
        containerView.addVisualConstraint("V:|-14-[v0]-[v1(64)]-25-|", views: ["v0": label, "v1": nextPIButton])
    }
    
    func setupViews() {
        backgroundColor = UIColor.clear
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        
        addSubview(dividerLineView)
        addSubview(nameLabel)
        addSubview(iconView)
        
        addVisualConstraint("H:|-14-[icon(20)]-[text]-14-|", views: ["icon": iconView, "text": nameLabel])
        iconView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": dividerLineView])
        addVisualConstraint("H:|[v0]|", views: ["v0": containerView])
        addVisualConstraint("V:|[nameLabel(30)][v0]-[v1(0.5)]-0.5-|", views: ["v0": containerView, "v1": dividerLineView, "nameLabel": nameLabel])
        
        setupCollectionView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return personalInformation.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationReviewCell
        cell.personalInformation = personalInformation[indexPath.item]
        cell.color = color
        cell.delegate = self
        cell.indexPath = indexPath
        print("lastPI: \(indexPath.item) / \(personalInformation.count)")
        cell.lastPI = indexPath.item+1 == personalInformation.count
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = infoCollectionView.contentOffset
        visibleRect.size = infoCollectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath = infoCollectionView.indexPathForItem(at: visiblePoint)
        guard let indexPath = visibleIndexPath else { return }
        
        count = personalInformation.count - indexPath.item
    }
    
    // PersonalInformationReviewCellDelegate methods
    func didReviewPersonalInformation(personalInformation: AggregatedPersonalInformation?, type: ReviewType, rating: Int32, indexPath: IndexPath?) {
        guard let pi = personalInformation, let cat = personalInformation?.category else { return }
        if let picIdx = self.indexPath, let indexPath = indexPath {
            delegate?.personalInformationReview(cat: cat, personalInformation: pi, type: type, rating: rating, picIndexPath: picIdx, personalInformationIndexPath: indexPath)
        }
    }
    
    func didTapFeedbackExplanation(for personalInformation: AggregatedPersonalInformation) {
        guard let cat = personalInformation.category else { return }
        delegate?.explanationFeedback(cat: cat, personalInformation: personalInformation)
    }
    
    func didTapHeader(for personalInformation: AggregatedPersonalInformation, indexPath: IndexPath?) {
        guard let cat = personalInformation.category else { return }
        
        if let picIdx = self.indexPath, let indexPath = indexPath {
            delegate?.showPlaces?(cat: cat, personalInformation: personalInformation, picIndexPath: picIdx, personalInformationIndexPath: indexPath)
        }
    }
    
    func didTapNextPersonalInformationButton(currentPersonalInformation: AggregatedPersonalInformation?, indexPath: IndexPath?) {
        
        delegate?.goToNextPersonalInformation?(currentPersonalInformation: currentPersonalInformation, picIndexPath: self.indexPath, personalInformationIndexPath: indexPath)
        
         if let indexPath = indexPath {
            let piCount = self.personalInformation.count
            // scroll to next item
            if piCount > indexPath.item + 1 {
                infoCollectionView.scrollToItem(at: IndexPath(item: indexPath.item+1, section:indexPath.section), at: .centeredHorizontally, animated: true)
                count -= 1
            } else {
                setupEndContainerView()
            }
        }
    }
}


protocol PersonalInformationReviewCellDelegate {
    func didReviewPersonalInformation(personalInformation: AggregatedPersonalInformation?, type: ReviewType, rating: Int32, indexPath: IndexPath?)
    func didTapFeedbackExplanation(for personalInformation: AggregatedPersonalInformation)
    func didTapHeader(for personalInformation: AggregatedPersonalInformation, indexPath: IndexPath?)
    func didTapNextPersonalInformationButton(currentPersonalInformation: AggregatedPersonalInformation?, indexPath: IndexPath?)
}

class PersonalInformationReviewCell: UICollectionViewCell {
    
    var indexPath: IndexPath? // personalInformation
    var delegate: PersonalInformationReviewCellDelegate?
    var lastPI: Bool = false {
        didSet {
            setButtonTitle()
        }
    }
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
                canSkip = canSkip || piRating > 0
            }
            if let privacyRating = personalInformation?.reviewPrivacy {
                privacyRatingView.rating = max(1.0, Float(privacyRating))
                canSkip = canSkip || privacyRating > 0
            }
            if let picid = personalInformation?.category, let pic = PersonalInformationCategory.getPersonalInformationCategory(with: picid) {
                personalInformationRatingView.question = pic.question
            }
        }
    }
    var color: UIColor = Constants.colors.orange {
        didSet {
            bgView.backgroundColor = color.withAlphaComponent(0.3)
            headerView.backgroundColor = color.withAlphaComponent(0.75)
            nameLabel.textColor = .white
            explanationLabel.textColor = Constants.colors.superLightGray
            personalInformationRatingView.color = color
            privacyRatingView.color = color
        }
    }
    var canSkip: Bool = false { didSet {
        nextButton.isEnabled = canSkip
        setButtonTitle()
    }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = color.withAlphaComponent(0.3)
        return v
    }()
    
    lazy var headerView: UIView = {
        let v = UIView()
        v.backgroundColor = color.withAlphaComponent(0.75)
        v.layer.masksToBounds = false
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var explanationLabel: UILabel = {
        let label = UILabel()
        label.text = "Explanations"
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.textColor = Constants.colors.superLightGray
        label.numberOfLines = 3
        label.textAlignment = .center
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var personalInformationRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How relevant is the personal information?") { [weak self] value in
            if let pi = self?.personalInformation, let canSkip = self?.canSkip {
                self?.canSkip = canSkip || value > 0
                pi.reviewPersonalInformation = Int32(value)
                self?.delegate?.didReviewPersonalInformation(personalInformation: pi, type: .personalInformation, rating: Int32(value), indexPath: self?.indexPath)
            }
        }
        row.color = color
        return row
    }()
    
    lazy var privacyRatingView: QuestionRatingRow = {
        let row = QuestionRatingRow(with: "How sensitive is the personal information?") { [weak self] value in
            if let pi = self?.personalInformation, let canSkip = self?.canSkip {
                self?.canSkip = canSkip ||  value > 0
                pi.reviewPrivacy = Int32(value)
                self?.delegate?.didReviewPersonalInformation(personalInformation: pi, type: .privacy, rating: Int32(value), indexPath: self?.indexPath)
            }
        }
        row.color = color
        return row
    }()
    
    private lazy var nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.layer.masksToBounds = true
        btn.setTitle("Next one", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        btn.setTitleColor(Constants.colors.superLightGray, for: .normal)
        btn.setTitleColor(color, for: .highlighted)
        btn.setBackgroundColor(color, for: .normal)
        btn.setBackgroundColor(Constants.colors.lightGray, for: .highlighted)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tappedNextButton), for: .touchUpInside)
        btn.isEnabled = false // default behaviour
        return btn
    }()
    
    @objc fileprivate func tappedNextButton() {
        self.delegate?.didTapNextPersonalInformationButton(currentPersonalInformation: personalInformation, indexPath: indexPath)
    }
    
    func setupViews() {
        // for performance improvements
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        addSubview(bgView)

        headerView.addSubview(nameLabel)
        headerView.addSubview(explanationLabel)

        headerView.addVisualConstraint("H:|-[v0]-|", views: ["v0": nameLabel])
        headerView.addVisualConstraint("H:|-[v0]-|", views: ["v0": explanationLabel])
        headerView.addVisualConstraint("V:|-[v0]-[v1]-10-|", views: ["v0": nameLabel, "v1": explanationLabel])
        
        bgView.addSubview(headerView)
        bgView.addSubview(personalInformationRatingView)
        bgView.addSubview(privacyRatingView)
        bgView.addSubview(nextButton)
        
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": headerView])
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": personalInformationRatingView])
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": privacyRatingView])
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": nextButton])
        
        bgView.addVisualConstraint("V:|[header]-10-[v3(40)]-[v4(40)]-10-[next(50)]|", views: ["header": headerView, "v1": explanationLabel, "v3": personalInformationRatingView, "v4": privacyRatingView, "next": nextButton])
        
        addVisualConstraint("H:|[v0]|", views: ["v0": bgView])
        addVisualConstraint("V:|[v0]|", views: ["v0": bgView])
        
        headerView.addTapGestureRecognizer { [weak self] in
            if let pi = self?.personalInformation {
                self?.delegate?.didTapHeader(for: pi, indexPath: self?.indexPath)
            }
        }
    }
    
    func setButtonTitle() {
        if self.canSkip {
            if self.lastPI {
                nextButton.setTitle("Finish", for: .normal)
            } else {
                nextButton.setTitle("Next one", for: .normal)
            }
        } else {
            nextButton.setTitle("Please give a rating", for: .normal)
        }
    }
    
    func height() -> CGFloat {
        return 10 + 50 + 90 + 10 + 0.5 + 10 + 40 + 8 + 40 + 10
    }
}



