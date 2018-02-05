//
//  InterestCell.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/16/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

enum PersonalInformationCategoryType {
    case regularPersonalInformation
    case addPersonalInformation
}

protocol PersonalInformationCategoryDelegate {
    func didPressPersonalInformation(type: PersonalInformationCategoryType, name: String)
}

class PersonalInformationCategoryCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var delegate: PersonalInformationCategoryDelegate?
    var personalInformationCategory: PersonalInformationCategory? {
        didSet {
            if let name = personalInformationCategory?.name {
                nameLabel.text = name
            }
            infoCollectionView.reloadData()
        }
    }
    var personalInformation: [PersonalInformation]? = []
    
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
            cell.personalInfo = personalInformation?[indexPath.item]
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: frame.height - 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 14, 0, 14)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cat = personalInformationCategory, let pi = personalInformation else { return }
        if indexPath.item == pi.count {
            print("clicked on the add button")
            if let cell = self.infoCollectionView.cellForItem(at: indexPath) as? PersonalInformationAddCell {
                cell.toggle(true)
                delegate?.didPressPersonalInformation(type: .addPersonalInformation, name: cat.name)
            }
        } else {
            personalInformation![indexPath.item].getReview(of: .personalInformation)?.answer = .yes
            self.infoCollectionView.layoutIfNeeded()  // to make cellForItem work
            if (self.infoCollectionView.cellForItem(at: indexPath) as? PersonalInformationCell) != nil {
                delegate?.didPressPersonalInformation(type: .regularPersonalInformation, name: cat.name)
            }
        }
    }
}


fileprivate class PersonalInformationCell: UICollectionViewCell {
    // TODO: - Add check / times marks to get "better" feedback from the users
    var personalInfo: PersonalInformation? {
        didSet {
            if let name = personalInfo?.name {
                nameLabel.text = name
            }
            
            if let review = personalInfo?.getReview(of: .personalInformation) {
                var alpha: CGFloat = 0.2
                switch review.answer {
                    case .none:
                        alpha = 0.2
                    case .yes:
                        alpha = 0.8
                    case .no:
                        alpha = 0.2
                }
                bgView.backgroundColor = UIColor.orange.withAlphaComponent(alpha)
                if alpha > 0.25 {
                    nameLabel.textColor = .white
                } else {
                    nameLabel.textColor = .black
                }
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
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.orange.withAlphaComponent(0.4)
        return v
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal information"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func setupViews() {
        addSubview(bgView)
        addSubview(nameLabel)
        
        addVisualConstraint("H:|-[v0]-|", views: ["v0": nameLabel])
        addVisualConstraint("V:|-[v0]-|", views: ["v0": nameLabel])
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


