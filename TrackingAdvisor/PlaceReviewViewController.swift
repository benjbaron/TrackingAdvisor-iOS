//
//  ProfileViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/22/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit
import Cosmos

protocol PlaceReviewCellDelegate {
    func didEndPlaceReview()
    func didChangeToNextPlaceReview(current: Int, next: Int)
}

class PlaceReviewViewController: UIViewController, UICollectionViewDataSource, PlaceReviewCellDelegate, DataStoreUpdateProtocol {
    
    var fullScreenView: FullScreenView?
    var collectionView: UICollectionView!
    var mainTitle: UILabel = {
        let label = UILabel()
        label.text = "Places to review"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var flowLayout: PlaceReviewLayout!
    var reviewChallenges: [ReviewChallenge] = [] {
        didSet {
            if reviewChallenges.count > 0 {
                fullScreenView?.removeFromSuperview()
                collectionView.reloadData()
                setTabBarCount(with: reviewChallenges.count)
            }
            setTabBarCount(with: nil)
        }
    }
    
    var updatedReviews: [String:Int32] = [:]  // [reviewId : Answer]
    var updateChallenges: [String:Date] = [:] // [challengeId : dateCompleted]
    let cellId = "PlaceReviewCell"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fullScreenView?.removeFromSuperview()
        
        DataStoreService.shared.delegate = self
        reviewChallenges = DataStoreService.shared.getLatestReviewChallenge(ctxt: nil)
        if reviewChallenges.count == 0 { // no challenges are available
            fullScreenView = FullScreenView(frame: view.frame)
            fullScreenView!.icon = "rocket"
            fullScreenView!.iconColor = Constants.colors.primaryLight
            fullScreenView!.headerTitle = "Places to review"
            fullScreenView!.subheaderTitle = "After moving to a few places, we will ask you to review some information related to these places"
            view.addSubview(fullScreenView!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // retrieve latest review challenges
        UserUpdateHandler.retrievingLatestReviewChallenge(for: DateHandler.dateToDayString(from: Date()))
        
        // setup the collection view
        let flowLayout = PlaceReviewLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewLayout())
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Register cells types
        collectionView.register(PlaceReviewChallengeCell.self, forCellWithReuseIdentifier: cellId)
        
        // Add constraints
        view.addSubview(collectionView)

        view.addVisualConstraint("H:|[v0]|", views: ["v0": collectionView])
        
        collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40.0).isActive = true
        if #available(iOS 11.0, *) {
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            collectionView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        }
        collectionView.layoutIfNeeded()
        
        // Setup collection view bounds
        let tabbarOffset:CGFloat = 49.0 // tabbar height
        let collectionViewFrame = collectionView.frame
        flowLayout.cellWidth = floor(collectionViewFrame.width * flowLayout.xCellFrameScaling)
        flowLayout.cellHeight = floor((collectionViewFrame.height - tabbarOffset) * flowLayout.yCellFrameScaling) // for the tab bar
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - tabbarOffset - flowLayout.cellHeight) / 2.0)
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = insetX - 25.0 // to show the next cell
        flowLayout.minimumLineSpacing = insetX - 25 // to show the next cell
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.isPagingEnabled = false
        collectionView.isScrollEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: insetY - 10.0, left: insetX, bottom: insetY + 10.0, right: insetX) // shift the view up
        
        collectionView.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reviewChallenges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? PlaceReviewChallengeCell {
            cell.delegate = self
            cell.parent = collectionView
            cell.indexPath = indexPath
            cell.last = indexPath.item + 1 == collectionView.numberOfItems(inSection: indexPath.section)
            
            let rc = reviewChallenges[indexPath.item]
            cell.visit = rc.visit
            cell.personalInformation = rc.personalInformation
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: - PlaceReviewCellDelegate methods
    func didChangeToNextPlaceReview(current: Int, next: Int) {
        if let rcid = reviewChallenges[current].id {
            let date = Date()
            updateChallenges[rcid] = date
            DataStoreService.shared.saveCompletedReviewChallenge(with: rcid, for: date)
        }
    }
    
    func didEndPlaceReview() {
        // perform save action to the server
        UserUpdateHandler.sendReviewUpdate(reviews: updatedReviews)
        UserUpdateHandler.sendReviewChallengeUpdate(reviewChallenges: updateChallenges)
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            // hide the collection view
            self?.collectionView.alpha = 0
            self?.mainTitle.alpha = 0
        }, completion: { [weak self] success in
            if success {
                guard let strongSelf = self else { return }
                strongSelf.fullScreenView = FullScreenView(frame: strongSelf.view.frame)
                strongSelf.fullScreenView!.icon = "galaxy"
                strongSelf.fullScreenView!.iconColor = Constants.colors.primaryLight
                strongSelf.fullScreenView!.headerTitle = "You're all set!"
                strongSelf.fullScreenView!.subheaderTitle = "Thank you for reviewing the places"
                strongSelf.view.addSubview(strongSelf.fullScreenView!)
            }
        })
    }
    
    // MARK: - DataStoreUpdateProtocol methods
    func dataStoreDidUpdateReviewAnswer(for reviewId: String?, with answer: Int32) {
        if let reviewId = reviewId {
            updatedReviews[reviewId] = answer
        }
    }
    
    func dataStoreDidAddReviewChallenge(for rcid: String?) {
        reviewChallenges = DataStoreService.shared.getLatestReviewChallenge(ctxt: nil)
    }
    
    private func setTabBarCount(with count: Int?) {
        if let tabItems = self.tabBarController?.tabBar.items as NSArray? {
            let tabItem = tabItems[1] as! UITabBarItem
            if count == nil {
                tabItem.badgeValue = nil
            } else {
                tabItem.badgeValue = String(describing: count)
            }
        }
    }
    
}

