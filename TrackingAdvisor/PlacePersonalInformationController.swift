//
//  PlacePersonalInformationController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/22/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit


class PlacePersonalInformationController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LargePersonalInformationCellDelegate, DataStoreUpdateProtocol, FooterDoneDelegate {
    
    func goBack() {
        guard let controllers = navigationController?.viewControllers else { return }
        let count = controllers.count
        UserUpdateHandler.sendReviewUpdate(reviews: updatedReviews)
        if count == 2 {
            // get the previous place detail controller
            if let vc = controllers[0] as? OneTimelinePlaceDetailViewController {
                vc.vid = visit?.id
                navigationController?.popToViewController(vc, animated: true)
            }
        } else if count == 1 {
            // return to the timeline
            presentingViewController?.dismiss(animated: true)
        }
    }
    
    @objc func done(_ sender: UIBarButtonItem) {
        // perform save action to the server
        UserUpdateHandler.sendReviewUpdate(reviews: updatedReviews)
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        goBack()
    }
    
    var collectionView: UICollectionView!
    lazy var headerView: HeaderPlaceDetail = {
        return HeaderPlaceDetail()
    }()
    
    let cellId = "CellId"
    let headerCellId = "HeaderCellId"
    let footerCellId = "FooterCellId"
    var color = Constants.colors.orange
    
    var visit: Visit? {
        didSet {
            guard let visit = visit, let place = visit.place else { return }
            headerView.placeName = place.name
            headerView.placeAddress = place.formatAddressString()
            headerView.placeTimes = visit.getTimesPhrase()
            
            color = place.getPlaceColor()
            headerView.backgroundColor = color
            
            personalInformation = place.getPersonalInformation()
            pics = personalInformation!.keys.sorted(by: { $0 < $1 })
        }
    }
    var personalInformation: [String : [PersonalInformation]]?
    var pics: [String]?
    var updatedReviews: [String:Int32] = [:]  // [reviewId : Answer]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        DataStoreService.shared.delegate = self
        
        setupNavBarButtons()
        updatedReviews.removeAll()
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
        collectionView.register(FooterDoneCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerCellId)

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
        
