//
//  PlacePersonalInformationController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/22/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation

class PlacePersonalInformationController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LargePersonalInformationCellDelegate {
    
    @objc func save(_ sender: UIBarButtonItem) {
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
    var personalInformation: [PersonalInformationCategory: [PersonalInformation]]?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        setupNavBarButtons()
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
        let editButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        editButton.tintColor = Constants.colors.superLightGray
        self.navigationItem.rightBarButtonItem = editButton
        
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
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.layoutIfNeeded()
        if let cell = collectionView.cellForItem(at: indexPath) as? LargePersonalInformationCell {
            let height = cell.height()
            print("height = \(height)")
            return CGSize(width: view.frame.width, height: height)
        }
        
        return CGSize(width: view.frame.width, height: 270)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerCellId, for: indexPath) as! HeaderLargePersonalInformationCell
            guard let pi = personalInformation else { return headerView }
            let category = Array(pi.keys)[indexPath.section]
            headerView.title = category.name
            headerView.subtitle = category.desc
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
        
        let category = Array(pi.keys)[section]
        headerView.title = category.name
        
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
    func wasPersonalInfromationCellChanged() {
        print("Personal information cell was changed")
        // update the layout of the cells
        collectionView.performBatchUpdates(nil, completion: nil)
    }
}

protocol LargePersonalInformationCellDelegate {
    func wasPersonalInfromationCellChanged()
}

fileprivate class LargePersonalInformationCell: UICollectionViewCell {
    var delegate: LargePersonalInformationCellDelegate?
    var personalInformation: PersonalInformation? {
        didSet {
            if let name = personalInformation?.name {
                titleLabel.text = name
            }
            if let explanation = personalInformation?.explanation {
                explanationLabel.text = explanation
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5.0
        v.layer.shadowRadius = 1.0
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 2, height: 2)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = Constants.colors.lightOrange  // TODO: - Associate with the color of the place / visit
        return v
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 2
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let explanationLabel: UILabel = {
        let label = UILabel()
        label.text = "Explanations"
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var questionPersonalInformationView: QuestionRow = {
        let row = QuestionRow(with: "Is the information correct?", yesAction: { [weak self] in
            print("yes")
            self?.personalInformationEditHeight?.constant = 0
            self?.questionExplanationViewHeight?.constant = 40
            self?.questionPrivacyViewHeight?.constant = 40
            self?.delegate?.wasPersonalInfromationCellChanged()
        }, noAction: { [weak self] in
            print("no")
            self?.personalInformationEditHeight?.constant = 40
            self?.questionExplanationViewHeight?.constant = 0
            self?.questionPrivacyViewHeight?.constant = 0
            self?.questionExplanationEditViewHeight?.constant = 0
            self?.questionExplanationView.selected = .none
            self?.questionPrivacyView.selected = .none
            self?.delegate?.wasPersonalInfromationCellChanged()
        })
        row.selectedColor = Constants.colors.orange
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
        let row = QuestionRow(with: "Is the explanation informative?", yesAction: { [weak self] in
            print("yes")
            self?.questionExplanationEditViewHeight?.constant = 0
            self?.delegate?.wasPersonalInfromationCellChanged()
        }, noAction: { [weak self] in
            print("no")
            self?.questionExplanationEditViewHeight?.constant = 40
            self?.delegate?.wasPersonalInfromationCellChanged()
        })
        row.selectedColor = Constants.colors.orange
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
        let row = QuestionRow(with: "Is the inferred information sensitive to you?", yesAction: { [weak self] in
            print("yes")
            self?.delegate?.wasPersonalInfromationCellChanged()
            }, noAction: { [weak self] in
            print("yes")
            self?.delegate?.wasPersonalInfromationCellChanged()
        })
        row.selectedColor = Constants.colors.orange
        row.unselectedColor = Constants.colors.superLightGray
        return row
    }()
    var questionPrivacyViewHeight: NSLayoutConstraint?
    
    func setupViews() {
        contentView.addSubview(bgView)
        
        let view = UIView()
        view.backgroundColor = Constants.colors.orange
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        view.addSubview(explanationLabel)
        view.addVisualConstraint("H:|-[v0]-|", views: ["v0": titleLabel])
        view.addVisualConstraint("H:|-[v0]-|", views: ["v0": explanationLabel])
        view.addVisualConstraint("V:|-14-[v0]-[v1]-|", views: ["v0": titleLabel, "v1": explanationLabel])
        
        bgView.addSubview(view)
        bgView.addVisualConstraint("H:|[v0]|", views: ["v0": view])
        
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
        
        bgView.addVisualConstraint("V:|[v0]-[v1(40)][v2][v3][v4][v5]-|", views: ["v0": view, "v1": questionPersonalInformationView, "v2": personalInformationEditView, "v3": questionExplanationView, "v4": questionExplanationEditView, "v5": questionPrivacyView])
        
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
    
    func height() -> CGFloat {
        let headerHeight: CGFloat = 14.0 + titleLabel.bounds.height + 8 + explanationLabel.bounds.height + 8.0
        var questionsHeight: CGFloat = 40.0
        if questionPersonalInformationView.selected == .no {
            questionsHeight += 40.0
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
