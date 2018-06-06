//
//  ChatViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 5/22/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

struct Message : Codable {
    let text: String
    let timestamp: Date
    let sender: Bool
}

class ChatViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var collectionView: UICollectionView!
    private let cellId = "cellId"
    
    var friend: String? {
        didSet {
            navigationItem.title = friend
        }
    }
    
    let messageInputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        let titleColor = UIColor(red: 0, green: 137/255, blue: 249/255, alpha: 1)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private func scrollToLastMessage() {
        // scroll to the last message
        if messages.count > 0 {
            let lastItem = self.messages.count - 1
            let indexPath = IndexPath(item: lastItem, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func createMessage(with text: String, minutesAgo: Double, sender: Bool = false) -> Message {
        let message = Message(text: text, timestamp: Date().addingTimeInterval(-minutesAgo * 60), sender: sender)
        return message
    }
    
    @objc func handleSend() {
        if let text = inputTextField.text {
            let message = createMessage(with: text, minutesAgo: 0, sender: true)
            messages.append(message)
            send(message: message) { [unowned self] in
                self.scrollToLastMessage()
            }
        }
        inputTextField.text = nil
    }
    
    var messages: [Message] = [] { didSet {
        collectionView?.reloadData()
        scrollToLastMessage()
    }}
    var bottomConstraint: NSLayoutConstraint?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
        getAllMessages() { [unowned self] res in
            self.messages = res
            self.scrollToLastMessage()
            
            self.collectionView.contentInset = UIEdgeInsets(top: 64.0, left: 0.0, bottom: 0.0, right: 0.0)
            self.collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 64.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    
    @objc func back(sender: UIBarButtonItem) {
        self.navigationController!.popToRootViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // change the behaviour of the back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        view.backgroundColor = .white
        
        let frame = UIScreen.main.bounds
        collectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 250, height: 100)
        flowLayout.minimumInteritemSpacing = 3
        flowLayout.minimumLineSpacing = 3
        flowLayout.scrollDirection = .vertical
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.register(ChatLogMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        view.addSubview(collectionView)
        view.addVisualConstraint("H:|[collection]|", views: ["collection": collectionView])
        
        view.addSubview(messageInputContainerView)
        view.addVisualConstraint("H:|[v0]|", views: ["v0": messageInputContainerView])
        view.addVisualConstraint("V:|[collection]-[v0(48)]", views: ["collection": collectionView, "v0": messageInputContainerView])
        
        bottomConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        
        if AppDelegate.isIPhoneX() {
            bottomConstraint?.constant = -15
        }
        
        view.addConstraint(bottomConstraint!)
        view.layoutIfNeeded()
        
        setupInputComponents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func handleKeyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
            
            bottomConstraint?.constant = isKeyboardShowing ? -keyboardFrame!.height : 0
            
            
            UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                
                self.view.layoutIfNeeded()
                
            }, completion: { [unowned self] (completed) in
                
                if isKeyboardShowing && self.messages.count > 0 {
                    let lastItem = self.messages.count - 1
                    let indexPath = IndexPath(item: lastItem, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        inputTextField.endEditing(true)
    }
    
    private func setupInputComponents() {
        let topBorderView = UIView()
        topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        topBorderView.translatesAutoresizingMaskIntoConstraints = false
        
        messageInputContainerView.addSubview(inputTextField)
        messageInputContainerView.addSubview(sendButton)
        messageInputContainerView.addSubview(topBorderView)
        
        messageInputContainerView.addVisualConstraint("H:|-8-[v0][v1(60)]|", views: ["v0": inputTextField, "v1": sendButton])
        
        messageInputContainerView.addVisualConstraint("V:|[v0]|", views: ["v0": inputTextField])
        messageInputContainerView.addVisualConstraint("V:|[v0]|", views: ["v0": sendButton])
        
        messageInputContainerView.addVisualConstraint("H:|[v0]|", views: ["v0": topBorderView])
        messageInputContainerView.addVisualConstraint("V:|[v0(0.5)]", views: ["v0": topBorderView])
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatLogMessageCell
        
        var nextMessage: Message? = nil
        if messages.count > indexPath.item+1 {
            nextMessage = messages[indexPath.item+1]
        }
        let message = messages[indexPath.item]
        
        cell.messageTextView.text = message.text
        cell.profileImageView.image = UIImage(named: "user-circle")
        
        let constraintRect = CGSize(width: 250, height: 1000)
        let estimatedFrame = message.text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font : UIFont.systemFont(ofSize: 18)], context: nil)
        
        
        if !message.sender {
            cell.messageTextView.frame = CGRect(x: 48 + 8, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 20)
            
            cell.textBubbleView.frame = CGRect(x: 48 - 10, y: -4, width: estimatedFrame.width + 16 + 8 + 16, height: estimatedFrame.height + 20 + 6)
            
            cell.profileImageView.isHidden = false
            
            if let msg = nextMessage, !msg.sender {
                cell.bubbleImageView.image = ChatLogMessageCell.grayTailBubbleImage
            } else {
                cell.bubbleImageView.image = ChatLogMessageCell.grayBubbleImage
            }
            cell.bubbleImageView.tintColor = UIColor(white: 0.95, alpha: 1)
            cell.messageTextView.textColor = UIColor.black
            
        } else {
            //outgoing sending message
            
            cell.messageTextView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 40, y: 0, width: estimatedFrame.width + 16, height: estimatedFrame.height + 20)
            
            cell.textBubbleView.frame = CGRect(x: view.frame.width - estimatedFrame.width - 50, y: -4, width: estimatedFrame.width + 34, height: estimatedFrame.height + 26)
            
            cell.profileImageView.isHidden = true
            
            if let msg = nextMessage, msg.sender {
                cell.bubbleImageView.image = ChatLogMessageCell.blueTailBubbleImage
            } else {
                cell.bubbleImageView.image = ChatLogMessageCell.blueBubbleImage
            }
            cell.bubbleImageView.tintColor = UIColor(red: 0, green: 137/255, blue: 249/255, alpha: 1)
            cell.messageTextView.textColor = UIColor.white
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let message = messages[indexPath.item]
        let constraintRect = CGSize(width: 250, height: 1000)
        let estimatedFrame = message.text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font : UIFont.systemFont(ofSize: 18)], context: nil)
        
        var nextMessage: Message? = nil
        if messages.count > indexPath.item+1 {
            nextMessage = messages[indexPath.item+1]
        }
        
        var offset: CGFloat = 20.0
        if nextMessage != nil && nextMessage!.sender != message.sender {
            offset = 35.0
        }
        return CGSize(width: view.frame.width, height: estimatedFrame.height + offset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - Communicate with the server
    private func getAllMessages(callback: (([Message])->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "userid": userid
            ]
            Alamofire.request(Constants.urls.getAllMessagesURL, method: .get, parameters: parameters).responseJSON { response in
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "get",
                                             LogService.args.responseUrl: Constants.urls.getAllMessagesURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let res = try decoder.decode([Message].self, from: data)
                        callback?(res)
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
            }
        }
    }
    
    private func send(message: Message, callback: (()->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let userid = Settings.getUserId() ?? ""
            let parameters: Parameters = [
                "userid": userid,
                "message": message.text,
                "timestamp": message.timestamp.localTime
            ]
            Alamofire.request(Constants.urls.sendMessageURL, method: .get, parameters: parameters).responseJSON { response in
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "get",
                                             LogService.args.responseUrl: Constants.urls.sendMessageURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        _ = try decoder.decode([String:String].self, from: data)
                        callback?()
                    } catch {
                        print("Error serializing the json", error)
                    }
                } else {
                    print("Error in response \(response.result)")
                }
            }
        }
    }
    
}