        if let pi = personalInformation, let pics = pics {
            let category = pics[section]
            if let count = pi[category]?.count {
                return count
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LargePersonalInformationCell
        guard let pi = personalInformation, let pics = pics else { return cell }
        let category = pics[indexPath.section]
        cell.parent = self
        cell.personalInformation = pi[category]?[indexPath.item]
        cell.indexPath = indexPath
        cell.color = color
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 1 - instanciate a new cell
        let cell = LargePersonalInformationCell()
        guard let pi = personalInformation, let pics = pics else {
            return CGSize(width: view.frame.width, height: 200)
        }
        
        let category = pics[indexPath.section]
        cell.personalInformation = pi[category]?[indexPath.item]
        
        // 3 - get the height
        let height = cell.height()
        
        // 4 - return the correct size
        return CGSize(width: view.frame.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! HeaderLargePersonalInformationCell
            
            guard let pics = pics else { return headerView }
            let picid = pics[indexPath.section]
            if let category = PersonalInformationCategory.getPersonalInformationCategory(with: picid) {
                headerView.title = category.name
                headerView.subtitle = category.detail
                headerView.icon = category.icon
            }
            if let place = visit?.place {
                headerView.color = place.getPlaceColor()
            }
            
            return headerView
        } else if kind == UICollectionElementKindSectionFooter {
            let footerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerCellId, for: indexPath) as! FooterDoneCell
            footerCell.delegate = self
            footerCell.color = color
            footerCell.text = "Done"
            return footerCell
        } else {
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // From https://stackoverflow.com/questions/33402596/how-can-i-dynamically-resize-a-header-view-in-a-uicollectionview
        
        // 1 - instanciate a new header
        let headerView = HeaderLargePersonalInformationCell()
        guard let pics = pics else {
            return CGSize(width: collectionView.frame.width, height: 100)
        }
        
        let picid = pics[section]
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let count = pics?.count, section == count-1 {
            return CGSize(width: collectionView.frame.width, height: 100)
        }
        return CGSize(width: collectionView.frame.width, height: 0)
    }
    
    // MARK: - LargePersonalInformationCellDelegate method
    func wasPersonalInfromationCellChanged(at indexPath: IndexPath?) {
        // update the layout of the cells
        if indexPath != nil {
            UIView.performWithoutAnimation {
                collectionView.reloadItems(at: [indexPath!])
            }
        }
    }
    
    // MARK: - DataStoreUpdateProtocol method
    func dataStoreDidUpdateReviewAnswer(for reviewId: String?, with answer: Int32) {
        if let reviewId = reviewId {
            updatedReviews[reviewId] = answer
            print("updated review \(reviewId) with \(answer) -- \(updatedReviews.count)")
        }
    }
    
    // MARK: - FooterDoneDelegate method
    func didPressDone() {
        goBack()
    }
}

protocol LargePersonalInformationCellDelegate {
    func wasPersonalInfromationCellChanged(at indexPath: IndexPath?)
}

fileprivate class LargePersonalInformationCell: UICollectionViewCell {
    var parent: PlacePersonalInformationController?
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
        let row = CommentRow(with: "It would be great if you could tell us the correct personal information", icon: "chevron-right", backgroundColor: UIColor.clear, color: Constants.colors.superLightGray) {
            print("tapped on personal information edit")
            // TODO: - present PlacePersonalInformationEditController
        }
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
            self?.delegate?.wasPersonalInfromationCellChanged(at: self?.indexPath)
        })
        row.selectedColor = color
        row.unselectedColor = Constants.colors.superLightGray
        return row
    }()
    var questionExplanationViewHeight: NSLayoutConstraint?
    lazy var questionExplanationEditView: CommentRow = {
        let row = CommentRow(with: "It would be great if you could tell us how we can improve the explanation", icon: "chevron-right", backgroundColor: UIColor.clear, color: Constants.colors.superLightGray) {
            print("tapped on explanation edit")
            let viewController = ExplanationFeedbackViewController()            
            self.parent?.navigationController?.pushViewController(viewController, animated: true)
        }
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
        switch answer {
        case .yes:
            personalInformationEditHeight?.constant = 0
            questionExplanationViewHeight?.constant = 40
            questionPrivacyViewHeight?.constant = 40
        case .no:
            personalInformationEditHeight?.constant = 0
            questionExplanationViewHeight?.constant = 0
            questionPrivacyViewHeight?.constant = 0
            questionExplanationEditViewHeight?.constant = 0
        case .none:
            personalInformationEditHeight?.constant = 0
            questionExplanationViewHeight?.constant = 0
            questionPrivacyViewHeight?.constant = 0
            questionExplanationEditViewHeight?.constant = 0
        }
    }
    
    private func constraintsUpdateExplanation(_ answer: ReviewAnswer) {
        switch answer {
        case .yes, .none:
            questionExplanationEditViewHeight?.constant = 0
        case .no:
            questionExplanationEditViewHeight?.constant = 40
        }
    }
    
    func height() -> CGFloat {
        let headerHeight: CGFloat = 14.0 + 40 + 8.0 + 50 + 16.0
        var questionsHeight: CGFloat = 40.0
        if questionPersonalInformationView.selected == .no {
            questionsHeight += 0.0
        } else if questionPersonalInformationView.selected == .yes {
            questionsHeight += 40.0 + 40.0
            if questionExplanationView.selected == .no {
                questionsHeight += 40.0
            }
        }
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
    var color: UIColor = Constants.colors.orange {
        didSet {
            self.iconView.iconColor = color
            self.instructionsLabel.textColor = color
        }
    }
    var icon: String = "user-circle" {
        didSet {
            self.iconView.icon = icon
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
    
    lazy var iconView: IconView = {
        return IconView(icon: icon, iconColor: Constants.colors.primaryLight)
    }()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel,subtitleLabel,instructionsLabel])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        addSubview(iconView)
        
        // add constraints
        addVisualConstraint("V:|-20-[stack]-|", views: ["stack": stackView])
        addVisualConstraint("V:|-20-[icon(30)]", views: ["icon": iconView])
        addVisualConstraint("H:|-14-[icon(30)]-[stack]-14-|", views: ["icon": iconView, "stack": stackView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 14 + titleLabel.bounds.height + subtitleLabel.bounds.height + instructionsLabel.bounds.height + 14
    }
}

protocol FooterDoneDelegate {
    func didPressDone()
}

class FooterDoneCell: UICollectionViewCell {
    var delegate: FooterDoneDelegate?
    var color: UIColor? {
        didSet {
            doneLabel.backgroundColor = color
            doneLabel.textColor = .white
        }
    }
    var text: String? {
        didSet {
            doneLabel.text = text
        }
    }
    
    private lazy var doneLabel: UILabel = {
        let l = UILabel()
        l.layer.cornerRadius = 5.0
        l.layer.masksToBounds = true
        l.text = "Done"
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        l.textColor = color
        l.backgroundColor = color
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        addSubview(doneLabel)
        addTapGestureRecognizer { [weak self] in
            self?.doneLabel.alpha = 0.7
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.doneLabel.alpha = 1
            }
            self?.delegate?.didPressDone()
        }
        
        // setup constraints
        addVisualConstraint("H:|-14-[label]-14-|", views: ["label": doneLabel])
        addVisualConstraint("V:|-20-[label]-20-|", views: ["label": doneLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func height() -> CGFloat {
        return 100
    }
}
