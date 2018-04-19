//
//  ReviewsViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/3/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

class ReviewsViewController: UIViewController, UIScrollViewDelegate {
    // set a content view inside the scroll view
    // From https://developer.apple.com/library/content/technotes/tn2154/_index.html

    
    var fullScreenView: FullScreenView?
    
    var numberOfPlacesToReview: Int? { didSet {
        if numberOfPlacesToReview! > 0 {
            placesToReviewButton.setTitle("Review places", for: .normal)
            placesToReviewButton.subviews.first?.backgroundColor = Constants.colors.midPurple
            placesToReviewButton.layoutIfNeeded()
            print("set badge")
            placesToReviewButton.badge = "\(numberOfPlacesToReview!)"
        } else {
            placesToReviewButton.subviews.first?.backgroundColor = Constants.colors.midPurple.withAlphaComponent(0.5)
            placesToReviewButton.setTitle("No places to review", for: .normal)
            placesToReviewButton.badge = nil
        }
    }}
    
    var numberOfPlacesReviewed: Int? { didSet {
         placeReviewsSummary.bigText.bigText = String(numberOfPlacesReviewed!)
        
        if numberOfPlacesReviewed! < 2 {
            placeReviewsSummary.bigText.smallBottomText = "PLACE"
            if numberOfPlacesReviewed! < 1 {
                placeReviewsSummary.descriptionText = "You haven't reviewed any places yet."
            } else {
                placeReviewsSummary.descriptionText = "You have reviewed one place."
            }
        } else {
            placeReviewsSummary.bigText.smallBottomText = "PLACES"
            placeReviewsSummary.descriptionText = "You have reviewed \(numberOfPlacesReviewed!) places. You are doing great!"
        }
    }}
    
    var numberOfPersonalInformationToReview: Int? { didSet {
        if numberOfPersonalInformationToReview! > 0 {
            personalInformationToReviewButton.setTitle("Review\npersonal information", for: .normal)
            personalInformationToReviewButton.subviews.first?.backgroundColor = Constants.colors.orange
            personalInformationToReviewButton.layoutIfNeeded()
            personalInformationToReviewButton.badge = "\(numberOfPersonalInformationToReview!)"
        } else {
            personalInformationToReviewButton.setTitle("No personal information\nto review", for: .normal)
            personalInformationToReviewButton.subviews.first?.backgroundColor = Constants.colors.orange.withAlphaComponent(0.5)
            personalInformationToReviewButton.badge = nil
        }
    }}
    
    var numberOfPersonalInformationReviewed: Int? { didSet {
        personalInformationReviewsSummary.bigText.bigText = String(numberOfPersonalInformationReviewed!)
        
        if numberOfPersonalInformationReviewed! < 2 {
            if numberOfPersonalInformationReviewed! < 1 {
                personalInformationReviewsSummary.descriptionText = "You haven't reviewed any personal information item yet."
            } else {
                personalInformationReviewsSummary.descriptionText = "You have reviewed one personal information item."
            }
        } else {
            
            personalInformationReviewsSummary.descriptionText = "So far, you have reviewed \(numberOfPersonalInformationReviewed!) personal information items."
        }
    }}
    
    var scrollView : UIScrollView!
    var contentView : UIView!
    
    var mainTitle: UILabel = {
        let label = UILabel()
        label.text = "Reviews"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var placesToReviewButton: BadgeButton = {
        let l = BadgeButton(type: .system)
        l.setTitle("You have places to review", for: .normal)
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.numberOfLines = 2
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.setTitleColor(.white, for: .normal)
        l.badge = nil
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedPlacesToReview), for: .touchUpInside)
        
        let view = UIView()
        view.layer.cornerRadius = 5.0
        view.layer.masksToBounds = true
        view.backgroundColor = Constants.colors.midPurple
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.isExclusiveTouch = false
        
        l.addSubview(view)
        l.sendSubview(toBack: view)
        l.addVisualConstraint("H:|[v0]|", views: ["v0": view])
        l.addVisualConstraint("V:|[v0]|", views: ["v0": view])

