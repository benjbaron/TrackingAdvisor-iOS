//
//  ProfileViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/22/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

protocol PlaceReviewCellDelegate {
    func didEndPlaceReview()
}

class PlaceReviewViewController: UIViewController, UICollectionViewDataSource, PlaceReviewCellDelegate{
    
    @IBOutlet weak var collectionView: UICollectionView!
    var mainTitle: UILabel = {
        let label = UILabel()
        label.text = "Places to review"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var flowLayout: PlaceReviewLayout!
    
    let placeReviews = PlaceReview.getSamplePlaceReviews()
    let cellId = "PlaceReviewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tabItems = self.tabBarController?.tabBar.items as NSArray! {
            let tabItem = tabItems[1] as! UITabBarItem
            tabItem.badgeValue = "3"
        }
        
        collectionView.dataSource = self
        flowLayout = collectionView.collectionViewLayout as! PlaceReviewLayout
        
        view.addSubview(mainTitle)
        view.addVisualConstraint("H:|-16-[v0]-|", views: ["v0": mainTitle])
        view.addVisualConstraint("V:|-48-[v0(40)]", views: ["v0": mainTitle])
        
        let collectionViewBounds = collectionView.bounds
        flowLayout.cellWidth = floor(collectionViewBounds.width * flowLayout.xCellFrameScaling)
        flowLayout.cellHeight = floor(collectionViewBounds.height * flowLayout.yCellFrameScaling)
        
        let insetX = floor((collectionViewBounds.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewBounds.height - flowLayout.cellHeight) / 2.0)
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = insetX - 25.0 // to show the next cell
        flowLayout.minimumLineSpacing = insetX - 25 // to show the next cell
        collectionView.isPagingEnabled = false
        
        collectionView.contentInset = UIEdgeInsets(top: insetY - 10.0, left: insetX, bottom: insetY + 10.0, right: insetX)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UICollectionViewDataSource deleagte methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeReviews.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PlaceReviewCell
        
        cell.delegate = self
        cell.parent = collectionView
        cell.indexPath = indexPath
        cell.last = indexPath.item + 1 == collectionView.numberOfItems(inSection: indexPath.section)
        cell.placeReview = placeReviews[indexPath.item]
        cell.answerQuestionPlace = placeReviews[indexPath.item].answerQuestionPlace
        cell.answerQuestionPersonalInformation = placeReviews[indexPath.item].answerQuestionPersonalInformation
        cell.answerQuestionExplanation = placeReviews[indexPath.item].answerQuestionExplanation
        cell.answerQuestionPrivacy = placeReviews[indexPath.item].answerQuestionPrivacy
        
        return cell
    }
    
    // MARK: - PlaceReviewCellDelegate methods
    func didEndPlaceReview() {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            // hide the collection view
            self?.collectionView.alpha = 0
            self?.mainTitle.alpha = 0
        }, completion: { [weak self] success in
            print("finished animation! with \(success)")
            if success {
                guard let strongSelf = self else { return }
                // show text in the center of the collection view
                let headerImage: UIImageView = {
                    let imageView = UIImageView(image: UIImage(named: "galaxy")!.withRenderingMode(.alwaysTemplate))
                    imageView.tintColor = Constants.colors.primaryLight
                    imageView.contentMode = .scaleAspectFit
                    return imageView
                }()
                
                let headerLabel: UILabel = {
                    let label = UILabel()
                    label.text = "You're all set!"
                    label.font = UIFont.boldSystemFont(ofSize: 40.0)
                    label.textColor = Constants.colors.primaryDark
                    label.textAlignment = .center
                    label.sizeToFit()
                    return label
                }()
                
                let textLabel: UILabel = {
                    let label = UILabel()
                    label.text = "Thank you for reviewing the places"
                    label.font = UIFont.boldSystemFont(ofSize: 18.0)
                    label.textColor = Constants.colors.primaryLight
                    label.textAlignment = .center
                    label.sizeToFit()
                    return label
                }()
                
                headerImage.frame = CGRect(x: strongSelf.view.center.x - 150, y: strongSelf.view.center.y - 200, width: 300, height: 300)
                headerLabel.center = CGPoint(x: strongSelf.view.center.x, y: strongSelf.view.center.y + 120)
                textLabel.center = CGPoint(x: strongSelf.view.center.x, y: strongSelf.view.center.y + 160)
                
                strongSelf.view.addSubview(headerImage)
                strongSelf.view.addSubview(headerLabel)
                strongSelf.view.addSubview(textLabel)
            }
        })
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

