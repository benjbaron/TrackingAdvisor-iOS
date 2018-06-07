//
//  TutorialOverlayView.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 5/25/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit

protocol TutorialOverlayViewDelegate {
    func tutorialFinished()
}

class TutorialOverlayView : UIView, OverlayViewDelegate {
    var delegate: TutorialOverlayViewDelegate?
    var color: UIColor = Constants.colors.midPurple
    var buttonText: String? { didSet {
        dismissButton.setTitle(buttonText, for: .normal)
    }}
    var titleText: String? { didSet {
        titleLabel.text = titleText
    }}
    var subtitleText: String? { didSet {
        subtitleLabel.text = subtitleText
    }}
    var showHeaderShadow: Bool? { didSet {
        if showHeaderShadow! {
            headerBgView.layer.shadowOffset = CGSize(width: 0, height: 2)
            headerBgView.layer.shadowOpacity = 0.2
            headerBgView.layer.shadowRadius = 2.0
            headerBgView.layer.shadowColor = Constants.colors.black.cgColor
        } else {
            headerBgView.layer.shadowOffset = CGSize(width: 0, height: 0)
            headerBgView.layer.shadowOpacity = 0
            headerBgView.layer.shadowRadius = 0
            headerBgView.layer.shadowColor = Constants.colors.black.cgColor
        }
    }}
    var isButtonEnabled: Bool? { didSet {
        dismissButton.isEnabled = isButtonEnabled!
        if !isButtonEnabled! {
            dismissButton.setTitleColor(Constants.colors.midPurpleDarker, for: .normal)
        } else {
            dismissButton.setTitleColor(Constants.colors.superLightGray, for: .normal)
        }
    }}
    var currentPage: Int = 0
    
