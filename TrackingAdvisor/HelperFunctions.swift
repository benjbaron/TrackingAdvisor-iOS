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
    var fill: Bool = true
    
    var color: UIColor! {
        didSet {
            if fill {
                shapeLayer.fillColor = color.cgColor
            } else {
                shapeLayer.strokeColor = color.cgColor
            }
            imageView.layoutIfNeeded()
        }
    }
    
    var image: UIImage! {
        didSet {
            imageView.image = image.withRenderingMode(.alwaysTemplate)
            imageView.layoutIfNeeded()
        }
    }
    
    var imageColor: UIColor! {
        didSet {
            imageView.tintColor = imageColor
            imageView.layoutIfNeeded()
        }
    }
    
    lazy var shapeLayer: CAShapeLayer = {
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: iconDiameter, height: iconDiameter))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        if fill {
            shapeLayer.fillColor = color.cgColor
            shapeLayer.lineWidth = 0
        } else {
            shapeLayer.strokeColor = color.cgColor
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 2
        }
        
        return shapeLayer
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.tintColor = imageColor
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: (1.0-scale)/2*iconDiameter, y: (1.0-scale)/2*iconDiameter, width: scale*iconDiameter, height: scale*iconDiameter)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(image: UIImage, color: UIColor, imageColor: UIColor, diameter: CGFloat = 30.0, scale: CGFloat = 0.75, fill: Bool = true) {
        self.init(frame: CGRect.zero)
        
        self.image = image
        self.color = color
        self.imageColor = imageColor
        self.iconDiameter = diameter
        self.scale = scale
        self.fill = fill
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
    
    var icon: String? = "profile" {
        didSet {
            imageView.image = UIImage(named: icon!)!.withRenderingMode(.alwaysTemplate)
            imageView.layoutIfNeeded()
        }
    }
    
    var iconColor: UIColor? = Constants.colors.primaryDark {
        didSet {
            imageView.tintColor = iconColor
        }
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: icon!)!.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = iconColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(icon: String?, iconColor: UIColor?) {
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
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = subheaderTitle
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .light)
        label.textColor = Constants.colors.primaryLight
        label.textAlignment = .center
        label.numberOfLines = 4
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var button: UIButton = {
        let l = UIButton(type: .system)
        l.layer.cornerRadius = 5.0
        l.layer.masksToBounds = true
        l.setTitle("", for: .normal)
        l.setTitleColor(.white, for: .normal)
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.backgroundColor = iconColor
        l.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    @objc fileprivate func tappedButton() {
        buttonAction?()
    }
    
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
    
    var buttonText: String = "" {
        didSet {
            button.setTitle(buttonText, for: .normal)
            if buttonText != "" {
                buttonConstraint?.constant = 64
            }
        }
    }
    
    var buttonConstraint: NSLayoutConstraint?
    var buttonAction: (()->Void)?
    var iconColor: UIColor = Constants.colors.primaryLight {
        didSet {
            icon = String(icon)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = iconColor
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
        backgroundColor = .white
        
        addSubview(headerImage)
        addSubview(headerLabel)
        addSubview(textLabel)
        addSubview(button)
        
        // add constraints
        headerImage.widthAnchor.constraint(equalToConstant: 200).isActive = true
        headerImage.heightAnchor.constraint(equalToConstant: 200).isActive = true
        headerImage.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0.0).isActive = true
        headerImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100.0).isActive = true
        
        addVisualConstraint("H:|-20-[v0]-20-|", views: ["v0": headerLabel])
        addVisualConstraint("H:|-20-[v0]-20-|", views: ["v0": textLabel])
        addVisualConstraint("H:|-20-[v0]-20-|", views: ["v0": button])
        addVisualConstraint("V:[v0]-[v1]-[v2]-10-[v3]", views: ["v0": headerImage, "v1": headerLabel, "v2": textLabel, "v3": button])
        
        buttonConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        buttonConstraint?.isActive = true
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

class CloseView: UIView {
    var color: UIColor = Constants.colors.primaryDark {
        didSet {
            self.backgroundColor = color.withAlphaComponent(0.5)
        }
    }
    
    var text: String = "Some text here" {
        didSet {
            label.text = text
            layoutIfNeeded()
        }
    }
    
    var closeIcon: IconView = {
        return IconView(icon: "times", iconColor: .white)
    }()
    
    lazy var label: UILabel = {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.textAlignment = .right
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
        self.layer.cornerRadius = 20.0
        self.backgroundColor = color
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        
        addSubview(label)
        addSubview(closeIcon)
        
        addVisualConstraint("V:|-[v0]-|", views: ["v0": label])
        addVisualConstraint("H:|-14-[v0(15)][v1]-14-|", views: ["v0": closeIcon, "v1": label])
        closeIcon.widthAnchor.constraint(equalToConstant: 15).isActive = true
        closeIcon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
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

func matches(for regex: String, in text: String) -> [String] {
    
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}
