//
//  ReviewsViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/3/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

class ReviewsViewController: UIViewController, UIScrollViewDelegate, VisitsTimelineViewDelegate {
    // set a content view inside the scroll view
    // From https://developer.apple.com/library/content/technotes/tn2154/_index.html

    var fullScreenView: FullScreenView?
    
    var numberOfPlacesToReview: Int?
    var numberOfPersonalInformationToReview: Int?
    
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
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var yourVisitsTitle: UILabel = {
        let label = UILabel()
        label.text = "Your visits"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var yourVisitsSubTitle: UILabel = {
        let label = UILabel()
        label.text = "You can find below a summary of your daily visits."
        label.numberOfLines = 2
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.textColor = Constants.colors.descriptionColor
        if AppDelegate.isIPhone5() {
            label.font = UIFont.italicSystemFont(ofSize: 12)
        } else {
            label.font = UIFont.italicSystemFont(ofSize: 14)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var visitsTimeline: VisitsTimelineView = {
        print("visitsTimeline")
        let timeline = VisitsTimelineView()
        timeline.delegate = self
        return timeline
    }()
    
    var yourReviewsTitle: UILabel = {
        let label = UILabel()
        label.text = "Your reviews"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var yourReviewsSubTitle: UILabel = {
        let label = UILabel()
        label.text = "You can find below a summary of the different reviews."
        label.numberOfLines = 2
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.textColor = Constants.colors.descriptionColor
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var visitsReviewProgress: ReviewProgressBar = {
        print("visitsReviewProgress")
        let pb = ReviewProgressBar()
        pb.color = Constants.colors.primaryDark
        pb.filled = UserStats.shared.numberOfVisitsConfirmed
        pb.empty = UserStats.shared.numberOfVisitsToConfirm
        pb.total = UserStats.shared.numberOfVisitsToConfirm + UserStats.shared.numberOfVisitsConfirmed
        pb.name = "Visit confirmations"
        if UserStats.shared.totNumberOfVisits == 0 {
            pb.desc = "You have no visits to confirm yet."
        } else if UserStats.shared.numberOfVisitsToConfirm == 0 {
            pb.desc = "You have confirmed all the visits!"
        } else if UserStats.shared.numberOfVisitsToConfirm < 2 {
            pb.desc = "You have one visit to confirm."
        } else {
            pb.desc = "You have \(UserStats.shared.numberOfVisitsToConfirm) visits to confirm."
        }
        pb.translatesAutoresizingMaskIntoConstraints = false
        return pb
    }()

    lazy var placesReviewProgress: ReviewProgressBar = {
        print("instanciate placesReviewProgress")
        let pb = ReviewProgressBar()
        pb.color = Constants.colors.midPurple
        pb.filled = UserStats.shared.numberOfPlacePersonalInformationReviewed
        pb.empty = UserStats.shared.numberOfPlacePersonalInformationToReview
        pb.total = UserStats.shared.numberOfPlacePersonalInformationReviewed + UserStats.shared.numberOfPlacePersonalInformationToReview
        pb.name = "Place reviews"
        print("number of places to review: \(UserStats.shared.numberOfPlacePersonalInformationToReview)")
        if UserStats.shared.totNumberOfPlacePersonalInformation == 0 {
            pb.desc = "You no places to review yet."
        } else if UserStats.shared.numberOfPlacePersonalInformationToReview == 0 {
            pb.desc = "You have reviewed all the places!"
        } else if UserStats.shared.numberOfPlacePersonalInformationToReview == 1 {
            pb.desc = "You have one place to review."
        } else {
            pb.desc = "You have \(UserStats.shared.numberOfPlacePersonalInformationToReview) places to review."
        }
        pb.translatesAutoresizingMaskIntoConstraints = false
        return pb
    }()
    
    var placesReviewActionLabel: UILabel = {
        let label = UILabel()
        if UserStats.shared.numberOfPlacePersonalInformationToReview > 0 {
            let placeStr = UserStats.shared.numberOfPlacePersonalInformationToReview > 0 ? "places" : "place"
            label.text = "Go review the \(placeStr) ‣"
        } else {
            label.text = ""
        }
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .black)
        label.textColor = Constants.colors.darkRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var apiReviewProgress: ReviewProgressBar = {
        print("apiReviewProgress")
        let pb = ReviewProgressBar()
        pb.color = Constants.colors.orange
        pb.filled = UserStats.shared.numberOfAggregatedPersonalInformationReviewed
        pb.empty = UserStats.shared.numberOfAggregatedPersonalInformationToReview
        pb.total = UserStats.shared.totNumberOfAggregatedPersonalInformation
        pb.name = "Personal information reviews"
        if UserStats.shared.totNumberOfAggregatedPersonalInformation == 0 {
            pb.desc = "You have no information to review yet."
        } else if UserStats.shared.numberOfAggregatedPersonalInformationToReview == 0 {
            pb.desc = "You have reviewed all the information!"
        } else if UserStats.shared.numberOfAggregatedPersonalInformationToReview == 1 {
            pb.desc = "You have one information to review."
        } else {
            pb.desc = "You have \(UserStats.shared.numberOfAggregatedPersonalInformationToReview) information to review."
        }
        pb.translatesAutoresizingMaskIntoConstraints = false
        print("apiReviewProgress - end")
        return pb
    }()
    
    var apiReviewActionLabel: UILabel = {
        let label = UILabel()
        if UserStats.shared.numberOfVisitsToConfirm > 0 {
            label.text = "Go review the information ‣"
        } else {
            label.text = ""
        }
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 16.0, weight: .black)
        label.textColor = Constants.colors.darkRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        LogService.shared.log(LogService.types.tabReviews)
        
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        let days = DataStoreService.shared.getUniqueVisitDays(ctxt: nil)
        if days.count > 0 {
            computeData()
        }
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
        
        contentView.addSubview(yourVisitsTitle)
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": yourVisitsTitle])
        
        contentView.addSubview(yourVisitsSubTitle)
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": yourVisitsSubTitle])
        
        contentView.addSubview(yourReviewsTitle)
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": yourReviewsTitle])
        
        contentView.addSubview(yourReviewsSubTitle)
        contentView.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": yourReviewsSubTitle])
        
        contentView.addSubview(visitsReviewProgress)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": visitsReviewProgress])
        
        contentView.addSubview(placesReviewProgress)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": placesReviewProgress])
        
        contentView.addSubview(placesReviewActionLabel)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": placesReviewActionLabel])
        
        contentView.addSubview(apiReviewProgress)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": apiReviewProgress])
        
        contentView.addSubview(apiReviewActionLabel)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": apiReviewActionLabel])
        
        contentView.addSubview(dividerLineView)
        contentView.addVisualConstraint("H:|-16-[v0]-16-|", views: ["v0": dividerLineView])
        
        contentView.addSubview(visitsTimeline)
        contentView.addVisualConstraint("H:|[v0]|", views: ["v0": visitsTimeline])
        
        contentView.addVisualConstraint("V:|-48-[title(40)]-16-[vt][vst][visits(160)]-16-[line(0.5)]-16-[rt][rst]-16-[visitProgress(90)]-25-[placeProgress(90)][placeAction]-25-[apiProgress(90)][apiAction]-25-|", views: ["title": mainTitle, "vt": yourVisitsTitle, "vst": yourVisitsSubTitle, "visits": visitsTimeline, "line": dividerLineView, "rt": yourReviewsTitle, "rst": yourReviewsSubTitle, "visitProgress": visitsReviewProgress, "placeProgress": placesReviewProgress, "placeAction": placesReviewActionLabel, "apiProgress": apiReviewProgress, "apiAction": apiReviewActionLabel])
        
        
        // Add tap gestures
        placesReviewActionLabel.addTapGestureRecognizer { [unowned self] in
            let viewController = PlacePersonalInformationReviewViewController()
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        
        apiReviewActionLabel.addTapGestureRecognizer { [unowned self] in
            let viewController = PersonalInformationReviewViewController()
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func computeData() {
        // visitsReviewProgress
        visitsReviewProgress.filled = UserStats.shared.numberOfVisitsConfirmed
        visitsReviewProgress.empty = UserStats.shared.numberOfVisitsToConfirm
        visitsReviewProgress.total = UserStats.shared.numberOfVisitsToConfirm + UserStats.shared.numberOfVisitsConfirmed
        visitsReviewProgress.name = "Visit confirmations"
        if UserStats.shared.totNumberOfVisits == 0 {
            visitsReviewProgress.desc = "You have no visits to confirm yet."
        } else if UserStats.shared.numberOfVisitsToConfirm == 0 {
            visitsReviewProgress.desc = "You have confirmed all the visits!"
        } else if UserStats.shared.numberOfVisitsToConfirm < 2 {
            visitsReviewProgress.desc = "You have one visit to confirm."
        } else {
            visitsReviewProgress.desc = "You have \(UserStats.shared.numberOfVisitsToConfirm) visits to confirm."
        }
        
        // placesReviewProgress
        placesReviewProgress.filled = UserStats.shared.numberOfPlacePersonalInformationReviewed
        placesReviewProgress.empty = UserStats.shared.numberOfPlacePersonalInformationToReview
        placesReviewProgress.total = UserStats.shared.numberOfPlacePersonalInformationReviewed + UserStats.shared.numberOfPlacePersonalInformationToReview
        
        placesReviewProgress.name = "Place reviews"
        if UserStats.shared.totNumberOfPlacePersonalInformation == 0 {
            placesReviewProgress.desc = "You have no places to review yet."
        } else if UserStats.shared.numberOfPlacePersonalInformationToReview == 0 {
            placesReviewProgress.desc = "You have reviewed all the places!"
        } else if UserStats.shared.numberOfPlacePersonalInformationToReview == 1 {
            placesReviewProgress.desc = "You have one place to review."
        } else {
            placesReviewProgress.desc = "You have \(UserStats.shared.numberOfPlacePersonalInformationToReview) places to review."
        }
        
        // apiReviewProgress
        apiReviewProgress.filled = UserStats.shared.numberOfAggregatedPersonalInformationReviewed
        apiReviewProgress.empty = UserStats.shared.numberOfAggregatedPersonalInformationToReview
        apiReviewProgress.total = UserStats.shared.totNumberOfAggregatedPersonalInformation
        apiReviewProgress.name = "Personal information reviews"
        if UserStats.shared.numberOfAggregatedPersonalInformationToReview == 0 {
            apiReviewProgress.desc = "You have no information to review yet."
        } else if UserStats.shared.numberOfAggregatedPersonalInformationToReview == 0 {
            apiReviewProgress.desc = "You have reviewed all the information!"
        } else if UserStats.shared.numberOfAggregatedPersonalInformationToReview == 1 {
            apiReviewProgress.desc = "You have one information to review."
        } else {
            apiReviewProgress.desc = "You have \(UserStats.shared.numberOfAggregatedPersonalInformationToReview) information to review."
        }
        
        // Action labels
        numberOfPlacesToReview = UserStats.shared.numberOfPlacePersonalInformationToReview
        if numberOfPlacesToReview! > 0 {
            let placeStr = numberOfPlacesToReview! > 1 ? "places" : "place"
            placesReviewActionLabel.text = "Go review the \(placeStr) ‣"
        } else {
            placesReviewActionLabel.text = ""
        }
        numberOfPersonalInformationToReview = UserStats.shared.numberOfAggregatedPersonalInformationToReview
        if numberOfPersonalInformationToReview! > 0 {
            apiReviewActionLabel.text = "Go review the information ‣"
        } else {
            apiReviewActionLabel.text = ""
        }
        
        // update the layouts
        visitsTimeline.layoutIfNeeded()
        visitsReviewProgress.layoutSubviews()
        placesReviewProgress.layoutSubviews()
        apiReviewProgress.layoutSubviews()
    }
    
    // MARK: - VisitsTimelineViewDelegate method
    func selectedDate(day: String) {
        print("selected day: \(day)")
    }
}