    lazy var headerBgView: UIView = {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quick tutorial"
        if AppDelegate.isIPhone5() {
            label.font = UIFont.systemFont(ofSize: 20.0, weight: .black)
        } else {
            label.font = UIFont.systemFont(ofSize: 25.0, weight: .black)
        }
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Thank you for participating in the study! We would like to show you how you can good feedback with this short tutorial."
        if AppDelegate.isIPhone5() {
            label.font = UIFont.italicSystemFont(ofSize: 14.0)
        } else {
            label.font = UIFont.italicSystemFont(ofSize: 16.0)
        }
        label.textAlignment = .center
        label.numberOfLines = 4
        label.lineBreakMode = .byWordWrapping
        label.textColor = Constants.colors.superLightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dismissButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.layer.masksToBounds = true
        btn.setTitle("Next", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        btn.setTitleColor(Constants.colors.superLightGray, for: .normal)
        btn.setTitleColor(color, for: .highlighted)
        btn.setBackgroundColor(color, for: .normal)
        btn.setBackgroundColor(Constants.colors.lightGray, for: .highlighted)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tappedDismissButton), for: .touchUpInside)
        return btn
    }()
    
    private var pageViewController: UIPageViewController!

    @objc private func tappedDismissButton() {
        // switch to a new page controller
        if currentPage == 0 {
            // 1 - Visit tutorial
            let vc = TutorialVisitsViewController()
            vc.parentView = self
            pageViewController.setViewControllers([vc], direction: .forward, animated: true)
            currentPage = 1
        } else if currentPage == 1 {
            // 2 - Place review
            let vc = TutorialPlaceReviewsViewController()
            vc.parentView = self
            pageViewController.setViewControllers([vc], direction: .forward, animated: true)
            currentPage = 2
        } else if currentPage == 2 {
            // 3 - Personal information review
            let vc = TutorialAPIReviewsViewController()
            vc.parentView = self
            pageViewController.setViewControllers([vc], direction: .forward, animated: true)
            currentPage = 3
        } else if currentPage == 3 {
            // 4 - End tutorial
            let vc = TutorialEndViewController()
            vc.parentView = self
            pageViewController.setViewControllers([vc], direction: .forward, animated: true)
            currentPage = 4
        } else if currentPage == 4 {
            // dismiss
            deleteDummyData()
            OverlayView.shared.hideOverlayView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupViews()
        
        // default: show the welcome screen
        let vc = TutorialIntroductionViewController()
        vc.parentView = self
        pageViewController.setViewControllers([vc], direction: .forward, animated: true)
        
        // create the dummy data we will use for the tutorial
        DispatchQueue.global(qos: .background).async { [unowned self] in
            self.createDummyData()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        // setup the view itself
        let overlayFrame = OverlayView.frame()
        if AppDelegate.isIPhoneX() {
            self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 50, height: overlayFrame.height - 200)
        } else if AppDelegate.isIPhone5() {
            self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 25, height: overlayFrame.height - 50)
        } else {
            self.frame = CGRect(x: 0, y: 0, width: overlayFrame.width - 50, height: overlayFrame.height - 100)
        }
        self.center = CGPoint(x: overlayFrame.width / 2.0, y: overlayFrame.height / 2.0)
        backgroundColor = .white
        clipsToBounds = true
        layer.cornerRadius = 10

        addSubview(headerBgView)
        headerBgView.addSubview(titleLabel)
        headerBgView.addSubview(subtitleLabel)
        headerBgView.addVisualConstraint("H:|-14-[title]-14-|", views: ["title": titleLabel])
        headerBgView.addVisualConstraint("H:|-14-[subtitle]-14-|", views: ["subtitle": subtitleLabel])
        headerBgView.addVisualConstraint("V:|-14-[title]-3-[subtitle]-14-|", views: ["title": titleLabel, "subtitle": subtitleLabel])
        
        addSubview(dismissButton)
        addVisualConstraint("H:|[v0]|", views: ["v0": headerBgView])
        addVisualConstraint("H:|[v0]|", views: ["v0": dismissButton])
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(pageViewController.view, belowSubview: headerBgView)
        addVisualConstraint("H:|[v0]|", views: ["v0": pageViewController.view])
        
        addVisualConstraint("V:|[header][pager][dismiss(64)]|", views: ["header": headerBgView, "pager": pageViewController.view, "dismiss": dismissButton])
        
        dismissButton.isEnabled = false
    }
    
    private func createDummyData() {
        // populate the personalinformation array
        
        let place = UserPlace(pid: "dummy-place", name: "Bilbo's", t: "user", pt: nil, lon: 0.0, lat: 0.0, c: "The Shire", a: "Hobbiton", col: "#24509A", icon: nil, emoji: nil)
        let visit: UserVisit = UserVisit(vid: "dummy-visit", pid: "dummy-place", a: Date(), d: Date(), c: 1.0, visited: true)
        
        var pis: [UserPersonalInformation] = []
        pis.append(UserPersonalInformation(piid: "dummy-pi-1", picid: "INT", pid: "dummy-place", icon: nil, name: "Hobbiton", d: nil, s: nil, e: nil, p: nil, r: 0))
        pis.append(UserPersonalInformation(piid: "dummy-pi-2", picid: "ETH", pid: "dummy-place", icon: nil, name: "Hobbit", d: nil, s: nil, e: nil, p: nil, r: 0))
        pis.append(UserPersonalInformation(piid: "dummy-pi-3", picid: "INT", pid: "dummy-place", icon: nil, name: "The Shire", d: nil, s: nil, e: nil, p: nil, r: 0))
        
        var apis: [UserAggregatedPersonalInformation] = []
        apis.append(UserAggregatedPersonalInformation(piid: "dummy-api-1", picid: "INT", name: "Hobbiton", d: nil, icon: nil, privacy: nil, subcat: nil, scicon: nil, rpi: 0, rexp: 0, rpriv: 0, explanation: nil, piids: ["dummy-pi-1"], com: nil))
        apis.append(UserAggregatedPersonalInformation(piid: "dummy-api-2", picid: "ETH", name: "Hobbit", d: nil, icon: nil, privacy: nil, subcat: nil, scicon: nil, rpi: 0, rexp: 0, rpriv: 0, explanation: nil, piids: ["dummy-pi-2"], com: nil))
        apis.append(UserAggregatedPersonalInformation(piid: "dummy-api-3", picid: "INT", name: "The Shire", d: nil, icon: nil, privacy: nil, subcat: nil, scicon: nil, rpi: 0, rexp: 0, rpriv: 0, explanation: nil, piids: ["dummy-pi-3"], com: nil))
        
        // create a UserUpdate instance
        let userUpdate = UserUpdate(uid: nil, from: nil, to: nil, days: [DateHandler.dateToDayString(from: Date())], rv: nil, rpi: nil, p: [place], v: [visit], m: nil, pi: pis, api: apis, q: nil)
        
        // save the user update in the database
        DataStoreService.shared.updateDatabase(with: userUpdate, callback: { [unowned self] in
            self.dismissButton.isEnabled = true
        })
    }
    
    private func deleteDummyData() {
        print("deleteDummyData")
        DataStoreService.shared.deletePlace(pid: "dummy-place", ctxt: nil)
        DataStoreService.shared.deleteVisit(vid: "dummy-visit", ctxt: nil)
        
        DataStoreService.shared.deletePersonalInformation(piid: "dummy-pi-1", ctxt: nil)
        DataStoreService.shared.deletePersonalInformation(piid: "dummy-pi-2", ctxt: nil)
        DataStoreService.shared.deletePersonalInformation(piid: "dummy-pi-3", ctxt: nil)
        
        DataStoreService.shared.deleteAggregatedPersonalInformation(piid: "dummy-api-1", ctxt: nil)
        DataStoreService.shared.deleteAggregatedPersonalInformation(piid: "dummy-api-2", ctxt: nil)
        DataStoreService.shared.deleteAggregatedPersonalInformation(piid: "dummy-api-3", ctxt: nil)
    }
    
    // MARK: - OverlayViewDelegate method
    func overlayViewDismissed() {
        deleteDummyData()
        delegate?.tutorialFinished()
//        Settings.staveTutorial(value: true)
    }
}

