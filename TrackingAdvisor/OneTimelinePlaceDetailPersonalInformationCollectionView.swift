//
//  PersonalInformationCollectionView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/16/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

protocol PersonalInformationCategoryCellDelegate {
    func reviewPersonalInformation(cat: String, personalInformation: PersonalInformation, answer: FeedbackType)
}

class PersonalInformationCategoryCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PersonalInformationCellDelegate {
    
    var delegate: PersonalInformationCategoryCellDelegate?
    var personalInformationCategory: PersonalInformationCategory? {
        didSet {
            if let name = personalInformationCategory?.name {
                nameLabel.text = name
            }
            if let icon = personalInformationCategory?.icon {
                iconView.icon = icon
            }
            infoCollectionView.reloadData()
        }
    }
    var personalInformation: [PersonalInformation]? = [] { didSet {
        personalInformation = personalInformation?.sorted(by: { $0.name ?? "" < $1.name ?? "" })
        infoCollectionView.reloadData()
    }}
    var color: UIColor? {
        didSet { iconView.iconColor = color }
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
    
    func setupViews() {
        backgroundColor = UIColor.clear
        
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        flowLayout.xCellFrameScaling = 0.85
        infoCollectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewLayout())
        infoCollectionView.dataSource = self
        infoCollectionView.delegate = self
        infoCollectionView.backgroundColor = .white
        infoCollectionView.showsHorizontalScrollIndicator = false
        infoCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(infoCollectionView)
        addSubview(dividerLineView)
        addSubview(nameLabel)
        addSubview(iconView)
        
        // register cell type
        infoCollectionView.register(PersonalInformationCell.self, forCellWithReuseIdentifier: cellId)
        
        addVisualConstraint("H:|-14-[icon(20)]-[text]-14-|", views: ["icon": iconView, "text": nameLabel])
    
        iconView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": dividerLineView])
        addVisualConstraint("H:|[v0]|", views: ["v0": infoCollectionView])
        addVisualConstraint("V:|[nameLabel(30)][v0][v1(0.5)]|", views: ["v0": infoCollectionView, "v1": dividerLineView, "nameLabel": nameLabel])
        
        infoCollectionView.layoutIfNeeded()
        
        // Setup collection view bounds
        let collectionViewFrame = infoCollectionView.frame
        flowLayout.cellWidth = floor(collectionViewFrame.width * flowLayout.xCellFrameScaling)
        flowLayout.cellHeight = floor(collectionViewFrame.height * flowLayout.yCellFrameScaling)
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - flowLayout.cellHeight) / 2.0)
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationCell
        cell.color = color!
        cell.personalInformation = personalInformation?[indexPath.item]
        cell.showCategory = false
        cell.indexPath = indexPath
        cell.delegate = self
        return cell
    }
    
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: FeedbackType, indexPath: IndexPath?) {
        guard let pi = personalInformation, let cat = personalInformation?.category else { return }
        delegate?.reviewPersonalInformation(cat: cat, personalInformation: pi, answer: answer)
    }
}


protocol PersonalInformationCellDelegate {
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: FeedbackType, indexPath: IndexPath?)
}

class PersonalInformationCell: UICollectionViewCell {
    var indexPath: IndexPath?
    var delegate: PersonalInformationCellDelegate?
    var personalInformation: PersonalInformation? {
        didSet {
            if let name = personalInformation?.name {
                nameLabel.text = name
                layoutIfNeeded()
            }
            if let picid = personalInformation?.category {
                let pic = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
                if let iconName = pic?.icon {
                    iconView.icon = iconName
                }
                if let categoryName = pic?.name {
                    categoryLabel.text = categoryName
                }
            }
            if let rating = personalInformation?.rating {
                if let feedback = FeedbackType(rawValue: rating) {
                    self.feedback = feedback
                }
            }
        }
    }
    var feedback: FeedbackType = .none { didSet {
        feedbackView.selectedFeedback = feedback
    }}
    var color: UIColor = Constants.colors.orange {
        didSet {
            bgView.backgroundColor = color.withAlphaComponent(0.3)
            nameLabel.textColor = color
            categoryLabel.textColor = color
            feedbackView.color = color
            iconView.iconColor = color
        }
    }
    var showCategory: Bool = false {
        didSet {
            categoryConstraint.constant = showCategory ? 30.0 : 0.0
        }
    }
    
    var categoryConstraint: NSLayoutConstraint!
    
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
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = color.withAlphaComponent(0.3)
        return v
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.textColor = color
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Category"
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.textColor = color
        label.numberOfLines = 1
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var iconView: IconView = {
        return IconView(icon: "user-circle", iconColor: Constants.colors.primaryLight)
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Is this personal information relevant?"
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var feedbackView: FeedbackRow = {
        let row = FeedbackRow(onChange: { [weak self] feedback in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.didPressPersonalInformationReview(personalInformation: strongSelf.personalInformation, answer: feedback, indexPath: strongSelf.indexPath)
        })
        row.selectedFeedback = feedback
        row.color = color
        return row
    }()
    
    func setupViews() {
        addSubview(bgView)
        bgView.addSubview(nameLabel)
        bgView.addSubview(dividerLineView)
        bgView.addSubview(descriptionLabel)
        bgView.addSubview(feedbackView)
        
        let stackView = UIStackView(arrangedSubviews: [iconView, categoryLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        bgView.addSubview(stackView)
        
        iconView.widthAnchor.constraint(equalToConstant: 15.0).isActive = true
        
        categoryConstraint = NSLayoutConstraint(item: stackView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30.0)
        stackView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor).isActive = true
        
        bgView.addConstraint(categoryConstraint)
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": nameLabel])
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": dividerLineView])
        addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": descriptionLabel])
        addVisualConstraint("V:|-10-[cat][v0]-[line(0.5)]-[v1]", views: ["cat": stackView, "v0": nameLabel, "line": dividerLineView, "v1": descriptionLabel])
        addVisualConstraint("V:[v1]-|", views: ["v1": feedbackView])
        
        feedbackView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor).isActive = true
        
        addVisualConstraint("H:|[v0]|", views: ["v0": bgView])
        addVisualConstraint("V:|-[v0]-14-|", views: ["v0": bgView])
    }
}
