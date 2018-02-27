//
//  OnboardingViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 2/7/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation
import UserNotifications

class OnboardingViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
//        navigationBar.barStyle = .blackOpaque
//        UIApplication.shared.statusBarStyle = .default
//
        view.backgroundColor = .white
        
        let bannerView = UIImageView(image: UIImage(named: "ucl-banner")!.withRenderingMode(.alwaysTemplate))
        bannerView.tintColor = Constants.colors.midPurple
        bannerView.contentMode = .scaleAspectFit
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
                
        view.addVisualConstraint("H:|[v0]|", views: ["v0": bannerView])
        view.addVisualConstraint("V:[v0(72)]", views: ["v0": bannerView])
        bannerView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIApplication.shared.statusBarFrame.size.height).isActive = true // goes under the status bar (20pt or 44pt)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

struct OnboardingItem {
    let icon: String
    let text: String
    let color: UIColor
}

class OnboardingItemsViewController: UIViewController {
    
    var items: [OnboardingItem]? {
        didSet {
            if contentView != nil {
                updateUI()
            }
        }
    }
    
    private var scrollView: UIScrollView!
    var contentView: UIView!
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        print("viewWillLayoutSubviews")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad")
        print("view frame: \(self.view.frame)")
        
        scrollView = UIScrollView(frame: self.view.frame)
        scrollView.sizeToFit()
        scrollView.alwaysBounceVertical = true
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.white
        self.view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.white
        scrollView.addSubview(contentView!)
        
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
        
        
        
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: 2300)
    }
    
    private func updateUI() {
        guard let items = items else { return }
        
        view.layoutIfNeeded()
        view.layoutSubviews()
        
        print("contentView: \(contentView.frame), scrollview: \(scrollView.frame)")
        
        let fixedWidth = contentView.frame.width - 50.0
        
        var height:CGFloat = 0.0
        for item in items {
            let textView = UITextView(frame: .zero)
            
            textView.text = item.text
            textView.font = UIFont.systemFont(ofSize: 18.0)
            textView.isEditable = false
            textView.isSelectable = false
            
            textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            
            let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            
            let newFrame = CGRect(x: 50.0, y: height, width: max(newSize.width, fixedWidth), height: newSize.height)
            textView.frame = newFrame
            
            contentView.addSubview(textView)
            
            let image = UIImageView(image: UIImage(named: item.icon)?.withRenderingMode(.alwaysTemplate))
            image.tintColor = item.color
            image.contentMode = .scaleAspectFit
            let yMiddle:CGFloat = height + newFrame.height / 2.0 - 20.0
            image.frame = CGRect(x: 0.0, y: yMiddle, width: 40.0, height: 40.0)
            
            contentView.addSubview(image)
            
            height += newFrame.height + 20.0
        }
        
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: max(height, scrollView.frame.height))
        
        print("height: \(height), \(scrollView.frame.height), \(contentView.frame), \(scrollView.contentSize)")
    }
}

class OnboardingConsentFormViewController: UIViewController {
    
    private var form: [String]? {
        didSet {
            updateUI()
        }
    }
    
    private var scrollView: UIScrollView!
    var contentView: UIView!
    
    private lazy var waitingView: UIView = {
        let view = UIView()
        
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.startAnimating()
        activityView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityView)
        
        let label = UILabel()
        label.text = "Getting the latest participant requirements"
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textAlignment = .center
        label.textColor = Constants.colors.midPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        view.addVisualConstraint("H:|[v0]|", views: ["v0": activityView])
        view.addVisualConstraint("H:|[v0]|", views: ["v0": label])
        view.addVisualConstraint("V:|-40-[v0]-[v1]-40-|", views: ["v0": activityView, "v1": label])
        
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("view frame: \(self.view.frame)")
        
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
        
        contentView.addSubview(waitingView)
        contentView.addVisualConstraint("H:|-40-[v0]-40-|", views: ["v0": waitingView])
        
        getConsentFormFromServer()
    }
    
    private func updateUI() {
        guard let form = form else { return }
        
        if form.count == 0 {
            waitingView.isHidden = false
        } else {
            waitingView.isHidden = true
        }
        
        let fixedWidth = contentView.frame.width - 42.0
        
        var height:CGFloat = 0.0
        var count = 1
        for clause in form {
            let textView = UITextView(frame: .zero)
            
            textView.text = clause
            textView.font = UIFont.systemFont(ofSize: 14.0)
            textView.isEditable = false
            textView.isSelectable = false
            
            textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            
            let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            let newFrame = CGRect(x: 42.0, y: height, width: max(newSize.width, fixedWidth), height: newSize.height)
            textView.frame = newFrame
            
            contentView.addSubview(textView)
            
            let label = UILabel(frame: CGRect(x: 0.0, y: height-7.0, width: 42.0, height: 40.0))
            label.text = "\(count)."
            label.font = UIFont.systemFont(ofSize: 25, weight: .heavy)
            label.textColor = Constants.colors.lightPurple
            
            contentView.addSubview(label)
            
            height += newFrame.height + 20.0
            count += 1
        }
        
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: max(height, scrollView.frame.height))
        print("height: \(height), \(scrollView.frame.height), \(contentView.frame)")
    }
    
    private func getConsentFormFromServer() {
        Alamofire.request(Constants.urls.consentFormURL, method: .get, parameters: nil)
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        strongSelf.form = try decoder.decode([String].self, from: data)
                    } catch {
                        print("Error serializing the json", error)
                    }
                }
        }
    }
}