class PlaceReviewChallengeCell: UICollectionViewCell {
    weak var parent: UICollectionView?
    var delegate: PlaceReviewCellDelegate!
    var color: UIColor = Constants.colors.primaryLight {
        didSet {
            self.headerView.backgroundColor = color
            self.nextPlaceView.backgroundColor = color.withAlphaComponent(0.5)
            
            self.questionPlaceView.selectedColor = color
            self.questionPlaceView.unselectedColor = color.withAlphaComponent(0.3)
            self.placeEditView.color = color.withAlphaComponent(0.7)
            
            self.questionPersonalInformationView.selectedColor = color
            self.questionPersonalInformationView.unselectedColor = color.withAlphaComponent(0.3)
            self.personalInformationEditView.color = color.withAlphaComponent(0.7)
            
            self.questionExplanationView.selectedColor = color
            self.questionExplanationView.unselectedColor = color.withAlphaComponent(0.3)
            
            self.questionPrivacyView.selectedColor = color
            self.questionPrivacyView.unselectedColor = color.withAlphaComponent(0.3)
        }
    }
    
    var personalInformation: PersonalInformation? {
        didSet {
            if let pi = personalInformation {
                self.headerView.placePersonalInformation = pi.getPersonalInformationPhrase()
                self.headerView.placeExplanation = pi.explanation
                
                self.reviewPersonalInformation = pi.getReview(of: .personalInformation)
                self.reviewExplanation = pi.getReview(of: .explanation)
                self.reviewPrivacy = pi.getReview(of: .privacy)

            }
        }
    }
    
    var visit: Visit? {
        didSet {
            if let place = visit?.place {
                self.headerView.placeName = place.name
                self.headerView.placeAddress = place.formatAddressString()
                self.color = place.getPlaceColor()
                self.nextPlaceView.text = last ? "Thank You!" : "Skip this place"
                self.headerView.placePersonalInformation = nil
                self.reviewPlace = visit?.review
            }
        }
    }
    
    var reviewPlace: Review? { didSet {
        questionPlaceView.question = reviewPlace?.question
        answerQuestionPlace = reviewPlace!.answer
    }}
    var reviewPersonalInformation: Review? { didSet {
        questionPersonalInformationView.question = reviewPersonalInformation?.question
        answerQuestionPersonalInformation = reviewPersonalInformation!.answer
    }}
    var reviewExplanation: Review? { didSet {
        questionExplanationView.question = reviewExplanation?.question
        answerQuestionExplanation = reviewExplanation!.answer
    }}
    var reviewPrivacy: Review? { didSet {
        questionPrivacyView.question = reviewPrivacy?.question
        answerQuestionPrivacy = reviewPrivacy!.answer
    }}
    
    var indexPath: IndexPath?
    var last: Bool = false
    
    lazy var headerView: HeaderRow = {
        return HeaderRow()
    }()
    
    lazy var questionPlaceView: QuestionRow = {
        return QuestionRow(with: "Did you visit this place?", yesAction: { [weak self] in
            self?.answerQuestionPlace = .yes
        }, noAction: { [weak self] in
            self?.answerQuestionPlace = .no
        })
    }()
    