class PlaceReview {
    var backgroundColor: UIColor = .clear
    var placeName: String = ""
    var placeAddress: String = ""
    var placePersonalInformation: String = ""
    var answerQuestionPlace: QuestionAnswer = .none
    var answerQuestionPersonalInformation: QuestionAnswer = .none
    var answerQuestionExplanation: QuestionAnswer = .none
    var answerQuestionPrivacy: QuestionAnswer = .none
    
    init(backgroundColor: UIColor, placeName: String, placeAddress: String, placePersonalInformation: String) {
        self.backgroundColor = backgroundColor
        self.placeName = placeName
        self.placeAddress = placeAddress
        self.placePersonalInformation = placePersonalInformation
    }
    
    class func getSamplePlaceReviews() -> [PlaceReview] {
        let placeReviews = [
            PlaceReview(backgroundColor: Constants.colors.darkRed, placeName: "UCL", placeAddress: "Gower St", placePersonalInformation: "Occupation"),
            PlaceReview(backgroundColor: .orange, placeName: "Tap No 114", placeAddress: "Tottenam Court Road", placePersonalInformation: "Activity, Interest, Social status"),
            PlaceReview(backgroundColor: .blue, placeName: "Stick'n'Sushi", placeAddress: "Henrietta St", placePersonalInformation: "Activity, Interest, Social status"),
            PlaceReview(backgroundColor: .red, placeName: "Subway", placeAddress: "Tottenam Court Road", placePersonalInformation: "Activity"),
            PlaceReview(backgroundColor: .purple, placeName: "Google", placeAddress: "St Pancras Sq", placePersonalInformation: "Occupation, Social status"),
            PlaceReview(backgroundColor: .gray, placeName: "Euston Station", placeAddress: "Euston Road", placePersonalInformation: "Activity")
        ]
        return placeReviews
    }
}

class PlaceReviewCell: UICollectionViewCell {
    weak var parent: UICollectionView?
    var delegate: PlaceReviewCellDelegate!

    var indexPath: IndexPath?
    var last: Bool = false
    
    lazy var headerView: HeaderRow = {
        return HeaderRow()
    }()
    
    lazy var questionPlaceView: QuestionRow = {
        return QuestionRow(with: "Did you visit this place?", yesAction: { [weak self] in
            self?.answerQuestionPlace = .yes
        }, noAction: { [weak self] in
            self?.answerQuestionPlace = .no
        })
    }()
    
