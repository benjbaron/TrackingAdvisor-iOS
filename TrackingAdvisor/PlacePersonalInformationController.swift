//
//  PlacePersonalInformationController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/22/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation

class PlacePersonalInformationController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LargePersonalInformationCellDelegate {
    
    @objc func done(_ sender: UIBarButtonItem) {
        // TODO: - perform save action
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        guard let controllers = navigationController?.viewControllers else { return }
        let count = controllers.count
        if count == 2 {
            // get the previous place detail controller
            if let vc = controllers[0] as? OneTimelinePlaceDetailViewController {
                vc.visit = visit
                navigationController?.popToViewController(vc, animated: true)
            }
        } else if count == 1 {
            // return to the timeline
            presentingViewController?.dismiss(animated: true)
        }
    }
    
    var collectionView: UICollectionView!
    lazy var headerView: HeaderPlaceDetail = {
        return HeaderPlaceDetail()
    }()
    
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    var color = Constants.colors.orange
    
    var visit: Visit? {
        didSet {
            guard let visit = visit, let place = visit.place else { return }
            headerView.placeAddress = place.address
            headerView.placeName = place.name
            headerView.placeCity = place.city
            headerView.placeTimes = visit.getTimesPhrase()
            color = place.getPlaceColor()
            headerView.backgroundColor = color
            personalInformation = place.getPersonalInformation()
        }
    }
    var personalInformation: [String: [PersonalInformation]]?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        setupNavBarButtons()
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(LargePersonalInformationCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(HeaderLargePersonalInformationCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerCellId)
        
        setupViews()
    }
    
    func setupNavBarButtons() {
//        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
//        doneButton.tintColor = Constants.colors.superLightGray
//        self.navigationItem.rightBarButtonItem = doneButton
        
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "angle-left")!.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = Constants.colors.superLightGray
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func setupViews() {
        self.view.addSubview(headerView)
        self.view.addVisualConstraint("H:|[header]|", views: ["header" : headerView])
        self.view.addVisualConstraint("V:|[header]", views: ["header" : headerView])
        
        collectionView.backgroundColor = UIColor.white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)