    var answerQuestionPlace: ReviewAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            questionPlaceView.selected = answerQuestionPlace
            if let review = reviewPlace {
                review.answer = answerQuestionPlace
                // save in database
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: answerQuestionPlace)
            }
            switch answerQuestionPlace {
            case .yes:
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.placeEditViewHeight?.constant = 0
                    self?.placeEditViewTopMargin?.constant = 0
                    if self?.personalInformation != nil {
                        self?.questionPersonalInformationViewHeight?.constant = 40
                        self?.questionPersonalInformationViewTopMargin?.constant = 8
                        self?.personalInformationViewHeight?.constant = 0
                        self?.personalInformationViewTopMargin?.constant = 0
                        self?.questionExplanationViewHeight?.constant = 40
                        self?.questionExplanationViewTopMargin?.constant = 8
                        self?.questionPrivacyViewHeight?.constant = 40
                        self?.questionPrivacyViewTopMargin?.constant = 8
                    } else {
                        self?.questionPersonalInformationViewHeight?.constant = 0
                        self?.questionPersonalInformationViewTopMargin?.constant = 0
                        self?.personalInformationViewHeight?.constant = 0
                        self?.personalInformationViewTopMargin?.constant = 0
                        self?.questionExplanationViewHeight?.constant = 0
                        self?.questionExplanationViewTopMargin?.constant = 0
                        self?.questionPrivacyViewHeight?.constant = 0
                        self?.questionPrivacyViewTopMargin?.constant = 0
                    }
                    self?.layoutIfNeeded()
                }
            case .no:
                answerQuestionPersonalInformation = .none
                answerQuestionPrivacy = .none
                answerQuestionExplanation = .none
                
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.placeEditViewHeight?.constant = 0
                    self?.placeEditViewTopMargin?.constant = 0
                    self?.questionPersonalInformationViewHeight?.constant = 0
                    self?.questionPersonalInformationViewTopMargin?.constant = 0
                    self?.personalInformationViewHeight?.constant = 0
                    self?.personalInformationViewTopMargin?.constant = 0
                    self?.questionExplanationViewHeight?.constant = 0
                    self?.questionExplanationViewTopMargin?.constant = 0
                    self?.questionPrivacyViewHeight?.constant = 0
                    self?.questionPrivacyViewTopMargin?.constant = 0
                    self?.layoutIfNeeded()
                }
            case .none:
                answerQuestionPersonalInformation = .none
                answerQuestionPrivacy = .none
                answerQuestionExplanation = .none
                
                self.placeEditViewHeight?.constant = 0
                self.placeEditViewTopMargin?.constant = 0
                self.questionPersonalInformationViewHeight?.constant = 0
                self.questionPersonalInformationViewTopMargin?.constant = 0
                self.personalInformationViewHeight?.constant = 0
                self.personalInformationViewTopMargin?.constant = 0
                self.questionExplanationViewHeight?.constant = 0
                self.questionExplanationViewTopMargin?.constant = 0
                self.questionPrivacyViewHeight?.constant = 0
                self.questionPrivacyViewTopMargin?.constant = 0
                self.layoutIfNeeded()
            }
        }
    }
    
    lazy var placeEditView: CommentRow = {
        return CommentRow(with: "It would be great if you could tell us what place you visited", icon: "chevron-right", backgroundColor: UIColor.clear, color: color.withAlphaComponent(0.5)) {
            print("tapped on place edit") // TODO: - Present the modal view PlaceFinderMapTableViewController
        }
    }()
    var placeEditViewHeight: NSLayoutConstraint?
    var placeEditViewTopMargin: NSLayoutConstraint?
    
    lazy var questionPersonalInformationView: QuestionRow = {
        return QuestionRow(with: "Is the personal information correct?", yesAction: { [weak self] in
            self?.answerQuestionPersonalInformation = .yes
        }, noAction: { [weak self] in
            self?.answerQuestionPersonalInformation = .no
        })
    }()
    var questionPersonalInformationViewHeight: NSLayoutConstraint?
    var questionPersonalInformationViewTopMargin: NSLayoutConstraint?
    
    let personalInformationEditView: CommentRow = {
        return CommentRow(with: "It would be great if you could tell us the correct personal information", icon: "chevron-right", backgroundColor: UIColor.clear, color: Constants.colors.superLightGray) {
            print("tapped on personal information edit")
            // TODO: - present PlacePersonalInformationController
        }
    }()
    var personalInformationViewHeight: NSLayoutConstraint?
    var personalInformationViewTopMargin: NSLayoutConstraint?

    var answerQuestionPersonalInformation: ReviewAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            questionPersonalInformationView.selected = answerQuestionPersonalInformation
            if let review = reviewPersonalInformation {
                review.answer = answerQuestionPersonalInformation
                // save in database
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: answerQuestionPersonalInformation)
            }
            switch answerQuestionPersonalInformation {
            case .yes:
                self.questionPersonalInformationViewHeight?.constant = 40
                self.questionPersonalInformationViewTopMargin?.constant = 8
                self.personalInformationViewHeight?.constant = 0
                self.personalInformationViewTopMargin?.constant = 0
                if self.personalInformation != nil {
                    self.questionExplanationViewHeight?.constant = 40
                    self.questionExplanationViewTopMargin?.constant = 8
                    self.questionPrivacyViewHeight?.constant = 40
                    self.questionPrivacyViewTopMargin?.constant = 8
                }
            case .no:
                answerQuestionPrivacy = .none
                answerQuestionExplanation = .none
                self.questionPersonalInformationViewHeight?.constant = 40
                self.questionPersonalInformationViewTopMargin?.constant = 8
                self.personalInformationViewHeight?.constant = 0
                self.personalInformationViewTopMargin?.constant = 0
                self.questionExplanationViewHeight?.constant = 0
                self.questionExplanationViewTopMargin?.constant = 0
                self.questionPrivacyViewHeight?.constant = 0
                self.questionPrivacyViewTopMargin?.constant = 0
            case .none:
                answerQuestionPrivacy = .none
                answerQuestionExplanation = .none
                self.questionPersonalInformationViewHeight?.constant = 40
                self.questionPersonalInformationViewTopMargin?.constant = 8
                self.personalInformationViewHeight?.constant = 0
                self.personalInformationViewTopMargin?.constant = 0
                self.questionExplanationViewHeight?.constant = 0
                self.questionExplanationViewTopMargin?.constant = 0
                self.questionPrivacyViewHeight?.constant = 0
                self.questionPrivacyViewTopMargin?.constant = 0
            }
        }
    }
    
    lazy var questionExplanationView: QuestionRow = {
        return QuestionRow(with: "Is the explanation informative?", yesAction: { [weak self] in
            self?.answerQuestionExplanation = .yes
            }, noAction: { [weak self] in
                self?.answerQuestionExplanation = .no
        })
    }()
    var questionExplanationViewHeight: NSLayoutConstraint?
    var questionExplanationViewTopMargin: NSLayoutConstraint?
    
    var answerQuestionExplanation: ReviewAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            questionExplanationView.selected = answerQuestionExplanation
            if let review = reviewExplanation {
                review.answer = answerQuestionExplanation
                // save in database
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: answerQuestionExplanation)
            }
        }
    }
    
    lazy var questionPrivacyView: QuestionRow = {
        return QuestionRow(with: "Is the inferred information sensitive to you?", yesAction: { [weak self] in
                self?.answerQuestionPrivacy = .yes
            }, noAction: { [weak self] in
                self?.answerQuestionPrivacy = .no
        })
    }()
    var questionPrivacyViewHeight: NSLayoutConstraint?
    var questionPrivacyViewTopMargin: NSLayoutConstraint?
    
    var answerQuestionPrivacy: ReviewAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            questionPrivacyView.selected = answerQuestionPrivacy
            if let review = reviewPrivacy {
                review.answer = answerQuestionPrivacy
                // save in database
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: answerQuestionPrivacy)
            }
        }
    }
    
    lazy var nextPlaceView: FooterRow = {
        var text = "Next place"
        return FooterRow(with: text, backgroundColor: Constants.colors.primaryDark) { [weak self] in
            guard let strongSelf = self else { return }
            if let indexPath = strongSelf.indexPath {
                strongSelf.delegate?.didChangeToNextPlaceReview(current: indexPath.item, next: indexPath.item+1)
                if !strongSelf.last {
                    strongSelf.parent?.scrollToItem(at: IndexPath(item: indexPath.item+1, section:indexPath.section), at: .centeredHorizontally, animated: true)
                } else {
                    // the user has finished reviewing the places
                    strongSelf.delegate?.didEndPlaceReview()
                }
            }
        }
    }()
    
    func clearAllQuestions() {
        questionPlaceView.selected = .none
        questionPersonalInformationView.selected = .none
        questionExplanationView.selected = .none
        questionPrivacyView.selected = .none
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(headerView)
        addSubview(questionPlaceView)
        addSubview(placeEditView)
        addSubview(questionPersonalInformationView)
        addSubview(personalInformationEditView)
        addSubview(questionExplanationView)
        addSubview(questionPrivacyView)
        addSubview(nextPlaceView)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0(200)]", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": headerView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": headerView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[header]-[v0(40)]", options: NSLayoutFormatOptions(), metrics: nil, views: ["header": headerView, "v0": questionPlaceView]))
        
        placeEditViewHeight = NSLayoutConstraint(item: placeEditView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        placeEditViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        placeEditViewHeight?.isActive = true
        
        placeEditViewTopMargin = NSLayoutConstraint(item: placeEditView, attribute: .top, relatedBy: .equal, toItem: questionPlaceView, attribute: .bottom, multiplier: 1, constant: 0)
        placeEditViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        placeEditViewTopMargin?.isActive = true
        
        questionPersonalInformationViewHeight = NSLayoutConstraint(item: questionPersonalInformationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        questionPersonalInformationViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        questionPersonalInformationViewHeight?.isActive = true
        
        questionPersonalInformationViewTopMargin = NSLayoutConstraint(item: questionPersonalInformationView, attribute: .top, relatedBy: .equal, toItem: placeEditView, attribute: .bottom, multiplier: 1, constant: 0)
        questionPersonalInformationViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        questionPersonalInformationViewTopMargin?.isActive = true
        
        personalInformationViewHeight = NSLayoutConstraint(item: personalInformationEditView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        personalInformationViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        personalInformationViewHeight?.isActive = true
        
        personalInformationViewTopMargin = NSLayoutConstraint(item: personalInformationEditView, attribute: .top, relatedBy: .equal, toItem: questionPersonalInformationView, attribute: .bottom, multiplier: 1, constant: 0)
        personalInformationViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        personalInformationViewTopMargin?.isActive = true

        questionExplanationViewHeight = NSLayoutConstraint(item: questionExplanationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        questionExplanationViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        questionExplanationViewHeight?.isActive = true
        
        questionExplanationViewTopMargin = NSLayoutConstraint(item: questionExplanationView, attribute: .top, relatedBy: .equal, toItem: personalInformationEditView, attribute: .bottom, multiplier: 1, constant: 0)
        questionExplanationViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        questionExplanationViewTopMargin?.isActive = true
        
        questionPrivacyViewHeight = NSLayoutConstraint(item: questionPrivacyView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        questionPrivacyViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        questionPrivacyViewHeight?.isActive = true
        
        questionPrivacyViewTopMargin = NSLayoutConstraint(item: questionPrivacyView, attribute: .top, relatedBy: .equal, toItem: questionExplanationView, attribute: .bottom, multiplier: 1, constant: 0)
        questionPrivacyViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        questionPrivacyViewTopMargin?.isActive = true

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionPlaceView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": placeEditView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionPersonalInformationView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": personalInformationEditView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionExplanationView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionPrivacyView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v0(50)]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nextPlaceView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nextPlaceView]))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 3.0
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.layer.backgroundColor = Constants.colors.superLightGray.cgColor
        
        self.clipsToBounds = false
        self.layer.masksToBounds = true
    }
    
    func checkIfEverythingIsAnswered() {
        if (self.personalInformation == nil && answerQuestionPlace != .none) ||
           (answerQuestionPlace == .no) ||
           (answerQuestionPlace == .yes && answerQuestionPersonalInformation == .no) ||
           (answerQuestionPlace == .yes && answerQuestionPersonalInformation != .none
         && answerQuestionExplanation != .none && answerQuestionPrivacy != .none) {
            nextPlaceView.text = last ? "You're done!" : "Next place"
        } else {
            nextPlaceView.text = last ? "Finish" : "Skip this place"
        }
    }
    
}