fileprivate class ChatLogMessageCell: BaseCell {
    
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.text = "Sample message"
        textView.backgroundColor = UIColor.clear
        return textView
    }()
    
    let textBubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        return view
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    static let grayBubbleImage = UIImage(named: "bubble_gray")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26)).withRenderingMode(.alwaysTemplate)
    static let blueBubbleImage = UIImage(named: "bubble_blue")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26)).withRenderingMode(.alwaysTemplate)
    
    static let blueTailBubbleImage = UIImage(named: "bubble_sender")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26)).withRenderingMode(.alwaysTemplate)
    static let grayTailBubbleImage = UIImage(named: "bubble_receiver")!.resizableImage(withCapInsets: UIEdgeInsets(top: 22, left: 26, bottom: 22, right: 26)).withRenderingMode(.alwaysTemplate)
    
    let bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = ChatLogMessageCell.grayBubbleImage
        imageView.tintColor = UIColor(white: 0.90, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(textBubbleView)
        addSubview(messageTextView)
        addSubview(profileImageView)

        addVisualConstraint("H:|-8-[v0(30)]", views: ["v0": profileImageView])
        addVisualConstraint("V:[v0(30)]|", views: ["v0": profileImageView])
        
        textBubbleView.addSubview(bubbleImageView)
        textBubbleView.addVisualConstraint("H:|[v0]|", views: ["v0": bubbleImageView])
        textBubbleView.addVisualConstraint("V:|[v0]|", views: ["v0": bubbleImageView])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}

fileprivate class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() { }
}