        self.view.addVisualConstraint("H:|[collection]|", views: ["collection" : collectionView])
        self.view.addVisualConstraint("V:[header][collection]|", views: ["header": headerView, "collection" : collectionView])
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let count = personalInformation?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let pi = personalInformation {
            let category = Array(pi.keys)[section]
            if let count = pi[category]?.count {
                return count
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LargePersonalInformationCell
        guard let pi = personalInformation else { return cell }
        let category = Array(pi.keys)[indexPath.section]
        cell.personalInformation = pi[category]?[indexPath.item]
        cell.indexPath = indexPath
        cell.color = color
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 1 - instanciate a new cell
        let cell = LargePersonalInformationCell()
        guard let pi = personalInformation else {
            return CGSize(width: view.frame.width, height: 200)
        }
        let category = Array(pi.keys)[indexPath.section]
        cell.personalInformation = pi[category]?[indexPath.item]
        
        // 3 - get the height
        let height = cell.height()
        print("height for pi \(category): \(height)")
        
        // 4 - return the correct size
        return CGSize(width: view.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! HeaderLargePersonalInformationCell
            
            guard let pi = personalInformation else { return headerView }
            let picid = Array(pi.keys)[indexPath.section]
            let category = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
            
            headerView.title = category?.name
            headerView.subtitle = category?.detail
            return headerView
        } else {
            assert(false, "Unexpected element kind")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // From https://stackoverflow.com/questions/33402596/how-can-i-dynamically-resize-a-header-view-in-a-uicollectionview
        
        // 1 - instanciate a new header
        let headerView = HeaderLargePersonalInformationCell()
        guard let pi = personalInformation else { return CGSize(width: collectionView.frame.width, height: 100) }
        
        let picid = Array(pi.keys)[section]
        let category = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
        headerView.title = category?.name
        
        // 2 - set the width through a constraint and lay out the view
        headerView.addConstraint(NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: collectionView.frame.width))
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        // 3 - get the height
        let height = headerView.height()
        
        // 4 - return the correct size
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    // MARK: - LargePersonalInformationCellDelegate method
    func wasPersonalInfromationCellChanged(at indexPath: IndexPath?) {
        print("Personal information cell was changed")
        // update the layout of the cells
//        collectionView.reloadData()
//        collectionView.performBatchUpdates(nil, completion: nil)
        if indexPath != nil {
            UIView.performWithoutAnimation {
                collectionView.reloadItems(at: [indexPath!])
            }
        }
    }
}

protocol LargePersonalInformationCellDelegate {
    func wasPersonalInfromationCellChanged(at indexPath: IndexPath?)
}

fileprivate class LargePersonalInformationCell: UICollectionViewCell {
    var delegate: LargePersonalInformationCellDelegate?
    var indexPath: IndexPath?
    var personalInformation: PersonalInformation? {
        didSet {
            if let name = personalInformation?.name {
                titleLabel.text = name
            }
            if let explanation = personalInformation?.explanation {
                explanationLabel.text = explanation
            }
            
            if let review = personalInformation?.getReview(of: .personalInformation) {
                questionPersonalInformationView.question = review.question
                questionPersonalInformationView.selected = review.answer
                constraintsUpdatePersonalInformation(review.answer)
            }
            
            if let review = personalInformation?.getReview(of: .explanation) {
                questionExplanationView.question = review.question
                questionExplanationView.selected = review.answer
                constraintsUpdateExplanation(review.answer)
            }
            
            if let review = personalInformation?.getReview(of: .privacy) {
                questionPrivacyView.question = review.question
                questionPrivacyView.selected = review.answer
            }
        }
    }
    var color: UIColor? = Constants.colors.lightOrange {
        didSet {
            bgView.backgroundColor = color?.withAlphaComponent(0.3)
            headerView.backgroundColor = color
            questionPersonalInformationView.selectedColor = color
            questionExplanationView.selectedColor = color
            questionPrivacyView.selectedColor = color
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5.0
        v.backgroundColor = color
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 2
        label.textColor = .white
        label.textAlignment = .center
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let explanationLabel: UILabel = {
        let label = UILabel()
        label.text = "Explanations"
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 3
        label.textAlignment = .center
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var questionPersonalInformationView: QuestionRow = {
        let row = QuestionRow(with: "question", yesAction: { [weak self] in
            if let review = self?.personalInformation?.getReview(of: .personalInformation) {
                review.answer = .yes
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .yes)
            }
            self?.constraintsUpdatePersonalInformation(.yes)
            self?.delegate?.wasPersonalInfromationCellChanged(at: self?.indexPath)
        }, noAction: { [weak self] in
            if let review = self?.personalInformation?.getReview(of: .personalInformation) {
                review.answer = .no
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .no)
            }
            if let review = self?.personalInformation?.getReview(of: .explanation) {
                review.answer = .none
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .none)
            }
            if let review = self?.personalInformation?.getReview(of: .privacy) {
                review.answer = .none
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .none)
            }
            self?.constraintsUpdatePersonalInformation(.no)
            self?.questionExplanationView.selected = .none
            self?.questionPrivacyView.selected = .none
            self?.delegate?.wasPersonalInfromationCellChanged(at: self?.indexPath)
        })
        row.selectedColor = color
        row.unselectedColor = Constants.colors.superLightGray
        
        return row
    }()
    
    let personalInformationEditView: CommentRow = {
        let row = CommentRow(with: "It would be great if you could tell us the correct personal information", icon: "chevron-right", backgroundColor: UIColor.clear) {
            print("tapped on personal information edit")
            // TODO: - present PlacePersonalInformationEditController
        }
        row.color = Constants.colors.superLightGray
        return row
    }()
    var personalInformationEditHeight: NSLayoutConstraint?
    
    lazy var questionExplanationView: QuestionRow = {
        
        let row = QuestionRow(with: "question", yesAction: { [weak self] in
            if let review = self?.personalInformation?.getReview(of: .explanation) {
                review.answer = .yes
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .yes)
                print("answered yes to review \(review)")
            }
            
            self?.constraintsUpdateExplanation(.yes)
            self?.delegate?.wasPersonalInfromationCellChanged(at: self?.indexPath)
        }, noAction: { [weak self] in
            if let review = self?.personalInformation?.getReview(of: .explanation) {
                review.answer = .no
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .no)
                print("answered no to review \(review)")
            }
            self?.constraintsUpdateExplanation(.no)
            self?.delegate?.wasPersonalInfromationCellChanged(at: self?.indexPath)
        })
        row.selectedColor = color
        row.unselectedColor = Constants.colors.superLightGray
        return row
    }()
    var questionExplanationViewHeight: NSLayoutConstraint?
    let questionExplanationEditView: CommentRow = {
        let row = CommentRow(with: "It would be great if you could tell us how we can improve the explanation", icon: "chevron-right", backgroundColor: UIColor.clear) {
            print("tapped on explanation edit")
            // TODO: - present PlacePersonalInformationExplanationEditController
        }
        row.color = Constants.colors.superLightGray
        return row
    }()
    var questionExplanationEditViewHeight: NSLayoutConstraint?

    lazy var questionPrivacyView: QuestionRow = {
        let row = QuestionRow(with: "question", yesAction: { [weak self] in
            if let review = self?.personalInformation?.getReview(of: .privacy) {
                review.answer = .yes
                DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .yes)
            }
            self?.delegate?.wasPersonalInfromationCellChanged(at: self?.indexPath)
            }, noAction: { [weak self] in
                if let review = self?.personalInformation?.getReview(of: .privacy) {
                    review.answer = .no
                    DataStoreService.shared.saveReviewAnswer(with: review.id!, answer: .no)
                }
            self?.delegate?.wasPersonalInfromationCellChanged(at: self?.indexPath)
        })
        row.selectedColor = color
        row.unselectedColor = Constants.colors.superLightGray
        return row
    }()
    var questionPrivacyViewHeight: NSLayoutConstraint?
    
    func setupViews() {
        contentView.addSubview(bgView)
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(explanationLabel)
        headerView.addVisualConstraint("H:|-[v0]-|", views: ["v0": titleLabel])
        headerView.addVisualConstraint("H:|-[v0]-|", views: ["v0": explanationLabel])
        headerView.addVisualConstraint("V:|-14-[v0]-[v1]-|", views: ["v0": titleLabel, "v1": explanationLabel])
        
        bgView.addSubview(headerView)
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": headerView])
        
        bgView.addSubview(questionPersonalInformationView)
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": questionPersonalInformationView])
        
        bgView.addSubview(personalInformationEditView)
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": personalInformationEditView])
        
        bgView.addSubview(questionExplanationView)
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": questionExplanationView])
        
        bgView.addSubview(questionExplanationEditView)
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": questionExplanationEditView])
        
        bgView.addSubview(questionPrivacyView)
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": questionPrivacyView])
        
        bgView.addVisualConstraint("V:|[v0(120)]", views: ["v0": headerView])
        bgView.addVisualConstraint("V:[v1(40)][v2][v3][v4][v5]-|", views: ["v1": questionPersonalInformationView, "v2": personalInformationEditView, "v3": questionExplanationView, "v4": questionExplanationEditView, "v5": questionPrivacyView])
        
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": bgView])
        addVisualConstraint("V:|-[v0]-|", views: ["v0": bgView])
        
        bgView.clipsToBounds = false
        bgView.layer.masksToBounds = true
        
        // add height constraints
        personalInformationEditHeight = NSLayoutConstraint(item: personalInformationEditView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        personalInformationEditHeight?.isActive = true

        questionExplanationViewHeight = NSLayoutConstraint(item: questionExplanationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        questionExplanationViewHeight?.isActive = true

        questionExplanationEditViewHeight = NSLayoutConstraint(item: questionExplanationEditView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        questionExplanationEditViewHeight?.isActive = true

        questionPrivacyViewHeight = NSLayoutConstraint(item: questionPrivacyView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        questionPrivacyViewHeight?.isActive = true
    }
    
    private func constraintsUpdatePersonalInformation(_ answer: ReviewAnswer) {
        if answer == .yes {
            personalInformationEditHeight?.constant = 0
            questionExplanationViewHeight?.constant = 40
            questionPrivacyViewHeight?.constant = 40
        } else if answer == .no {
            personalInformationEditHeight?.constant = 40
            questionExplanationViewHeight?.constant = 0
            questionPrivacyViewHeight?.constant = 0
            questionExplanationEditViewHeight?.constant = 0
        } else {
            personalInformationEditHeight?.constant = 0
            questionExplanationViewHeight?.constant = 0
            questionPrivacyViewHeight?.constant = 0
            questionExplanationEditViewHeight?.constant = 0
        }
    }
    
    private func constraintsUpdateExplanation(_ answer: ReviewAnswer) {
        if answer == .yes {
            questionExplanationEditViewHeight?.constant = 0
        } else if answer == .no {
            questionExplanationEditViewHeight?.constant = 40
        } else {
            questionExplanationEditViewHeight?.constant = 0
        }
    }
    
    func height() -> CGFloat {
        let headerHeight: CGFloat = 14.0 + 40 + 8.0 + 50 + 16.0
        var questionsHeight: CGFloat = 40.0
        if questionPersonalInformationView.selected == .no {
            questionsHeight += 40.0
        } else if questionPersonalInformationView.selected == .yes {
            questionsHeight += 40.0 + 40.0
            if questionExplanationView.selected == .no {
                questionsHeight += 40.0
            }
        }
        print("headerHeight: \(headerHeight), questionsHeight: \(questionsHeight)")
        return 8.0 + headerHeight + 8.0 + questionsHeight + 8.0
    }
}

fileprivate class HeaderLargePersonalInformationCell : UICollectionViewCell {
    var title: String? {
        didSet {
            self.titleLabel.text = title
        }
    }
    var subtitle: String? {
        didSet {
            self.subtitleLabel.text = subtitle
        }
    }
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
        label.textColor = Constants.colors.black
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Please give us feedback on the personal information inferences we made below."
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textColor = Constants.colors.primaryLight
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(instructionsLabel)
        
        // add constraints
        addVisualConstraint("V:|-20-[title][subtitle][instructions]-|", views: ["title": titleLabel, "subtitle": subtitleLabel,"instructions": instructionsLabel])
        addVisualConstraint("H:|-14-[title]-14-|", views: ["title": titleLabel])
        addVisualConstraint("H:|-14-[subtitle]-14-|", views: ["subtitle": subtitleLabel])
        addVisualConstraint("H:|-14-[instructions]-14-|", views: ["instructions": instructionsLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 14 + titleLabel.bounds.height + instructionsLabel.bounds.height + 14
    }
}