class PlaceReviewLayout: UICollectionViewFlowLayout {
    var cellWidth: CGFloat = 50
    var cellHeight: CGFloat = 50
    var xCellFrameScaling: CGFloat = 0.8
    var yCellFrameScaling: CGFloat = 0.95
    var cellScaling: CGFloat = 0.95
    
    override init() {
        super.init()
        
        scrollDirection = .horizontal
        itemSize = CGSize(width: cellWidth, height: cellHeight)
        minimumInteritemSpacing = 10
        minimumLineSpacing = 10
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func prepare() {
        super.prepare()
        
        // rate at which we scroll the collection view
        collectionView?.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        let array = super.layoutAttributesForElements(in: rect)!.map { $0.copy() } as! [UICollectionViewLayoutAttributes]
        
        for attributes in array {
            let frame = attributes.frame
            let distance = abs(collectionView!.contentOffset.x + collectionView!.contentInset.left - frame.origin.x)
            let scale = cellScaling * min(max(1 - distance / (4 * collectionView!.bounds.width), cellScaling), 1)
            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        
        return array
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


class QuestionRow : UIView {
    var question: String? {
        didSet {
            questionLabel?.text = question
        }
    }
    var yesAction: (() -> ())?
    var noAction: (() -> ())?
    var selectedColor: UIColor? = Constants.colors.primaryDark {
        didSet {
            let tmp = selected
            selected = tmp
        }
    }
    var unselectedColor: UIColor = Constants.colors.primaryLight {
        didSet {
            let tmp = selected
            selected = tmp
        }
    }
    private var yesView: IconView?
    private var noView: IconView?
    private var questionLabel: UILabel?

    var selected: ReviewAnswer = .none {
        didSet {
            switch selected {
            case .none:
                yesView?.iconColor = unselectedColor
                noView?.iconColor = unselectedColor
            case .yes:
                yesView?.iconColor = selectedColor
                noView?.iconColor = unselectedColor
            case .no:
                yesView?.iconColor = unselectedColor
                noView?.iconColor = selectedColor
            }
            layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(with question: String?, yesAction: @escaping () -> (), noAction: @escaping () -> ()) {
        self.init(frame: CGRect.zero)
        self.question = question
        self.yesAction = yesAction
        self.noAction = noAction
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        yesView = IconView(icon: "check", iconColor: unselectedColor)
        noView = IconView(icon: "times", iconColor: unselectedColor)
        
        guard let yesView = yesView, let noView = noView else { return }
        
        yesView.addTapGestureRecognizer {
            self.selected = .yes
            self.yesAction!()
        }
        noView.addTapGestureRecognizer {
            self.selected = .no
            self.noAction!()
        }
        
        addSubview(yesView)
        addSubview(noView)
        
        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5@999)-[v0]-(5@999)-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": yesView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5@999)-[v0]-(5@999)-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": noView]))

        questionLabel = UILabel()
        questionLabel?.text = question
        questionLabel?.font = UIFont.systemFont(ofSize: 14)
        questionLabel?.numberOfLines = 0
        questionLabel?.textAlignment = .left
        questionLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(questionLabel!)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionLabel!]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[v0]-10-[yes(30)]-14-[no(30)]-14-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionLabel!, "yes": yesView, "no": noView]))
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}