        return l
    }()
    
    @objc fileprivate func tappedPlacesToReview() {
        print("tappedPlacesToReview")
        if numberOfPlacesToReview != nil && numberOfPlacesToReview! > 0 {
            let viewController = PlacePersonalInformationReviewViewController()
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private lazy var personalInformationToReviewButton: BadgeButton = {
        let l = BadgeButton(type: .system)
        l.setTitle("You have personal information to review", for: .normal)
        l.titleLabel?.textAlignment = .center
        l.titleLabel?.numberOfLines = 2
        l.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
        l.setTitleColor(.white, for: .normal)
        l.badge = nil
        l.translatesAutoresizingMaskIntoConstraints = false
        l.addTarget(self, action: #selector(tappedPersonalInformationToReview), for: .touchUpInside)
        
        let view = UIView()
        view.layer.cornerRadius = 5.0
        view.layer.masksToBounds = true
        view.backgroundColor = Constants.colors.orange
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.isExclusiveTouch = false
        
        l.addSubview(view)
        l.sendSubview(toBack: view)
        l.addVisualConstraint("H:|[v0]|", views: ["v0": view])
        l.addVisualConstraint("V:|[v0]|", views: ["v0": view])
        return l
    }()
    
    @objc fileprivate func tappedPersonalInformationToReview() {
        if numberOfPersonalInformationToReview != nil && numberOfPersonalInformationToReview! > 0 {
            let viewController = PersonalInformationReviewViewController()
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var yourReviewsTitle: UILabel = {
        let label = UILabel()
        label.text = "Your reviews"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var placeReviewsSummary: InfoCardView = {
        return InfoCardView(bigText: BigText(bigText: "XX", topExponent: "", smallBottomText: "PLACES"),
                            descriptionText: "You have reviewed XX places!")
    }()
    
    lazy var personalInformationReviewsSummary: InfoCardView = {
        return InfoCardView(bigText: BigText(bigText: "XX", topExponent: "", smallBottomText: "INFO"),
                            descriptionText: "You have reviewed XX personal information items!")
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LogService.shared.log(LogService.types.tabReviews)
        
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        computeData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let days = DataStoreService.shared.getUniqueVisitDays(ctxt: nil)
        if days.count == 0 {
            fullScreenView = FullScreenView(frame: view.frame)
            fullScreenView!.icon = "rocket"
            fullScreenView!.iconColor = Constants.colors.primaryLight
            fullScreenView!.headerTitle = "Reviews"
            fullScreenView!.subheaderTitle = "After moving to a few places, we will ask you to review the personal information we have inferred from the places you visited."
            view.addSubview(fullScreenView!)
        } else {
            fullScreenView?.removeFromSuperview()
            setupViews()
            
            // update with the latest aggregated personal information
            UserUpdateHandler.retrieveLatestAggregatedPersonalInformation { [weak self] in
                print("retrieved latest aggregated personal information")
                self?.computeData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupViews() {
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
        
        contentView.addSubview(mainTitle)
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        
        contentView.addSubview(placeReviewsSummary)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": placeReviewsSummary])
        
        contentView.addSubview(personalInformationReviewsSummary)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": personalInformationReviewsSummary])
        
        contentView.addSubview(dividerLineView)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": dividerLineView])
        
        contentView.addSubview(yourReviewsTitle)
        
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": yourReviewsTitle])
        
        contentView.addSubview(placesToReviewButton)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": placesToReviewButton])
        
        contentView.addSubview(personalInformationToReviewButton)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": personalInformationToReviewButton])
        
        contentView.addVisualConstraint("V:|-48-[title(40)]-16-[statsPlaces]-16-[statsPI]-16-[line(0.5)]-16-[subtitle]-16-[placesBtn(64)]-16-[piBtn(64)]-16-|", views: ["title": mainTitle, "statsPlaces": placeReviewsSummary, "statsPI": personalInformationReviewsSummary, "line": dividerLineView, "subtitle": yourReviewsTitle, "placesBtn": placesToReviewButton, "piBtn": personalInformationToReviewButton])
    }
    
    func computeData() {
        let placesReviewed = DataStoreService.shared.getAllPlacesReviewed(ctxt: nil)
        let placesToReview = DataStoreService.shared.getAllPlacesToReview(ctxt: nil)

        numberOfPlacesReviewed = placesReviewed.count
        numberOfPlacesToReview = placesToReview.count
        
        let personalInformationReviewed = DataStoreService.shared.getAggregatedPersonalInformationReviewed(ctxt: nil)
        let personalInformationToReview = DataStoreService.shared.getAggregatedPersonalInformationToReview(ctxt: nil)
        
        numberOfPersonalInformationReviewed = personalInformationReviewed.count
        numberOfPersonalInformationToReview = personalInformationToReview.count        
    }
}