class TutorialIntroductionViewController : UIViewController {
    var parentView: TutorialOverlayView? {
        didSet {
            parentView?.buttonText = "Next"
            parentView?.titleText = ""
            parentView?.subtitleText = ""
            parentView?.showHeaderShadow = false
        }
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 25.0, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "Quick tutorial"
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .light)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Thank you for participating in the study! We've made this short tutorial to show you how to give us useful feedback throughout this study."
        return label
    }()
    
    lazy var titleImage: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        let array = getImageArray(icon: "walking", numberOfImages: 11, color: .white)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.animationImages = array
        imageView.animationDuration = 1.0
        imageView.animationRepeatCount = 0
        imageView.startAnimating()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
         view.backgroundColor = Constants.colors.midPurple
        
        setupViews()
    }
    
    private func setupViews() {
        let vStackView = UIStackView(arrangedSubviews: [titleImage, titleLabel, subtitleLabel])
        vStackView.alignment = .center
        vStackView.axis = .vertical
        vStackView.distribution = .fillProportionally
        vStackView.spacing = 10
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vStackView)
        titleImage.widthAnchor.constraint(equalToConstant: 150).isActive = true
        titleImage.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        view.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": vStackView])
        vStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    private func getImageArray(icon: String, numberOfImages: Int, color: UIColor?) -> [UIImage] {
        var imageArray:[UIImage] = []
        for i in 1..<numberOfImages {
            let imageName = "\(icon)-\(i)"
            let image = UIImage(named: imageName)!.withRenderingMode(.alwaysTemplate)
            if let color = color {
                imageArray.append(image.imageWithTint(tint: color))
            } else {
                imageArray.append(image)
            }
        }
        return imageArray
    }
}

class TutorialVisitsViewController : UIViewController {
    var parentView: TutorialOverlayView? {
        didSet {
            parentView?.buttonText = "Next"
            parentView?.titleText = "Visit confirmation"
            parentView?.subtitleText = "We automatically detect places that you visited during your day. We ask you to confirm the visits we detected."
            parentView?.showHeaderShadow = true
            parentView?.isButtonEnabled = false
        }
    }
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.colors.lightGray