class QuestionRatingRow : UIView {
    var question: String? {
        didSet {
            questionLabel?.text = question
        }
    }
    var ratingChanged: ((Double) -> ())?
    var color: UIColor = Constants.colors.primaryDark {
        didSet {
            ratingView?.settings.filledColor = color
            ratingView?.settings.filledBorderColor = color
            ratingView?.settings.emptyColor = color.withAlphaComponent(0.3)
            ratingView?.settings.emptyBorderColor = color.withAlphaComponent(0.3)
            questionLabel?.textColor = color
        }
    }
    
    private var ratingView: CosmosView?
    private var questionLabel: UILabel?
    
    var rating: Float = 1.0 { didSet {
        ratingView?.rating = Double(rating)
    }}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(with question: String?, onChange: ((Double)->())?) {
        self.init(frame: CGRect.zero)
        self.question = question
        self.ratingChanged = onChange
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        ratingView = CosmosView()
        questionLabel = UILabel()
        guard let ratingView = ratingView, let questionLabel = questionLabel else { return }
        
        ratingView.backgroundColor = UIColor.clear
        ratingView.contentMode = UIViewContentMode.scaleAspectFit
        ratingView.settings.fillMode = .full
        ratingView.settings.totalStars = 3
        ratingView.settings.filledColor = color
        ratingView.settings.filledBorderColor = color
        ratingView.settings.emptyColor = color.withAlphaComponent(0.3)
        ratingView.settings.emptyBorderColor = color.withAlphaComponent(0.3)
        if AppDelegate.isIPhone5() {
            ratingView.settings.starSize = 24
            ratingView.settings.starMargin = 6
        } else {
            ratingView.settings.starSize = 28
            ratingView.settings.starMargin = 8
        }
        ratingView.rating = 2
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ratingView)
        