    var answerQuestionPlace: QuestionAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            placeReview?.answerQuestionPlace = answerQuestionPlace
            questionPlaceView.selected = answerQuestionPlace
            switch answerQuestionPlace {
            case .yes:
                UIView.animate(withDuration: 0.1) {
                    self.placeEditViewHeight?.constant = 0
                    self.placeEditViewTopMargin?.constant = 0
                    self.questionPersonalInformationViewHeight?.constant = 40
                    self.questionPersonalInformationViewTopMargin?.constant = 8
                    self.questionExplanationViewHeight?.constant = 40
                    self.questionExplanationViewTopMargin?.constant = 8
                    self.questionPrivacyViewHeight?.constant = 40
                    self.questionPrivacyViewTopMargin?.constant = 8
                    self.layoutIfNeeded()
                }
            case .no:
                answerQuestionPersonalInformation = .none
                answerQuestionPrivacy = .none
                answerQuestionExplanation = .none
                UIView.animate(withDuration: 0.1) {
                    self.placeEditViewHeight?.constant = 40
                    self.placeEditViewTopMargin?.constant = 8
                    self.questionPersonalInformationViewHeight?.constant = 0
                    self.questionPersonalInformationViewTopMargin?.constant = 0
                    self.questionExplanationViewHeight?.constant = 0
                    self.questionExplanationViewTopMargin?.constant = 0
                    self.questionPrivacyViewHeight?.constant = 0
                    self.questionPrivacyViewTopMargin?.constant = 0
                    self.layoutIfNeeded()
                }
            case .none:
                answerQuestionPersonalInformation = .none
                answerQuestionPrivacy = .none
                answerQuestionExplanation = .none
                
                self.placeEditViewHeight?.constant = 0
                self.placeEditViewTopMargin?.constant = 0
                self.questionPersonalInformationViewHeight?.constant = 0
                self.questionPersonalInformationViewTopMargin?.constant = 0
                self.questionExplanationViewHeight?.constant = 0
                self.questionExplanationViewTopMargin?.constant = 0
                self.questionPrivacyViewHeight?.constant = 0
                self.questionPrivacyViewTopMargin?.constant = 0
                self.layoutIfNeeded()
            }
        }
    }
    
    let placeEditView: CommentRow = {
        return CommentRow(with: "It would be great if you could tell us what place you visited", icon: "chevron-right", backgroundColor: UIColor.clear) {
            print("tapped on place edit")
        }
    }()
    var placeEditViewHeight: NSLayoutConstraint?
    var placeEditViewTopMargin: NSLayoutConstraint?
    
    lazy var questionPersonalInformationView: QuestionRow = {
        return QuestionRow(with: "Is the personal information correct?", yesAction: { [weak self] in
            self?.answerQuestionPersonalInformation = .yes
        }, noAction: { [weak self] in
            self?.answerQuestionPersonalInformation = .no
        })
    }()
    var questionPersonalInformationViewHeight: NSLayoutConstraint?
    var questionPersonalInformationViewTopMargin: NSLayoutConstraint?
    
    let personalInformationEditView: CommentRow = {
        return CommentRow(with: "It would be great if you could tell us the correct personal information", icon: "chevron-right", backgroundColor: UIColor.clear) {
            print("tapped on personal information edit")
        }
    }()
    var personalInformationViewHeight: NSLayoutConstraint?
    var personalInformationViewTopMargin: NSLayoutConstraint?

    var answerQuestionPersonalInformation: QuestionAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            placeReview?.answerQuestionPersonalInformation = answerQuestionPersonalInformation
            questionPersonalInformationView.selected = answerQuestionPersonalInformation
            switch answerQuestionPersonalInformation {
            case .yes:
                self.personalInformationViewHeight?.constant = 0
                self.personalInformationViewTopMargin?.constant = 0
            case .no:
                self.personalInformationViewHeight?.constant = 40
                self.personalInformationViewTopMargin?.constant = 8
            case .none:
                self.personalInformationViewHeight?.constant = 0
                self.personalInformationViewTopMargin?.constant = 0
            }
        }
    }
    
    lazy var questionExplanationView: QuestionRow = {
        return QuestionRow(with: "Is the explanation informative?", yesAction: { [weak self] in
            self?.answerQuestionExplanation = .yes
            }, noAction: { [weak self] in
                self?.answerQuestionExplanation = .no
        })
    }()
    var questionExplanationViewHeight: NSLayoutConstraint?
    var questionExplanationViewTopMargin: NSLayoutConstraint?
    
    var answerQuestionExplanation: QuestionAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            placeReview?.answerQuestionExplanation = answerQuestionExplanation
            questionExplanationView.selected = answerQuestionExplanation
        }
    }
    
    lazy var questionPrivacyView: QuestionRow = {
        return QuestionRow(with: "Is the inferred information sensitive to you?", yesAction: { [weak self] in
            self?.answerQuestionPrivacy = .yes
            }, noAction: { [weak self] in
                self?.answerQuestionPrivacy = .no
        })
    }()
    var questionPrivacyViewHeight: NSLayoutConstraint?
    var questionPrivacyViewTopMargin: NSLayoutConstraint?
    
    var answerQuestionPrivacy: QuestionAnswer = .none {
        didSet {
            checkIfEverythingIsAnswered()
            placeReview?.answerQuestionPrivacy = answerQuestionPrivacy
            questionPrivacyView.selected = answerQuestionPrivacy
        }
    }
    
    lazy var nextPlaceView: FooterRow = {
        var text = "Next place"
        return FooterRow(with: text, backgroundColor: Constants.colors.primaryDark) { [weak self] in
            guard let strongSelf = self else { return }
            if let indexPath = strongSelf.indexPath {
                if !strongSelf.last {
                    strongSelf.parent?.scrollToItem(at: IndexPath(item: indexPath.item+1, section:indexPath.section), at: .centeredHorizontally, animated: true)
                } else {
                    // the user has finished reviewing the places
                    strongSelf.delegate?.didEndPlaceReview()
                }
            }
        }
    }()
    
    func clearAllQuestions() {
        questionPlaceView.selected = .none
        questionPersonalInformationView.selected = .none
        questionExplanationView.selected = .none
        questionPrivacyView.selected = .none
    }
    
    var placeReview: PlaceReview? {
        didSet {
            self.updateUI()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func updateUI() {
        if let review = placeReview {
            self.headerView.placeName = review.placeName
            self.headerView.placeAddress = review.placeAddress
            self.headerView.placePersonalInformation = "This place gives personal information about \(review.placePersonalInformation)"
            self.headerView.backgroundColor = review.backgroundColor
            self.nextPlaceView.backgroundColor = review.backgroundColor.withAlphaComponent(0.5)
            self.nextPlaceView.text = last ? "Thank You!" : "Next place"
        } else {
            self.headerView.backgroundColor = .clear
            self.nextPlaceView.backgroundColor = Constants.colors.primaryDark
            self.headerView.placeName = ""
            self.headerView.placeAddress = ""
            self.headerView.placePersonalInformation = ""
            self.nextPlaceView.text = ""
        }
    }
    
    func setupViews() {
        addSubview(headerView)
        addSubview(questionPlaceView)
        addSubview(placeEditView)
        addSubview(questionPersonalInformationView)
        addSubview(personalInformationEditView)
        addSubview(questionExplanationView)
        addSubview(questionPrivacyView)
        addSubview(nextPlaceView)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0(150)]", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": headerView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": headerView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[header]-[v0(40)]", options: NSLayoutFormatOptions(), metrics: nil, views: ["header": headerView, "v0": questionPlaceView]))
        
        placeEditViewHeight = NSLayoutConstraint(item: placeEditView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        placeEditViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        placeEditViewHeight?.isActive = true
        
        placeEditViewTopMargin = NSLayoutConstraint(item: placeEditView, attribute: .top, relatedBy: .equal, toItem: questionPlaceView, attribute: .bottom, multiplier: 1, constant: 0)
        placeEditViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        placeEditViewTopMargin?.isActive = true
        
        questionPersonalInformationViewHeight = NSLayoutConstraint(item: questionPersonalInformationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        questionPersonalInformationViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        questionPersonalInformationViewHeight?.isActive = true
        
        questionPersonalInformationViewTopMargin = NSLayoutConstraint(item: questionPersonalInformationView, attribute: .top, relatedBy: .equal, toItem: placeEditView, attribute: .bottom, multiplier: 1, constant: 0)
        questionPersonalInformationViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        questionPersonalInformationViewTopMargin?.isActive = true
        
        personalInformationViewHeight = NSLayoutConstraint(item: personalInformationEditView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        personalInformationViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        personalInformationViewHeight?.isActive = true
        
        personalInformationViewTopMargin = NSLayoutConstraint(item: personalInformationEditView, attribute: .top, relatedBy: .equal, toItem: questionPersonalInformationView, attribute: .bottom, multiplier: 1, constant: 0)
        personalInformationViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        personalInformationViewTopMargin?.isActive = true

        questionExplanationViewHeight = NSLayoutConstraint(item: questionExplanationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        questionExplanationViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        questionExplanationViewHeight?.isActive = true
        
        questionExplanationViewTopMargin = NSLayoutConstraint(item: questionExplanationView, attribute: .top, relatedBy: .equal, toItem: personalInformationEditView, attribute: .bottom, multiplier: 1, constant: 0)
        questionExplanationViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        questionExplanationViewTopMargin?.isActive = true
        
        questionPrivacyViewHeight = NSLayoutConstraint(item: questionPrivacyView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        questionPrivacyViewHeight?.priority = UILayoutPriority(rawValue: 1000)
        questionPrivacyViewHeight?.isActive = true
        
        questionPrivacyViewTopMargin = NSLayoutConstraint(item: questionPrivacyView, attribute: .top, relatedBy: .equal, toItem: questionExplanationView, attribute: .bottom, multiplier: 1, constant: 0)
        questionPrivacyViewTopMargin?.priority = UILayoutPriority(rawValue: 1000)
        questionPrivacyViewTopMargin?.isActive = true

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionPlaceView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": placeEditView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionPersonalInformationView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": personalInformationEditView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionExplanationView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionPrivacyView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v0(50)]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nextPlaceView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": nextPlaceView]))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 3.0
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.layer.backgroundColor = Constants.colors.superLightGray.cgColor
        
        self.clipsToBounds = false
        self.layer.masksToBounds = true
    }
    
    func checkIfEverythingIsAnswered() {
        if (answerQuestionPlace == .no) ||
           (answerQuestionPlace == .yes && answerQuestionPersonalInformation != .none
         && answerQuestionExplanation != .none && answerQuestionPrivacy != .none) {
            nextPlaceView.text = last ? "You're done!" : "Next place"
        } else {
            nextPlaceView.text = last ? "Finish" : "Skip this place"
        }
    }
    
}

class PlaceReviewLayout: UICollectionViewFlowLayout {
    var cellWidth: CGFloat = 250
    var cellHeight: CGFloat = 400
    var xCellFrameScaling: CGFloat = 0.8
    var yCellFrameScaling: CGFloat = 0.95
    var cellScaling: CGFloat = 0.95
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        scrollDirection = .horizontal
        itemSize = CGSize(width: cellWidth, height: cellHeight)
        minimumInteritemSpacing = 10
        minimumLineSpacing = 10
    }
    
    override func prepare() {
        super.prepare()
        
        // rate at which we scroll the collection view
        collectionView?.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let array = super.layoutAttributesForElements(in: rect)!
        
        for attributes in array {
            let frame = attributes.frame
            let distance = abs(collectionView!.contentOffset.x + collectionView!.contentInset.left - frame.origin.x)
            let scale = cellScaling * min(max(1 - distance / (4 * collectionView!.bounds.width), cellScaling), 1)
            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        
        return array
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // forces to recalculate the attribtues every time the collection view's bounds changes
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }
        
        var newOffset = CGPoint()
        let width = itemSize.width + minimumLineSpacing
        
        var offset = proposedContentOffset.x + collectionView.contentInset.left
        
        if velocity.x > 0 {
            // user is scrolling to the right
            offset = width * ceil(offset / width)
        } else if velocity.x == 0 {
            // user did not scroll strongly enough
            offset = width * round(offset / width)
        } else if velocity.x < 0 {
            // user is scrolling to the left
            offset = width * floor(offset / width)
        }
        
        newOffset.x = offset - collectionView.contentInset.left
        newOffset.y = proposedContentOffset.y // does not change
        
        return newOffset
    }
}

enum QuestionAnswer {
    case yes
    case no
    case none
}

class QuestionRow : UIView {
    var question: String?
    var yesAction: (() -> ())?
    var noAction: (() -> ())?
    var yesView: UIView?
    var noView: UIView?
    var selected: QuestionAnswer = .none {
        didSet {
            switch selected {
            case .none:
                (yesView?.subviews[0] as! UIImageView).tintColor = Constants.colors.primaryLight
                (noView?.subviews[0] as! UIImageView).tintColor = Constants.colors.primaryLight
                layoutIfNeeded()
            case .yes:
                (yesView?.subviews[0] as! UIImageView).tintColor = Constants.colors.primaryDark
                (noView?.subviews[0] as! UIImageView).tintColor = Constants.colors.primaryLight
                layoutIfNeeded()
            case .no:
                (yesView?.subviews[0] as! UIImageView).tintColor = Constants.colors.primaryLight
                (noView?.subviews[0] as! UIImageView).tintColor = Constants.colors.primaryDark
                layoutIfNeeded()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(with question: String, yesAction: @escaping () -> (), noAction: @escaping () -> ()) {
        self.init(frame: CGRect.zero)
        self.question = question
        self.yesAction = yesAction
        self.noAction = noAction
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        let questionLabel = UILabel()
        questionLabel.text = question
        questionLabel.font = UIFont.systemFont(ofSize: 16)
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .left
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //        let yesView = createIconWithText(icon: "check", text: "YES")
        //        let noView = createIconWithText(icon: "times", text: "NO")
        
        yesView = createIcon(icon: "check")
        noView = createIcon(icon: "times")
        
        guard let yesView = yesView, let noView = noView else { return }
        
        yesView.addTapGestureRecognizer {
            self.selected = .yes
            self.yesAction!()
        }
        noView.addTapGestureRecognizer {
            self.selected = .no
            self.noAction!()
        }
        
        addSubview(questionLabel)
        addSubview(yesView)
        addSubview(noView)
        
        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5@999)-[v0]-(5@999)-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": yesView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5@999)-[v0]-(5@999)-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": noView]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[v0]-10-[yes(30)]-14-[no(30)]-14-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": questionLabel, "yes": yesView, "no": noView]))
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

class CommentRow : UIView {
    var action: (() -> ())?
    var text: String?
    var icon: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    convenience init(with text: String, icon: String, backgroundColor: UIColor, action: @escaping () -> ()) {
        self.init(frame: CGRect.zero)
        self.text = text
        self.icon = icon
        self.action = action
        self.backgroundColor = backgroundColor
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupView() {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 2
        label.textColor = Constants.colors.primaryLight
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        let icon = createIcon(icon: self.icon!)
        addSubview(icon)
        
        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": label]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5@999)-[icon]-(5@999)-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["icon": icon]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[v0]-14-[icon(25)]-14-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": label, "icon": icon]))
        
        translatesAutoresizingMaskIntoConstraints = false
        addTapGestureRecognizer {
            self.action!()
        }
    }
}

class HeaderRow : UIView {
    var placePersonalInformation: String? {
        didSet {
            placePersonalInformationLabel.text = placePersonalInformation
        }
    }
    
    var placeName : String? {
        didSet {
            placeNameLabel.text = placeName
        }
    }
    
    var placeAddress : String? {
        didSet {
            placeAddressLabel.text = placeAddress
        }
    }

    let placeNameLabel: UILabel = {
        let label = UILabel()
        label.text = "place name"
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.textColor = Constants.colors.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let placeAddressLabel: UILabel = {
        let label = UILabel()
        label.text = "place address"
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = Constants.colors.superLightGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let placePersonalInformationLabel: UILabel = {
        let label = UILabel()
        label.text = "place personal information"
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = Constants.colors.white
        label.textAlignment = .center
        label.numberOfLines = 0 // as many lines as necessary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupView() {
        addSubview(placeNameLabel)
        addSubview(placeAddressLabel)
        addSubview(placePersonalInformationLabel)

        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[title(30)][address]-15-[info]", options: NSLayoutFormatOptions(), metrics: nil, views: ["title": placeNameLabel, "address": placeAddressLabel, "info": placePersonalInformationLabel]))
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[title]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["title": placeNameLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[address]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["address": placeAddressLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[info]-10-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["info": placePersonalInformationLabel]))

        translatesAutoresizingMaskIntoConstraints = false
    }
}

class FooterRow : UIView {
    var action: (() -> ())?
    var text: String? {
        didSet {
            label?.text = text
        }
    }
    var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(with text: String, backgroundColor: UIColor, action: @escaping () -> ()) {
        self.init(frame: CGRect.zero)
        self.text = text
        self.action = action
        self.backgroundColor = backgroundColor.withAlphaComponent(0.7)
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupView() {
        label = UILabel()
        guard let label = label else { return }
        label.text = text
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = Constants.colors.white
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        // add constraints
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": label]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": label]))
        
        translatesAutoresizingMaskIntoConstraints = false
        addTapGestureRecognizer {
            self.action!()
        }
    }
}

// MARK: - helper functions

fileprivate func createIcon(icon: String) -> UIView {
    let view = UIView()
    let imageView = UIImageView(image: UIImage(named: icon)!.withRenderingMode(.alwaysTemplate))
    imageView.tintColor = Constants.colors.primaryLight
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(imageView)
    
    view.addVisualConstraint("V:|[v0]|", views: ["v0": imageView])
    view.addVisualConstraint("H:|[v0]|", views: ["v0": imageView])
    
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
}

private func createIconWithText(icon: String, text: String) -> UIView {
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

