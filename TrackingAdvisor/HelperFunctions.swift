//
//  HelperFunctions.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 2/9/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

class RoundIconView: UIView {
    var iconDiameter: CGFloat = 30.0
    var scale: CGFloat = 0.75
    
    var color: UIColor! {
        didSet {
            shapeLayer.fillColor = color.cgColor
        }
    }
    
    var image: UIImage! {
        didSet {
            imageView.image = image.withRenderingMode(.alwaysTemplate)
        }
    }
    
    var imageColor: UIColor! {
        didSet {
            imageView.tintColor = imageColor
        }
    }
    
    lazy var shapeLayer: CAShapeLayer = {
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: iconDiameter, height: iconDiameter))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = Constants.colors.primaryDark.cgColor
        shapeLayer.lineWidth = 0
        return shapeLayer
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "times")!.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: (1.0-scale)/2*iconDiameter, y: (1.0-scale)/2*iconDiameter, width: scale*iconDiameter, height: scale*iconDiameter)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(image: UIImage, color: UIColor, imageColor: UIColor) {
        self.init(frame: CGRect.zero)
        
        self.image = image
        self.color = color
        self.imageColor = imageColor
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        self.layer.addSublayer(shapeLayer)
        self.addSubview(imageView)
    }
}


class IconView: UIView {
    
    var icon: String! {
        didSet {
            imageView.image = UIImage(named: icon)!.withRenderingMode(.alwaysTemplate)
            imageView.layoutIfNeeded()
        }
    }
    
    var iconColor: UIColor! {
        didSet {
            imageView.tintColor = iconColor
        }
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: icon)!.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = iconColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(icon: String, iconColor: UIColor) {
        self.init(frame: CGRect.zero)
        
        self.icon = icon
        self.iconColor = iconColor
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        addSubview(imageView)
        
        addVisualConstraint("V:|[v0]|", views: ["v0": imageView])
        addVisualConstraint("H:|[v0]|", views: ["v0": imageView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

func createIconWithText(icon: String, text: String) -> UIView {
    let view = UIView()
    let imageView = UIImageView(image: UIImage(named: icon)!.withRenderingMode(.alwaysTemplate))
    imageView.tintColor = Constants.colors.primaryLight
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    
    let label = UILabel()
    label.text = text
    label.font = UIFont.italicSystemFont(ofSize: 14.0)
    label.textAlignment = .right
    label.textColor = Constants.colors.primaryLight
    label.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(imageView)
    view.addSubview(label)
    
    // add constraints
    view.addVisualConstraint("V:|[v0]|", views: ["v0": imageView])
    view.addVisualConstraint("V:|[v0]|", views: ["v0": label])
    view.addVisualConstraint("H:|[icon]-8-[text(30)]|", views: ["icon": imageView, "text": label])
    
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
}

class FullScreenView: UIView {
    
    var headerTitle: String = "Title" {
        didSet {
            headerLabel.text = headerTitle
            headerLabel.sizeToFit()
        }
    }
    
    var subheaderTitle: String = "Subtitle" {
        didSet {
            textLabel.text = subheaderTitle
            textLabel.sizeToFit()
        }
    }
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = headerTitle
        label.font = UIFont.systemFont(ofSize: 35.0, weight: .heavy)
        label.textColor = Constants.colors.primaryDark
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = subheaderTitle
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .light)
        label.textColor = Constants.colors.primaryLight
        label.textAlignment = .center
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var icon: String = "galaxy" {
        didSet {
            if icon == "walking" {
                let array = getImageArray(icon: icon, numberOfImages: 11, color: iconColor)
                headerImage.animationImages = array
                headerImage.animationDuration = 1.0
                headerImage.animationRepeatCount = 0
                headerImage.startAnimating()
                
            } else if icon == "rocket" {
                let array = getImageArray(icon: icon, numberOfImages: 5, color: iconColor)
                headerImage.animationImages = array
                headerImage.animationDuration = 1.0
                headerImage.animationRepeatCount = 0
                headerImage.startAnimating()
            } else {
                headerImage.image = UIImage(named: icon)!.withRenderingMode(.alwaysTemplate)
            }
            headerImage.layoutIfNeeded()
        }
    }
    
    var iconColor: UIColor = Constants.colors.primaryLight {
        didSet {
            icon = String(icon)
        }
    }
    
    private lazy var headerImage: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.tintColor = iconColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    convenience init(frame: CGRect, icon: String, iconColor: UIColor) {
        self.init(frame: frame)
        
        self.icon = icon
        self.iconColor = iconColor
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        addSubview(headerImage)
        addSubview(headerLabel)
        addSubview(textLabel)
        
        // add constraints
        headerImage.widthAnchor.constraint(equalToConstant: 200).isActive = true
        headerImage.heightAnchor.constraint(equalToConstant: 200).isActive = true
        headerImage.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0.0).isActive = true
        headerImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100.0).isActive = true
        
        addVisualConstraint("H:|-20-[v0]-20-|", views: ["v0": headerLabel])
        addVisualConstraint("H:|-20-[v0]-20-|", views: ["v0": textLabel])
        addVisualConstraint("V:[v0]-[v1]-[v2]", views: ["v0": headerImage, "v1": headerLabel, "v2": textLabel])
    }
    
    private func getImageArray(icon: String, numberOfImages: Int, color: UIColor) -> [UIImage] {
        var imageArray:[UIImage] = []
        for i in 1..<numberOfImages {
            let imageName = "\(icon)-\(i)"
            let image = UIImage(named: imageName)!.withRenderingMode(.alwaysTemplate)
            imageArray.append(image.imageWithTint(tint: color))
        }
        return imageArray
    }
}

class NotificationView: UIView {
    
    var color: UIColor = Constants.colors.primaryDark.withAlphaComponent(0.5) {
        didSet {
            self.backgroundColor = color.withAlphaComponent(0.5)
        }
    }
    
    var text: String = "Some text here" {
        didSet {
            label.text = text
        }
    }
    
    lazy var label: UILabel = {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(text: String) {
        self.init(frame: CGRect.zero)
        
        self.text = text
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        self.layer.cornerRadius = 25.0
        self.backgroundColor = color
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        
        addSubview(label)
        
        addVisualConstraint("V:|-[v0]-|", views: ["v0": label])
        addVisualConstraint("H:|-[v0]-|", views: ["v0": label])
    }
}

func dot(size: Int, color: UIColor) -> UIImage {
    let floatSize = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: floatSize, height: floatSize)
    let strokeWidth: CGFloat = 1
    
    UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
    
    let ovalPath = UIBezierPath(ovalIn: rect.insetBy(dx: strokeWidth, dy: strokeWidth))
    color.setFill()
    ovalPath.fill()
    
    UIColor.white.setStroke()
    ovalPath.lineWidth = strokeWidth
    ovalPath.stroke()
    
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return image
}