        ratingView.didFinishTouchingCosmos = { [weak self] rating in
            self?.ratingChanged?(rating)
        }
        
        // add constraints
        questionLabel.text = question
        if AppDelegate.isIPhone5() {
            questionLabel.font = UIFont.boldSystemFont(ofSize: 12)
        } else {
            questionLabel.font = UIFont.boldSystemFont(ofSize: 14)
        }
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .left
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(questionLabel)
        
        addVisualConstraint("V:|[v0]|", views: ["v0": questionLabel])
        addVisualConstraint("H:|-14-[v0]-10-[rating]-14-|", views: ["v0": questionLabel, "rating": ratingView])
        ratingView.centerYAnchor.constraint(equalTo: questionLabel.centerYAnchor).isActive = true
        ratingView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        if AppDelegate.isIPhone5() {
            ratingView.widthAnchor.constraint(equalToConstant: 84).isActive = true
        } else {
            ratingView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        }
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

enum FeedbackType : Int32 {
    case none = 0
    case no  = 1
    case meh = 2
    case yes = 3
}

class FeedbackRow : UIView {
    var feedbackChanged: ((FeedbackType) -> ())?
    let iconDiameter:CGFloat = 35.0
    var selectedColor: UIColor! = Constants.colors.primaryDark {
        didSet {
            resetColors()
        }
    }
    var unselectedColor: UIColor! = Constants.colors.primaryLight {
        didSet {
            resetColors()
        }
    }
    var selectedFeedback: FeedbackType = .meh {
        didSet {
            unselectAll()
            switch selectedFeedback {
            case .yes:
                yesLabel.textColor = selectedColor
                yesView.isSelected = true
            case .no:
                noLabel.textColor = selectedColor
                noView.isSelected = true
            case .meh:
                mehLabel.textColor = selectedColor
                mehView.isSelected = true
            case .none:
                break
            }
        }
    }
    
