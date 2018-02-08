//
//  InterestCell.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/16/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

protocol PersonalInformationCategoryCellDelegate {
    func addPersonalInformation(cat: String)
    func reviewPersonalInformation(cat: String, personalInformation: PersonalInformation, answer: ReviewAnswer)
}

class PersonalInformationCategoryCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PersonalInformationCellDelegate {
    
    var delegate: PersonalInformationCategoryCellDelegate?
    var personalInformationCategory: PersonalInformationCategory? {
        didSet {
            if let name = personalInformationCategory?.name {
                nameLabel.text = name
            }
            infoCollectionView.reloadData()
        }
    }
    var personalInformation: [PersonalInformation]? = []
    var color: UIColor?
    
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
    
    let infoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    func setupViews() {
        backgroundColor = UIColor.clear
        
        addSubview(infoCollectionView)
        addSubview(dividerLineView)
        addSubview(nameLabel)
        
        infoCollectionView.dataSource = self
        infoCollectionView.delegate = self
        
        infoCollectionView.register(PersonalInformationCell.self, forCellWithReuseIdentifier: cellId)
        infoCollectionView.register(PersonalInformationAddCell.self, forCellWithReuseIdentifier: cellAddId)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[v0]-14-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[v0]-14-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": dividerLineView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": infoCollectionView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[nameLabel(30)][v0][v1(0.5)]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": infoCollectionView, "v1": dividerLineView, "nameLabel": nameLabel]))
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = personalInformation?.count {
            return count + 1 // take the add button into account
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let pi = personalInformation else { return UICollectionViewCell() }
        if indexPath.item == pi.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellAddId, for: indexPath) as! PersonalInformationAddCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationCell
            cell.personalInformation = personalInformation?[indexPath.item]
            cell.color = color!
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: frame.height - 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 14, 0, 14)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cat = personalInformationCategory, let pi = personalInformation else { return }
        if indexPath.item == pi.count {
            if let cell = self.infoCollectionView.cellForItem(at: indexPath) as? PersonalInformationAddCell {
                cell.toggle(true)
                delegate?.addPersonalInformation(cat: cat.picid)
            }
        }
    }
    
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: ReviewAnswer) {
        guard let pi = personalInformation, let cat = personalInformation?.category else { return }
        delegate?.reviewPersonalInformation(cat: cat, personalInformation: pi, answer: answer)
    }
}


protocol PersonalInformationCellDelegate {
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: ReviewAnswer)
}

fileprivate class PersonalInformationCell: UICollectionViewCell {
    var delegate: PersonalInformationCellDelegate?
    var personalInformation: PersonalInformation? {
        didSet {
            if let name = personalInformation?.name {
                nameLabel.text = name
                layoutIfNeeded()
            }
            if let review = personalInformation?.getReview(of: .personalInformation) {
                questionPlaceView.selected = review.answer
            }
        }
    }
    var color: UIColor? = UIColor.orange {
        didSet {
            bgView.backgroundColor = color!.withAlphaComponent(0.3)
            nameLabel.textColor = color!
            questionPlaceView.selectedColor = color
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
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = color
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var questionPlaceView: QuestionRow = {
        let row = QuestionRow(with: nil, yesAction: {
            self.delegate?.didPressPersonalInformationReview(personalInformation: self.personalInformation, answer: .yes)
        }, noAction: {
            self.delegate?.didPressPersonalInformationReview(personalInformation: self.personalInformation, answer: .no)
        })
        row.unselectedColor = .white
        row.selectedColor = color
        return row
    }()
    
    func setupViews() {
        addSubview(bgView)
        bgView.addSubview(nameLabel)
        bgView.addSubview(questionPlaceView)
        
        addVisualConstraint("H:|-[v0]-|", views: ["v0": nameLabel])
        addVisualConstraint("V:|-10-[v0]", views: ["v0": nameLabel])
        addVisualConstraint("V:[v1(40)]-|", views: ["v1": questionPlaceView])
        
        questionPlaceView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor).isActive = true
        
        addVisualConstraint("H:|[v0]|", views: ["v0": bgView])
        addVisualConstraint("V:|-[v0]-14-|", views: ["v0": bgView])
    }
}


fileprivate class PersonalInformationAddCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = Constants.colors.superLightGray
        return v
    }()
    
    let iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "plus")!.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = Constants.colors.lightGray
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    func setupViews() {
        addSubview(bgView)
        bgView.addSubview(iconView)
        
        addVisualConstraint("H:|-24-[v0]-24-|", views: ["v0": iconView])
        addVisualConstraint("V:|-20-[v0]-20-|", views: ["v0": iconView])
        addVisualConstraint("H:|[v0]|", views: ["v0": bgView])
        addVisualConstraint("V:|-[v0]-14-|", views: ["v0": bgView])
    }
    
    func toggle(_ selected: Bool) {
        if selected {
            bgView.backgroundColor = Constants.colors.lightGray
            iconView.tintColor = Constants.colors.superLightGray
        } else {
            bgView.backgroundColor = Constants.colors.superLightGray
            iconView.tintColor = Constants.colors.lightGray
        }
    }
}