class OnboardingExpectationsViewController: UIViewController {
    @IBAction func cancel(_ sender: UIButton) {
        showCancelDialog(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "expectations" {
            if let dest = segue.destination as? OnboardingItemsViewController {
                
                let items = [
                    OnboardingItem(icon: "iphone4", text: "All you need to do is use your phone as usual.", color: Constants.colors.lightPurple),
                    OnboardingItem(icon: "location-arrow", text: "The study will automatically collect and analyse your location data.", color: Constants.colors.lightPurple),
                    OnboardingItem(icon: "notification", text: "We will ask you to give feedback on the places and personal information we extracted.", color: Constants.colors.lightPurple),
                    OnboardingItem(icon: "log-out", text: "You can choose to leave the study at any time.", color: Constants.colors.lightPurple)
                ]
                dest.items = items
            }
            
        }
    }
}

class OnboardingRequirementsViewController: UIViewController {
    @IBAction func cancel(_ sender: UIButton) {
        showCancelDialog(self)
    }
}

class OnboardingPermissionsViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    let segueId = "allow permissions"
    
    @IBAction func cancel(_ sender: UIButton) {
        showCancelDialog(self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == segueId) {
            print("Show all the permission prompts here")
            
            // location permission
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestAlwaysAuthorization()
        } else if identifier == "permissions" {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "permissions" {
            if let dest = segue.destination as? OnboardingItemsViewController {
                
                let items = [
                    OnboardingItem(icon: "location-arrow", text: "Enable always-on location so that we automatically collect your location data.", color: Constants.colors.lightPurple),
                    OnboardingItem(icon: "running", text: "Enable fitness and activity so that we fine-tune our place matching.", color: Constants.colors.lightPurple),
                    OnboardingItem(icon: "notification", text: "Enable your iPhone to receive notifications so that we can ask you feedback.", color: Constants.colors.lightPurple)
                ]
                dest.items = items
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorization with status \(status)")
        
        switch status {
        case .notDetermined:
            locationManager?.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("authorizedAlways")
            // activity and motion permission
            ActivityService.shared.getSteps(from: Date(), to: Date(), callback: {_ in
                // notification permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) {
                    [weak self] (granted, error) in
                    print("Permission granted: \(granted)")
                    
                    if granted {
                        DispatchQueue.main.async {
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.getNotificationSettings()
                            
                            // we are good to go
                            guard let strongSelf = self else { return }
                            strongSelf.performSegue(withIdentifier: strongSelf.segueId, sender: nil)
                        }
                    }
                }
            })
        default:
            print("permission denied")
        }
    }
}

class OnboardingFinalViewController: UIViewController {
    @IBAction func done(_ sender: UIButton) {
        Settings.saveOnboarding(with: true)
        UserUpdateHandler.registerNewUser()
        
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.launchStoryboard(storyboard: "Main")
        }
    }
}

class OnboardingSorryViewController: UIViewController {
    
    @IBAction func startAgain(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "FirstScreenInitialOnboarding")
        self.navigationController?.pushViewController(initialViewController, animated: true)
    }
}

fileprivate func showCancelDialog(_ controller: UIViewController, handler: (() -> Void)? = nil) {
    let alertController = UIAlertController(title: "Are you sure you want to stop enrolling in this user study?", message: nil, preferredStyle: .actionSheet)
    
    let stopEnrolling = UIAlertAction(title: "Don't Enroll", style: .destructive) { action in
        if let handler = handler {
            handler()
        } else {
            // Load the onboarding view and the navigation controller
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let failedViewController = storyboard.instantiateViewController(withIdentifier: "FailedEnrolling")
            controller.navigationController?.pushViewController(failedViewController, animated: true)
        }
    }
    
    let cancelButton = UIAlertAction(title: "Close", style: .cancel)
    cancelButton.setValue(UIColor.red, forKey: "titleTextColor")
    
    alertController.addAction(stopEnrolling)
    alertController.addAction(cancelButton)
    
    controller.present(alertController, animated: true, completion: nil)
}