        view.addSubview(bottomLabel)
        view.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": bottomLabel])
        view.addVisualConstraint("V:|-[v0]-|", views: ["v0": bottomLabel])
        return view
    }()
    
    lazy var bottomLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 6
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .light)
        label.textColor = .black
        let formattedString = NSMutableAttributedString()
        formattedString
            .normal("Let's imagine that you are ")
            .bold("Gandalf")
            .normal(" and that you visit ")
            .bold("Bilbo the Hobbit")
            .normal(" in his home at ")
            .bold("Hobbiton")
            .normal(" in the ")
            .bold("Shire")
            .normal(".")
        label.attributedText = formattedString
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var gandalfImage: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = UIImage(named: "gandalf")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.gray.withAlphaComponent(0.5)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var feedbackView: UIView!
    var helperArrowView: UIImageView!
    var helperTextView: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupViews()
    }
    
    private func setupViews() {
        view.addSubview(gandalfImage)
        view.addSubview(bottomView)
        view.addVisualConstraint("H:|[v0]|", views: ["v0": bottomView])
        view.addVisualConstraint("V:[v0(100)]|", views: ["v0": bottomView])
        
        // set up gandalf
        gandalfImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        gandalfImage.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        gandalfImage.widthAnchor.constraint(equalToConstant: 150).isActive = true
        gandalfImage.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        // set up the timeline
        let timelineView = UIView()
        timelineView.backgroundColor = Constants.colors.primaryDark
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(timelineView, belowSubview: bottomView)
        view.addVisualConstraint("V:|-30-[v0]|", views: ["v0": timelineView])
        view.addVisualConstraint("H:|-50-[v0(16)]", views: ["v0": timelineView])
        
        let timelineTopView = UIView()
        timelineTopView.backgroundColor = Constants.colors.primaryDark
        timelineTopView.translatesAutoresizingMaskIntoConstraints = false
        timelineTopView.layer.cornerRadius = 8
        view.insertSubview(timelineTopView, belowSubview: bottomView)
        timelineTopView.centerXAnchor.constraint(equalTo: timelineView.centerXAnchor).isActive = true
        timelineTopView.centerYAnchor.constraint(equalTo: timelineView.topAnchor).isActive = true
        timelineTopView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        timelineTopView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let timelinePlaceView = UIView()
        timelinePlaceView.backgroundColor = Constants.colors.primaryLight
        timelinePlaceView.translatesAutoresizingMaskIntoConstraints = false
        timelinePlaceView.layer.cornerRadius = 6
        view.insertSubview(timelinePlaceView, belowSubview: bottomView)
        timelinePlaceView.centerXAnchor.constraint(equalTo: timelineView.centerXAnchor).isActive = true
        timelinePlaceView.centerYAnchor.constraint(equalTo: timelineView.topAnchor).isActive = true
        timelinePlaceView.widthAnchor.constraint(equalToConstant: 12).isActive = true
        timelinePlaceView.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        let placeIcon = RoundIconView(image: UIImage(named: "home")!.withRenderingMode(.alwaysTemplate), color: Constants.colors.primaryDark, imageColor: .white)
        placeIcon.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(placeIcon, belowSubview: bottomView)
        view.addVisualConstraint("H:|-10-[v0]", views: ["v0": placeIcon])
        placeIcon.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        placeIcon.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        placeIcon.centerYAnchor.constraint(equalTo: timelineTopView.centerYAnchor).isActive = true
        
        let placeNameLabel = UILabel()
        placeNameLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        placeNameLabel.textColor = Constants.colors.black
        placeNameLabel.textAlignment = .left
        placeNameLabel.lineBreakMode = .byWordWrapping
        placeNameLabel.numberOfLines = 0
        placeNameLabel.text = "Bilbo's"
        placeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(placeNameLabel, belowSubview: bottomView)
        view.addVisualConstraint("H:[line]-12-[label]-20-|", views: ["line": timelineView, "label": placeNameLabel])
        placeNameLabel.centerYAnchor.constraint(equalTo: placeIcon.centerYAnchor).isActive = true
        
        let placeDescriptionLabel = UILabel()
        placeDescriptionLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .light)
        placeDescriptionLabel.textColor = Constants.colors.descriptionColor
        placeDescriptionLabel.textAlignment = .left
        placeDescriptionLabel.lineBreakMode = .byWordWrapping
        placeDescriptionLabel.numberOfLines = 0
        placeDescriptionLabel.text = "Visited from 11:12 to 15:25"
        placeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(placeDescriptionLabel, belowSubview: bottomView)
        view.addVisualConstraint("H:[line]-12-[label]-|", views: ["line": timelineView, "label": placeDescriptionLabel])
        view.addVisualConstraint("V:[title][description]", views: ["title": placeNameLabel, "description": placeDescriptionLabel])
        
        // build the feedback view
        feedbackView = UIView()
        feedbackView.translatesAutoresizingMaskIntoConstraints = false
        let btn1 = feedbackButton(text: "Yes ✓", tag: 1, type: 0)
        let btn2 = feedbackButton(text: "Delete ✕", tag: 1, type: 1)
        let btn3 = feedbackButton(text: "Correct ‣", tag: 1, type: 2)
        
        feedbackView.addSubview(btn1)
        feedbackView.addSubview(btn2)
        feedbackView.addSubview(btn3)
        feedbackView.addVisualConstraint("H:|[b1]-10-[b2]-10-[b3]|", views: ["b1": btn1, "b2": btn2, "b3": btn3])
        feedbackView.addVisualConstraint("V:|[b(40)]|", views: ["b": btn1])
        feedbackView.addVisualConstraint("V:|[b(40)]|", views: ["b": btn2])
        feedbackView.addVisualConstraint("V:|[b(40)]|", views: ["b": btn3])
        btn1.widthAnchor.constraint(equalTo: btn2.widthAnchor).isActive = true
        btn2.widthAnchor.constraint(equalTo: btn3.widthAnchor).isActive = true
        btn3.widthAnchor.constraint(equalTo: btn1.widthAnchor).isActive = true
        
        view.addSubview(feedbackView)
        view.addVisualConstraint("H:[line]-12-[feeback]-|", views: ["line": timelineView, "feeback": feedbackView])
        view.addVisualConstraint("V:[description]-[feedback]", views: ["description": placeDescriptionLabel, "feedback": feedbackView])
        
        // show a helper arrow
        helperArrowView = UIImageView(image: UIImage(named: "arrow-up")!.withRenderingMode(.alwaysTemplate))
        helperArrowView.tintColor = Constants.colors.darkRed
        helperArrowView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(helperArrowView)
        helperArrowView.widthAnchor.constraint(equalToConstant: 35.0).isActive = true
        helperArrowView.heightAnchor.constraint(equalToConstant: 35.0).isActive = true
        helperArrowView.centerXAnchor.constraint(equalTo: btn1.centerXAnchor).isActive = true
        helperArrowView.topAnchor.constraint(equalTo: feedbackView.bottomAnchor).isActive = true
        
        // show a helper text
        helperTextView = UILabel()
        helperTextView.textColor = Constants.colors.darkRed
        helperTextView.font = UIFont.italicSystemFont(ofSize: 14.0)
        helperTextView.numberOfLines = 0
        helperTextView.text = "Tap here to confirm you visit at Bilbo's"
        helperTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(helperTextView)
        view.addVisualConstraint("H:[line]-20-[label]-|", views: ["line": timelineView, "label": helperTextView])
        view.addVisualConstraint("V:[arrow]-[text]", views: ["arrow": helperArrowView, "text": helperTextView])
    }
    
    fileprivate func feedbackButton(text: String, tag: Int, type: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.layer.cornerRadius = 5.0
        btn.layer.masksToBounds = true
        btn.tag = tag
        btn.setTitle(text, for: .normal)
        btn.setTitleColor(Constants.colors.primaryDark, for: .normal)
        btn.setTitleColor(Constants.colors.primaryMidDark, for: .highlighted)
        btn.backgroundColor = Constants.colors.superLightGray
        btn.titleLabel?.font =  UIFont.italicSystemFont(ofSize: 14.0)
        btn.addTarget(self, action: #selector(feedbackButtonTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        return btn
    }

    @objc func feedbackButtonTapped(sender: UIButton) {
        print("tapped button")
        // hide the feedback view
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.beginFromCurrentState], animations: { [weak self] in
            self?.feedbackView.alpha = 0
            self?.helperArrowView.alpha = 0
            self?.helperTextView.alpha = 0
            
            }, completion: { [weak self] _ in
                let formattedString = NSMutableAttributedString()
                formattedString.normal("Now that we are sure that you've visited Bilbo's, we've automatically inferred some personal information about the place.", of: 14)
                self?.bottomLabel.attributedText = formattedString
                self?.parentView?.isButtonEnabled = true
        })
    }
    
}


class TutorialPlaceReviewsViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PersonalInformationCellDelegate {
    var parentView: TutorialOverlayView? {
        didSet {
            parentView?.buttonText = "Next"
            parentView?.titleText = "Place review"
            parentView?.subtitleText = ""
            parentView?.showHeaderShadow = true
            parentView?.isButtonEnabled = false
        }
    }
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.colors.lightGray
        
        view.addSubview(bottomLabel)
        view.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": bottomLabel])
        view.addVisualConstraint("V:|-[v0]-|", views: ["v0": bottomLabel])
        return view
    }()
    
    lazy var bottomLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 6
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .light)
        label.textColor = .black
        let formattedString = NSMutableAttributedString()
        formattedString
            .normal("With your visit at ", of: 14)
            .bold("Bilbo the Hobbit", of: 14)
            .normal(", we have automatically inferred the following personal information about the place you visited.", of: 14)
            .italic(" We ask you to review the relevance of the personal information with the place.", of: 14)
        label.attributedText = formattedString
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var containerView: UIView!
    var collectionView : UICollectionView!
    var flowLayout: PlaceReviewLayout!
    let cellId = "cellId"
    var personalInformation: [PersonalInformation] = [] { didSet {
        if collectionView != nil {
            collectionView.reloadData()
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let visit = DataStoreService.shared.getVisit(for: "dummy-visit", ctxt: nil)
        if let place = visit?.place {
            personalInformation = place.getOrderedPersonalInformation()
        }
    }
    
    override func viewWillLayoutSubviews() {
        if flowLayout == nil {
            setupViews()
        }
    }
    
    private func setupViews() {
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        flowLayout.xCellFrameScaling = 0.85
        flowLayout.yCellFrameScaling = 0.85
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // register cell type
        collectionView.register(PersonalInformationCell.self, forCellWithReuseIdentifier: cellId)
        
        // lay out the collection view
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        view.addSubview(bottomView)
        view.addVisualConstraint("H:|[v0]|", views: ["v0": bottomView])
        view.addVisualConstraint("H:|[v0]|", views: ["v0": containerView])
        view.addVisualConstraint("V:|[container][v0(120)]|", views: ["v0": bottomView, "container": containerView])
        
        containerView.addSubview(collectionView)
        containerView.addVisualConstraint("H:|[v0]|", views: ["v0": collectionView])
        containerView.addVisualConstraint("V:|[v0]|", views: ["v0": collectionView])
        
        collectionView.layoutIfNeeded()
        
        // Setup collection view bounds
        let collectionViewFrame = collectionView.frame
        
        flowLayout.cellWidth = floor(collectionViewFrame.width * flowLayout.xCellFrameScaling)
        flowLayout.cellHeight = min(250, floor(collectionViewFrame.height * flowLayout.yCellFrameScaling))
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - flowLayout.cellHeight) / 2.0)
        
//        print("collectionViewFrame: \(collectionViewFrame), cellWidth: \(flowLayout.cellWidth), cellHeight: \(flowLayout.cellHeight), insetX: \(insetX), insetY: \(insetY)")
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.isPagingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        
        if personalInformation.count > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    // MARK: - CollectionView delegate methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return personalInformation.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationCell
        
        cell.color = Constants.colors.midPurple // color must be declared before the personal information
        cell.personalInformation = personalInformation[indexPath.item]
        cell.indexPath = indexPath
        cell.delegate = self
        return cell
    }
    
    func didPressPersonalInformationReview(personalInformation: PersonalInformation?, answer: FeedbackType, indexPath: IndexPath?) {
        print("pressed personal information review")
        personalInformation?.rating = 3
        
        if let indexPath = indexPath {
            let piCount = self.personalInformation.count
            if piCount > indexPath.item + 1 {
                collectionView.scrollToItem(at: IndexPath(item: indexPath.item+1,
                                                          section:indexPath.section),
                                            at: .centeredHorizontally, animated: true)
            } else {
                // remove all the subviews from the container view
                containerView.subviews.forEach({ $0.removeFromSuperview() })
                
                // setup the text
                let label = UILabel()
                label.text = "Thank you for reviewing the personal information"
                label.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
                label.textColor = Constants.colors.midPurple
                label.textAlignment = .center
                label.numberOfLines = 2
                label.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(label)
                containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": label])
                containerView.addVisualConstraint("V:|-14-[v0]-14-|", views: ["v0": label])
                
                UIView.transition(with: bottomLabel, duration: 0.25, options: .transitionCrossDissolve, animations: { [weak self] in
                    let formattedString = NSMutableAttributedString()
                    formattedString.normal("Perfect! Now, we can aggregate this personal information with the those that you have already reviewed for other places.", of: 14)
                    self?.bottomLabel.attributedText = formattedString

                    }, completion: { [weak self] _  in
                        self?.parentView?.isButtonEnabled = true
                })
            }
        }
    }
}

class TutorialAPIReviewsViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PersonalInformationReviewCellDelegate {
    
    var parentView: TutorialOverlayView? {
        didSet {
            parentView?.buttonText = "Next"
            parentView?.titleText = "Personal information review"
            parentView?.subtitleText = ""
            parentView?.isButtonEnabled = false
        }
    }
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.colors.lightGray
        
        view.addSubview(bottomLabel)
        view.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": bottomLabel])
        view.addVisualConstraint("V:|-[v0]-|", views: ["v0": bottomLabel])
        return view
    }()
    
    lazy var bottomLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 6
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .light)
        label.textColor = .black
        let formattedString = NSMutableAttributedString()
        formattedString
            .normal("We aggregate the information associated to ", of: 14)
            .bold("Bilbo's", of: 14)
            .normal(" that you have reviewed with information from other places that you visited.", of: 14)
            .italic(" We ask you to review the relevance of the information with yourself", of: 14)
        label.attributedText = formattedString
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var containerView: UIView!
    var collectionView : UICollectionView!
    var flowLayout: PlaceReviewLayout!
    let cellId = "cellId"
    var personalInformation: [AggregatedPersonalInformation] = [] { didSet {
        if collectionView != nil {
            collectionView.reloadData()
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        if let api = DataStoreService.shared.getAggregatePersonalInformation(with: "dummy-api-1", ctxt: nil) {
            personalInformation.append(api)
        }
        if let api = DataStoreService.shared.getAggregatePersonalInformation(with: "dummy-api-2", ctxt: nil) {
            personalInformation.append(api)
        }
        if let api = DataStoreService.shared.getAggregatePersonalInformation(with: "dummy-api-3", ctxt: nil) {
            personalInformation.append(api)
        }
    }
    
    override func viewWillLayoutSubviews() {
        if flowLayout == nil {
            setupViews()
        }
    }
    
    private func setupViews() {
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        flowLayout.xCellFrameScaling = 0.96
        flowLayout.yCellFrameScaling = 1.0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // register cell type
        collectionView.register(PersonalInformationReviewCell.self, forCellWithReuseIdentifier: cellId)
        
        // lay out the collection view
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        view.addSubview(bottomView)
        view.addVisualConstraint("H:|[v0]|", views: ["v0": bottomView])
        view.addVisualConstraint("H:|[v0]|", views: ["v0": containerView])
        view.addVisualConstraint("V:|-[container]-[v0(120)]|", views: ["v0": bottomView, "container": containerView])
        
        containerView.addSubview(collectionView)
        containerView.addVisualConstraint("H:|[v0]|", views: ["v0": collectionView])
        containerView.addVisualConstraint("V:|[v0]|", views: ["v0": collectionView])
        
        containerView.layoutIfNeeded()
        
        // Setup collection view bounds
        let collectionViewFrame = collectionView.frame
        print("collectionViewFrame: \(collectionViewFrame)")
        
        flowLayout.cellWidth = floor(collectionViewFrame.width * flowLayout.xCellFrameScaling)
        flowLayout.cellHeight = min(250,floor(collectionViewFrame.height * flowLayout.yCellFrameScaling))
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - flowLayout.cellHeight) / 2.0)
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.isPagingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        
        if personalInformation.count > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    // MARK: - CollectionView delegate methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return personalInformation.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationReviewCell
        
        cell.personalInformation = personalInformation[indexPath.item]
        cell.color = Constants.colors.orange
        cell.indexPath = indexPath
        cell.lastPI = indexPath.item+1 == personalInformation.count
        cell.delegate = self
        return cell
    }
    
    // PersonalInformationReviewCellDelegate methods
    func didReviewPersonalInformation(personalInformation: AggregatedPersonalInformation?, type: ReviewType, rating: Int32, indexPath: IndexPath?) {
        print("gave review")
    }
        
    func didTapHeader(for personalInformation: AggregatedPersonalInformation, indexPath: IndexPath?) { }
    
    func didTapNextPersonalInformationButton(currentPersonalInformation: AggregatedPersonalInformation?, indexPath: IndexPath?) {
        
        if let indexPath = indexPath {
            let piCount = self.personalInformation.count
            
            // scroll to next item
            if piCount > indexPath.item + 1 {
                collectionView.scrollToItem(at: IndexPath(item: indexPath.item+1, section:indexPath.section), at: .centeredHorizontally, animated: true)
            } else {
                // remove all the subviews from the container view
                containerView.subviews.forEach({ $0.removeFromSuperview() })
                
                // setup the text
                let label = UILabel()
                label.text = "Thank you for reviewing the personal information"
                label.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
                label.textColor = Constants.colors.orange
                label.textAlignment = .center
                label.numberOfLines = 2
                label.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(label)
                
                // setup the next place button
                containerView.addVisualConstraint("H:|-14-[v0]-14-|", views: ["v0": label])
                containerView.addVisualConstraint("V:|-14-[v0]-14-|", views: ["v0": label])
                
                UIView.transition(with: bottomLabel, duration: 0.25, options: .transitionCrossDissolve, animations: { [weak self] in
                    let formattedString = NSMutableAttributedString()
                    formattedString.normal("Awesome! Now, we have ground truth about the relevance of the personal information we automatically inferred about you.", of: 14)
                    self?.bottomLabel.attributedText = formattedString
                    }, completion: { [weak self] _  in
                        self?.parentView?.isButtonEnabled = true
                })
            }
        }
    }

}

class TutorialEndViewController : UIViewController {
    
    var parentView: TutorialOverlayView? {
        didSet {
            parentView?.buttonText = "Finish"
            parentView?.titleText = ""
            parentView?.subtitleText = ""
            parentView?.showHeaderShadow = false
        }
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "Thank you!"
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .light)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Hopefully this walkthrough has helped you understand how to give useful feedback. We will send you daily notifications to remind you to give us the feedback we need. Thank you again for participating in the study!"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.colors.midPurple
        
        setupViews()
    }
    
    private func setupViews() {
        let vStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        vStackView.alignment = .center
        vStackView.axis = .vertical
        vStackView.distribution = .fillProportionally
        vStackView.spacing = 10
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vStackView)
        
        view.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": vStackView])
        vStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}