    private func unselectAll() {
        yesLabel.textColor = unselectedColor
        yesView.isSelected = false
        noLabel.textColor = unselectedColor
        noView.isSelected = false
        mehLabel.textColor = unselectedColor
        mehView.isSelected = false
    }
    
    private func resetColors() {
        yesLabel.textColor = unselectedColor
        yesView.selectedColor = selectedColor
        yesView.unselectedColor = unselectedColor
        noLabel.textColor = unselectedColor
        noView.selectedColor = selectedColor
        noView.unselectedColor = unselectedColor
        mehLabel.textColor = unselectedColor
        mehView.selectedColor = selectedColor
        mehView.unselectedColor = unselectedColor

    }
    
    private lazy var yesView: CircleCheckView = {
        let view = CircleCheckView(frame: CGRect(x: 0, y: 0, width: iconDiameter, height: iconDiameter))
        view.selectedColor = selectedColor
        view.unselectedColor = unselectedColor
        return view
    }()
    
    private lazy var yesLabel: UILabel = {
        let label = UILabel()
        label.text = "Yes!"
        label.font = UIFont.systemFont(ofSize: 16.0)
        return label
    }()
    
    private lazy var mehView: MehView = {
        let view = MehView(frame: CGRect(x: 0, y: 0, width: iconDiameter, height: iconDiameter))
        view.selectedColor = selectedColor
        view.unselectedColor = unselectedColor
        return view
    }()
    
    private lazy var mehLabel: UILabel = {
        let label = UILabel()
        label.text = "Not really"
        label.font = UIFont.systemFont(ofSize: 16.0)
        return label
    }()
    
    private lazy var noView: TimesView = {
        let view = TimesView(frame: CGRect(x: 0, y: 0, width: iconDiameter, height: iconDiameter))
        view.selectedColor = selectedColor
        view.unselectedColor = unselectedColor
        return view
    }()
    
    private lazy var noLabel: UILabel = {
        let label = UILabel()
        label.text = "No"
        label.font = UIFont.systemFont(ofSize: 16.0)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(onChange: ((FeedbackType)->())?) {
        self.init(frame: CGRect.zero)
        self.feedbackChanged = onChange
        setupViews()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        yesView.widthAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        yesView.heightAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        noView.widthAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        noView.heightAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        mehView.widthAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        mehView.heightAnchor.constraint(equalToConstant: iconDiameter).isActive = true
        
        let yesStackView = UIStackView(arrangedSubviews: [yesView, yesLabel])
        yesStackView.axis = .vertical
        yesStackView.distribution = .fillProportionally
        yesStackView.alignment = .center
        yesStackView.spacing = 5
        yesStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(yesStackView)
        
        let noStackView = UIStackView(arrangedSubviews: [noView, noLabel])
        noStackView.axis = .vertical
        noStackView.distribution = .fillProportionally
        noStackView.alignment = .center
        noStackView.spacing = 5
        noStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noStackView)
        
        let mehStackView = UIStackView(arrangedSubviews: [mehView, mehLabel])
        mehStackView.axis = .vertical
        mehStackView.distribution = .fillProportionally
        mehStackView.alignment = .center
        mehStackView.spacing = 5
        mehStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mehStackView)
        
        // add tap recognizers
        yesStackView.addTapGestureRecognizer { [weak self] in
            self?.selectedFeedback = .yes
            self?.feedbackChanged?(.yes)
        }
        mehStackView.addTapGestureRecognizer { [weak self] in
            self?.selectedFeedback = .meh
            self?.feedbackChanged?(.meh)
        }
        noStackView.addTapGestureRecognizer { [weak self] in
            self?.selectedFeedback = .no
            self?.feedbackChanged?(.no)
        }
        
