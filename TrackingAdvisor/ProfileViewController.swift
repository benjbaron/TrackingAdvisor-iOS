//
//  ProfileViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 1/5/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import Mapbox

class ProfileViewController: UIViewController, UIScrollViewDelegate, MGLMapViewDelegate {
    // set a content view inside the scroll view
    // From https://developer.apple.com/library/content/technotes/tn2154/_index.html

    var scrollView : UIScrollView!
    var contentView : UIView!
    
    var mainTitle: UILabel = {
        let label = UILabel()
        label.text = "About you"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var studySummary: InfoCardView = {
        return InfoCardView(bigText: BigText(bigText: "28", topExponent: "%", smallBottomText: "DAYS"),
                            descriptionText: "You have been participating in the study for 28 days!")
    }()
    
    var studySummary2: InfoCardView = {
        return InfoCardView(bigText: BigText(bigText: "28", topExponent: "%", smallBottomText: "DAYS"),
                            descriptionText: "You have been participating")
    }()
    
    var mapView: MGLMapView = {
        let map = MGLMapView(frame: CGRect(), styleURL: MGLStyle.lightStyleURL())
        map.zoomLevel = 15
        map.translatesAutoresizingMaskIntoConstraints = false
        map.layer.cornerRadius = 5.0
        map.layer.shadowRadius = 5.0
        map.layer.shadowOpacity = 0.5
        map.layer.shadowOffset = CGSize(width: 5, height: 5)
        map.backgroundColor = Constants.colors.superLightGray
        map.allowsZooming = false
        map.allowsTilting = false
        map.allowsRotating = false
        map.allowsScrolling = false
        
        map.attributionButton.alpha = 0
        map.logoView.alpha = 0
        
        map.clipsToBounds = true
        map.layer.masksToBounds = true
        
        // Center the map on the visit coordinates
        let coordinates = CLLocationCoordinate2D(latitude: 51.524528, longitude: -0.134524)
        map.centerCoordinate = coordinates
        return map
    }()
    
    var zoomMapView: MGLMapView = {
        let map = MGLMapView(frame: CGRect(), styleURL: MGLStyle.lightStyleURL())
        map.zoomLevel = 15
        map.backgroundColor = Constants.colors.superLightGray
        map.attributionButton.alpha = 0
        map.logoView.alpha = 0
        
        // Center the map on the visit coordinates
        let coordinates = CLLocationCoordinate2D(latitude: 51.524528, longitude: -0.134524)
        map.centerCoordinate = coordinates
        return map
    }()
    
    var iconExitMapView: IconView = {
        return IconView(image: UIImage(named: "times")!, color: Constants.colors.primaryDark, imageColor: .white)
    }()
    
    var studyStats: StatsCardView = {
        return StatsCardView(statsOne: BigText(bigText: "28.1", smallBottomText: "DAYS AND\nNIGHTS"),
                             statsTwo: BigText(bigText: "28", smallBottomText: "DAYS"),
                             statsThree: BigText(bigText: "28", smallBottomText: "DAYS"))
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: self.view.frame)
        scrollView.sizeToFit()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.white
        self.view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.white
        scrollView.addSubview(contentView)
        
        let margins = self.view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: margins.topAnchor)
        ])
        self.view.addVisualConstraint("H:|[scrollView]|", views: ["scrollView" : scrollView])
        self.view.addVisualConstraint("V:[scrollView]|",  views: ["scrollView" : scrollView])
        
        scrollView.addVisualConstraint("H:|[contentView]|", views: ["contentView" : contentView])
        scrollView.addVisualConstraint("V:|[contentView]|", views: ["contentView" : contentView])
        
        // make the width of content view to be the same as that of the containing view.
        self.view.addVisualConstraint("H:[contentView(==mainView)]", views: ["contentView" : contentView, "mainView" : self.view])

        scrollView.delegate = self
        mapView.delegate = self
        setupViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupViews() {
        contentView.addSubview(mainTitle)
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        contentView.addVisualConstraint("V:|-48-[v0(40)]", views: ["v0": mainTitle])

        contentView.addSubview(studySummary)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0":studySummary])
        contentView.addVisualConstraint("V:[v0]-16-[v1]", views: ["v0": mainTitle, "v1":studySummary])
        
        contentView.addSubview(studySummary2)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0":studySummary2])
        contentView.addVisualConstraint("V:[v0]-16-[v1]", views: ["v0": studySummary, "v1":studySummary2])
        
        contentView.addSubview(studyStats)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0":studyStats])
        contentView.addVisualConstraint("V:[v0]-16-[v1]", views: ["v0": studySummary2, "v1":studyStats])
        
        contentView.addSubview(mapView)
        mapView.addTapGestureRecognizer {
            self.animateMapViewIn()
        }
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0":mapView])
        contentView.addVisualConstraint("V:[v0]-16-[v1(250)]-32-|", views: ["v0": studyStats, "v1":mapView])
    }
    
    func animateMapViewIn() {
        if let startingFrame = mapView.superview?.convert(mapView.frame, to: nil) {
            mapView.alpha = 0
            zoomMapView.frame = startingFrame
            self.view.addSubview(zoomMapView)
            
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.zoomMapView.frame = CGRect(x: 0, y: -1 * UIApplication.shared.statusBarFrame.height, width: self.view.frame.width, height: self.view.frame.height)
            }, completion: { didComplete in
                if didComplete {
                    self.iconExitMapView.frame = CGRect(x: 20, y: UIApplication.shared.statusBarFrame.height + 10, width: 30, height: 30)
                    self.iconExitMapView.addTapGestureRecognizer {
                        self.animateMapViewOut()
                    }
                    self.view.addSubview(self.iconExitMapView)
                }
            })
        }
    }
    
    func animateMapViewOut() {
        if let startingFrame = mapView.superview?.convert(mapView.frame, to: nil) {
            self.iconExitMapView.removeFromSuperview()
            UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.zoomMapView.frame = startingFrame
            }, completion: { didComplete in
                if didComplete {
                    self.zoomMapView.removeFromSuperview()
                    self.mapView.alpha = 1
                }
            })
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class InfoCardView: UIView {
    var bigTextColor: UIColor = Constants.colors.primaryDark {
        didSet {
            bigTextLabel.color = bigTextColor
        }
    }
    var bigText: BigText = BigText() {
        didSet {
            bigTextLabel.bigText = bigText
        }
    }
    var descriptionTextColor: UIColor = Constants.colors.primaryLight {
        didSet {
            descriptionTextLabel.textColor = descriptionTextColor
        }
    }
    var descriptionText: String = "" {
        didSet {
            descriptionTextLabel.text = descriptionText
        }
    }
    
    lazy var bigTextLabel: BigLabel = {
        return BigLabel(bigText: bigText, color: bigTextColor)
    }()
    
    lazy var descriptionTextLabel: UILabel = {
        let label = UILabel()
        label.text = descriptionText
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = descriptionTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(bigText: BigText, descriptionText: String) {
        self.init(frame: CGRect.zero)
        
        self.bigText = bigText
        self.descriptionText = descriptionText
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 5.0
        self.layer.shadowRadius = 5.0
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.backgroundColor = Constants.colors.superLightGray
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
    }
    
    func setupViews() {
        addSubview(bigTextLabel)
        addSubview(descriptionTextLabel)
        
        // set content compression resistance
        // see: https://krakendev.io/blog/autolayout-magic-like-harry-potter-but-real
        bigTextLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        descriptionTextLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        
         // setup contraints
        addVisualConstraint("V:|-[v0]-12-|", views: ["v0": bigTextLabel])
        addVisualConstraint("V:|-[v0]-12-|", views: ["v0": descriptionTextLabel])
        addVisualConstraint("H:|-16-[v0]-8-[v1]-16-|", views: ["v0": bigTextLabel, "v1": descriptionTextLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

class StatsCardView: UIView {
    var statsOne: BigText! {
        didSet {
            statsOneLabel.bigText = statsOne
        }
    }
    var statsOneColor: UIColor = Constants.colors.primaryDark {
        didSet {
            statsOneLabel.color = statsOneColor
        }
    }
    lazy var statsOneLabel: BigLabel = {
        return BigLabel(bigText: statsOne, color: statsOneColor)
    }()
    
    var statsTwo: BigText! {
        didSet {
            statsTwoLabel.bigText = statsTwo
        }
    }
    var statsTwoColor: UIColor = Constants.colors.primaryDark {
        didSet {
            statsTwoLabel.color = statsTwoColor
        }
    }
    lazy var statsTwoLabel: BigLabel = {
        return BigLabel(bigText: statsTwo, color: statsTwoColor)
    }()
    
    var statsThree: BigText! {
        didSet {
            statsThreeLabel.bigText = statsThree
        }
    }
    var statsThreeColor: UIColor = Constants.colors.primaryDark {
        didSet {
            statsThreeLabel.color = statsThreeColor
        }
    }
    lazy var statsThreeLabel: BigLabel = {
        return BigLabel(bigText: statsThree, color: statsThreeColor)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(statsOne: BigText, statsTwo: BigText, statsThree: BigText) {
        self.init(frame: CGRect.zero)
        
        self.statsOne = statsOne
        self.statsTwo = statsTwo
        self.statsThree = statsThree
        
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 3.0
        self.layer.shadowRadius = 3.0
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.backgroundColor = Constants.colors.superLightGray
        
        self.clipsToBounds = true
        self.layer.masksToBounds = true
    }
    
    func setupViews() {
        addSubview(statsOneLabel)
        addSubview(statsTwoLabel)
        addSubview(statsThreeLabel)
        
        // setup contraints
        addVisualConstraint("V:|-[v0]", views: ["v0": statsOneLabel])
        addVisualConstraint("V:|-[v0]", views: ["v0": statsTwoLabel])
        addVisualConstraint("V:|-[v0]", views: ["v0": statsThreeLabel])
        addVisualConstraint("H:|-16-[v0]->=16-[v1]->=16-[v2]-16-|", views: ["v0": statsOneLabel, "v1": statsTwoLabel, "v2": statsThreeLabel], options: .alignAllTop)
        NSLayoutConstraint(item: statsTwoLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        
        var tallestBigLabel:BigLabel = statsOneLabel
        if statsTwoLabel.height > statsOneLabel.height && statsTwoLabel.height > statsThreeLabel.height {
            tallestBigLabel = statsTwoLabel
        } else if statsThreeLabel.height > statsOneLabel.height && statsThreeLabel.height > statsTwoLabel.height {
            tallestBigLabel = statsThreeLabel
        }
        addVisualConstraint("V:[v0]-12-|", views: ["v0": tallestBigLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

struct BigText {
    var bigText: String
    var topExponent: String?
    var smallBottomText: String?
    
    init() {
        self.bigText = ""
    }
    
    init(bigText: String) {
        self.bigText = bigText
    }
    
    init(bigText: String, smallBottomText: String) {
        self.bigText = bigText
        self.smallBottomText = smallBottomText
    }
    
    init(bigText: String, topExponent: String?, smallBottomText: String?) {
        self.bigText = bigText
        self.topExponent = topExponent
        self.smallBottomText = smallBottomText
    }
    
}

class BigLabel: UIView {
    var bigText: BigText! {
        didSet {
            bigTextLabel.text = bigText.bigText
            topExponentLabel.text = bigText.topExponent ?? ""
            smallBottomTextLabel.text = bigText.smallBottomText ?? ""
        }
    }
    var color: UIColor! {
        didSet {
            bigTextLabel.textColor = color
            topExponentLabel.textColor = color
            smallBottomTextLabel.textColor = color.withAlphaComponent(0.7)
        }
    }
    var bigTextLabel: UILabel!
    var topExponentLabel: UILabel!
    var smallBottomTextLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(bigText: BigText, color: UIColor) {
        self.init(frame: CGRect.zero)
        
        self.bigText = bigText
        self.color = color
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        bigTextLabel = UILabel()
        bigTextLabel.text = bigText.bigText
        bigTextLabel.textAlignment = .left
        bigTextLabel.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        bigTextLabel.textColor = color
        bigTextLabel.sizeToFit()
        bigTextLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bigTextLabel)
        
        topExponentLabel = UILabel()
        topExponentLabel!.text = bigText.topExponent ?? ""
        topExponentLabel!.textAlignment = .left
        topExponentLabel!.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        topExponentLabel!.textColor = color
        topExponentLabel.numberOfLines = 1
        topExponentLabel!.sizeToFit()
        topExponentLabel!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topExponentLabel!)
        
        smallBottomTextLabel = UILabel()
        smallBottomTextLabel!.text = bigText.smallBottomText ?? ""
        smallBottomTextLabel!.textAlignment = .left
        smallBottomTextLabel!.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        smallBottomTextLabel!.textColor = color.withAlphaComponent(0.7)
        smallBottomTextLabel.numberOfLines = 0
        smallBottomTextLabel!.sizeToFit()
        smallBottomTextLabel!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(smallBottomTextLabel!)
        
        // set up the constraints
        addVisualConstraint("V:|[v0]", views: ["v0": bigTextLabel])
        addVisualConstraint("H:|[v0][v1]|", views: ["v0": bigTextLabel, "v1": topExponentLabel!])
        addVisualConstraint("V:|-7-[v0]", views: ["v0": topExponentLabel!])
        addVisualConstraint("H:|[v0]", views: ["v0": smallBottomTextLabel!])
        addVisualConstraint("V:|[v0]-(==-5)-[v1]|", views: ["v0": bigTextLabel, "v1": smallBottomTextLabel!])

        translatesAutoresizingMaskIntoConstraints = false
    }
    
    lazy var height:CGFloat = {
        return bigTextLabel.bounds.height + smallBottomTextLabel.bounds.height - 5
    }()
    
    lazy var width:CGFloat = {
        return max(bigTextLabel.bounds.width + topExponentLabel.bounds.width, smallBottomTextLabel.bounds.width)
    }()
}

class IconView: UIView {
    
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
