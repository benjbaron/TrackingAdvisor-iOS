//
//  PlaceEditViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/10/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit

class PlaceEditViewController: UIViewController {
    
    @objc func save(_ sender: UIBarButtonItem) {
        saveChanges()
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        goBack(nil)
    }
    
    func goBack(_ notificationView: NotificationView?) {
        view.endEditing(true)
        
        if let pid = place?.id {
            LogService.shared.log(LogService.types.personalInfoBack,
                                  args: [LogService.args.placeId: pid])
        }
        
        guard let controllers = navigationController?.viewControllers else { return }
        let vc = controllers[controllers.count - 2]
        navigationController?.popToViewController(vc, animated: true)
    }
    
    func saveChanges() {
        if let pid = place?.id {
            LogService.shared.log(LogService.types.placeEditSaved,
                                  args: [LogService.args.placeId: pid])
        }
        
        let notificationView: NotificationView? = NotificationView(text: "Updating the place...")
        notificationView?.color = color
        notificationView?.frame = CGRect(x: 0, y: 0, width: view.frame.width - 50, height: 50)
        notificationView?.center = CGPoint(x: view.center.x, y: view.frame.height - 100.0)
        
        if let pid = place?.id, let placeName = nameTextView.text,
           let placeAddress = addressTextView.text, let placeCity = cityTextView.text {
            place?.name = placeName
            place?.address = placeAddress
            place?.city = placeCity
            
            self.goBack(notificationView)
            notificationView?.autoRemove(with: 15, text: "Failed, try again")
            
            UserUpdateHandler.placeEdit(for: pid, placeName: placeName, placeAddress: placeAddress, placeCity: placeCity) {
                notificationView?.text = "Done"
                if notificationView != nil {
                    UIView.animate(withDuration: 1.0, animations: {
                        notificationView?.alpha = 0
                    }, completion: { success in
                        notificationView?.remove()
                    })
                }
            }
        }
    }
    
    lazy var headerView: PlaceHeader = {
        let header = PlaceHeader()
        header.placeName = "Edit the place"
        header.backgroundColor = color
        return header
    }()
    
    lazy var nameIconView: UIImageView = {
        let icon = UIImageView(image: UIImage(named: "shop")!.withRenderingMode(.alwaysTemplate))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = Constants.colors.lightGray
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var nameTextView: UITextView = {
        let tv = UITextView()
        tv.autocorrectionType = .no
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.textContainer.maximumNumberOfLines = 2
        tv.isScrollEnabled = false
        tv.text = ""
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    let nameDividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var addressIconView: UIImageView = {
        let icon = UIImageView(image: UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    var addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Address"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = Constants.colors.lightGray
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var addressTextView: UITextView = {
        let tv = UITextView()
        tv.autocorrectionType = .no
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.textContainer.maximumNumberOfLines = 2
        tv.isScrollEnabled = false
        tv.text = ""
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    let addressDividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var cityLabel: UILabel = {
        let label = UILabel()
        label.text = "City"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = Constants.colors.lightGray
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    var cityTextView: UITextView = {
        let tv = UITextView()
        tv.autocorrectionType = .no
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.textContainer.maximumNumberOfLines = 2
        tv.isScrollEnabled = false
        tv.text = ""
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    let cityDividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    var color = Constants.colors.orange { didSet {
        nameIconView.tintColor = color
        addressIconView.tintColor = color
        headerView.backgroundColor = color
    }}
    
    var place: Place? { didSet {
        if let placeName = place?.name {
            nameTextView.text = placeName
        }
        if let placeCity = place?.city {
            cityTextView.text = placeCity
        }
        if let placeAddress = place?.address {
            addressTextView.text = placeAddress
        }
        if let color = place?.getPlaceColor() {
            self.color = color
        }
    }}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        setupNavBarButtons()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        
        setupViews()
    }

    func setupNavBarButtons() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
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
        
        self.view.addSubview(nameLabel)
        self.view.addSubview(nameTextView)
        self.view.addSubview(nameDividerLineView)
        self.view.addSubview(nameIconView)
        
        self.view.addSubview(addressLabel)
        self.view.addSubview(addressTextView)
        self.view.addSubview(addressDividerLineView)
        self.view.addSubview(addressIconView)
        
        self.view.addSubview(cityLabel)
        self.view.addSubview(cityTextView)
        self.view.addSubview(cityDividerLineView)
        
        self.view.addVisualConstraint("H:|[header]|", views: ["header" : headerView])
        self.view.addVisualConstraint("H:|-14-[icon]-14-[name]-14-|", views: ["icon": nameIconView, "name" : nameLabel])
        self.view.addVisualConstraint("H:|-14-[icon]-10-[name]-14-|", views: ["icon": nameIconView, "name" : nameTextView])
        self.view.addVisualConstraint("H:|-14-[icon]-10-[name]-14-|", views: ["icon": nameIconView, "name" : nameDividerLineView])
        
        self.view.addVisualConstraint("H:|-14-[icon]-14-[address]-14-|", views: ["icon": addressIconView, "address" : addressLabel])
        self.view.addVisualConstraint("H:|-14-[icon]-10-[address]-14-|", views: ["icon": addressIconView, "address" : addressTextView])
        self.view.addVisualConstraint("H:|-14-[icon]-10-[address]-14-|", views: ["icon": addressIconView, "address" : addressDividerLineView])
        
        self.view.addVisualConstraint("H:|-14-[icon]-14-[city]-14-|", views: ["icon": addressIconView, "city" : cityLabel])
        self.view.addVisualConstraint("H:|-14-[icon]-10-[city]-14-|", views: ["icon": addressIconView, "city" : cityTextView])
        self.view.addVisualConstraint("H:|-14-[icon]-10-[city]-14-|", views: ["icon": addressIconView, "city" : cityDividerLineView])

        
        self.view.addVisualConstraint("V:|[header]-20-[name][nameTF][nameL(0.5)]-23-[address][addressTF][addressL(0.5)]-23-[city][cityTF][cityL(0.5)]", views: ["header": headerView, "name" : nameLabel, "nameTF": nameTextView, "nameL": nameDividerLineView, "address" : addressLabel, "addressTF": addressTextView, "addressL": addressDividerLineView, "city" : cityLabel, "cityTF": cityTextView, "cityL": cityDividerLineView])
        
        nameIconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        nameIconView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        nameIconView.topAnchor.constraint(equalTo: nameLabel.topAnchor).isActive = true
        
        addressIconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        addressIconView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        addressIconView.topAnchor.constraint(equalTo: addressLabel.topAnchor).isActive = true
    }
}