        // add constraints
        addVisualConstraint("V:|-[stack(60)]-|", views: ["stack": yesStackView])
        addVisualConstraint("V:|-[stack(60)]-|", views: ["stack": noStackView])
        addVisualConstraint("V:|-[stack(60)]-|", views: ["stack": mehStackView])
        addVisualConstraint("H:|-14-[stack1]-30-[stack2]-30-[stack3]-14-|", views: ["stack1": yesStackView, "stack2": mehStackView, "stack3": noStackView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}


class CommentRow : UIView {
    var action: (() -> ())?
    var text: String? {
        didSet {
            textLabel.text = text
        }
    }
    var icon: String?
    var color: UIColor? = Constants.colors.primaryLight {
        didSet {
            textLabel.textColor = color
            iconView.iconColor = color
        }
    }
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 2
        label.textColor = color
        if AppDelegate.isIPhone5() {
            label.font = UIFont.italicSystemFont(ofSize: 12.0)
        } else {
            label.font = UIFont.italicSystemFont(ofSize: 14.0)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var iconView: IconView = {
        return IconView(icon: self.icon, iconColor: color)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(with text: String, icon: String, backgroundColor: UIColor, color: UIColor?, action: @escaping () -> ()) {
        self.init(frame: CGRect.zero)
        self.text = text
        self.color = color
        self.icon = icon
        self.action = action
        self.backgroundColor = backgroundColor
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupView() {
        addSubview(textLabel)
        addSubview(iconView)
        
        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": textLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5@999)-[icon]-(5@999)-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["icon": iconView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[v0]-14-[icon(25)]-14-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": textLabel, "icon": iconView]))
        
        translatesAutoresizingMaskIntoConstraints = false
        addTapGestureRecognizer {
            self.action!()
        }
    }
    
    func height() -> CGFloat {
        textLabel.sizeToFit()
        return textLabel.intrinsicContentSize.height
    }
}

class HeaderRow : UIView {
    
    var placeExplanation: String? {
        didSet {
            placeExplanationLabel.text = placeExplanation
        }
    }
    
    var placePersonalInformation: String? {
        didSet {
            placePersonalInformationLabel.text = placePersonalInformation
        }
    }
    
    var placeName : String? {
        didSet {
            placeNameLabel.text = placeName
        }
    }
    
    var placeAddress : String? {
        didSet {
            placeAddressLabel.text = placeAddress
        }
    }

    let placeNameLabel: UILabel = {
        let label = UILabel()
        label.text = "place name"
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.textColor = Constants.colors.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let placeAddressLabel: UILabel = {
        let label = UILabel()
        label.text = "place address"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.superLightGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let placePersonalInformationLabel: UILabel = {
        let label = UILabel()
        label.text = "place personal information"
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = Constants.colors.white
        label.textAlignment = .center
        label.numberOfLines = 0 // as many lines as necessary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let placeExplanationLabel: UILabel = {
        let label = UILabel()
        label.text = "place explanation"
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textColor = Constants.colors.white
        label.textAlignment = .center
        label.numberOfLines = 0 // as many lines as necessary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupView() {
        addSubview(placeNameLabel)
        addSubview(placeAddressLabel)
        addSubview(placePersonalInformationLabel)
        addSubview(placeExplanationLabel)

        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[title(30)][address]-15-[info]-15-[expl]", options: NSLayoutFormatOptions(), metrics: nil, views: ["title": placeNameLabel, "address": placeAddressLabel, "info": placePersonalInformationLabel, "expl": placeExplanationLabel]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[title]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["title": placeNameLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[address]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["address": placeAddressLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[info]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["info": placePersonalInformationLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[expl]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["expl": placeExplanationLabel]))

        translatesAutoresizingMaskIntoConstraints = false
    }
}

class FooterRow : UIView {
    var action: (() -> ())?
    var text: String? {
        didSet {
            label?.text = text
        }
    }
    var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(with text: String, backgroundColor: UIColor, action: @escaping () -> ()) {
        self.init(frame: CGRect.zero)
        self.text = text
        self.action = action
        self.backgroundColor = backgroundColor.withAlphaComponent(0.7)
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupView() {
        label = UILabel()
        guard let label = label else { return }
        label.text = text
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = Constants.colors.white
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": label]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": label]))
        
        translatesAutoresizingMaskIntoConstraints = false
        addTapGestureRecognizer {
            self.action!()
        }
    }
}

