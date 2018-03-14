//
//  ExplanationFeedbackViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 3/1/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class ExplanationFeedbackViewController: UIViewController {
    @objc func send(_ sender: UIBarButtonItem) {
        sendToServerAndSaveLocally()
        goBack(nil)
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        sendToServerAndSaveLocally()
        goBack(nil)
    }
    
    func goBack(_ notificationView: NotificationView?) {
        view.endEditing(true)
        guard let controllers = navigationController?.viewControllers else { return }
        if controllers.count == 2 {
            // get the previous view controller
            navigationController?.popToViewController(controllers[0], animated: true)
        }
    }
    
    func sendToServerAndSaveLocally() {
        print("comment: \(textView.text)")
        if let piid = personalInformation?.id, let comment = textView.text, comment != "" {
            UserUpdateHandler.updatePersonalInformation(for: piid, with: comment) { [weak self] in
                self?.goBack(nil)
            }
        }
    }
    
    lazy var headerView: PlaceHeader = {
        let header = PlaceHeader()
        header.backgroundColor = color
        header.placeName = "Give a feedback on an explanation"
        return header
    }()
    
    var color = Constants.colors.orange
    
    lazy private var explanationRow: ElementRowView = {
        let row = ElementRowView()
        row.descriptionText = "Explanation:"
        if let explanation = personalInformation?.explanation {
            row.text = explanation
        }
        return row
    }()
    
    lazy private var piRow: ElementRowView = {
        let row = ElementRowView()
        row.descriptionText = "Personal information:"
        if let pi = personalInformation?.name {
            row.text = pi
        }
        return row
    }()
    
    var personalInformation: AggregatedPersonalInformation? {
        didSet {
            if let explanation = personalInformation?.getExplanation() {
                print("explanation: \(explanation)")
                explanationRow.text = explanation
            }
            if let pi = personalInformation?.name {
                print("personal information: \(pi)")
                piRow.text = pi
            }
            if let comment = personalInformation?.comment {
                print("comment: \(comment)")
                textView.text = comment
            }
        }
    }
    
    lazy private var textView: UITextView = {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 14.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        setupNavBarButtons()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupViews()
    }
    
    func setupNavBarButtons() {
        self.navigationController?.isNavigationBarHidden = false
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .blackOpaque

        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(send))
        doneButton.tintColor = Constants.colors.superLightGray
        self.navigationItem.rightBarButtonItem = doneButton
        
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "angle-left")!.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = Constants.colors.superLightGray
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func setupViews() {
        self.view.addSubview(headerView)
        self.view.addSubview(piRow)
        self.view.addSubview(explanationRow)
        self.view.addSubview(textView)
        self.view.addVisualConstraint("H:|[header]|", views: ["header" : headerView])
        self.view.addVisualConstraint("H:|[v0]-|", views: ["v0": piRow])
        self.view.addVisualConstraint("H:|[v0]-|", views: ["v0": explanationRow])
        self.view.addVisualConstraint("H:|-[v0]-|", views: ["v0": textView])
        
        self.view.addVisualConstraint("V:|[header(120)][pi]-[ex]-[text]|", views: ["header": headerView, "pi": piRow, "ex": explanationRow, "text": textView])
    }
    
}

fileprivate class ElementRowView: UIView {
    
    var descriptionText: String = "Description:" { didSet {
        descriptionLabel.text = descriptionText
    }}
    
    var text: String = "Text" { didSet {
        textLabel.text = text
    }}
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = Constants.colors.lightGray
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .light)
        label.text = descriptionText
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = Constants.colors.black
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        label.text = text
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupViews() {
        addSubview(dividerLineView)
        addSubview(descriptionLabel)
        addSubview(textLabel)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": dividerLineView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-14-[desc(100)]-[text]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["desc": descriptionLabel, "text": textLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[desc]-12-[v0(0.5)]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["desc": descriptionLabel, "v0": dividerLineView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[text]-12-[v0(0.5)]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["text": textLabel, "v0": dividerLineView]))
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
