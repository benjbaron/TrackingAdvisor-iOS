//
//  PersonalInformationChooserViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 2/21/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Fuse


struct PersonalInformationSearchResult: Codable {
    let picid: String
    let pi: String
    let icon: String
}

class PersonalInformationSearchResultFuse: Fuseable {
    @objc dynamic var picid: String
    @objc dynamic var pi: String
    @objc dynamic var icon: String
    @objc dynamic var score: Float
    
    var properties: [FuseProperty] {
        return [
            FuseProperty(name: "pi", weight: 1.0),
        ]
    }
    
    init(picid: String, pi: String, icon: String) {
        self.picid = picid
        self.pi = pi
        self.icon = icon
        self.score = 0.0
    }
}

class PersonalInformationChooserViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
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
        let count = controllers.count
        if count >= 2 {
            // get the previous place detail controller
            let vc = controllers[controllers.count - 2]
            navigationController?.popToViewController(vc, animated: true)
            if let view = notificationView {
                vc.view.addSubview(view)
            }
        } else if count == 1 {
            // return to the timeline
            presentingViewController?.dismiss(animated: true)
            if let view = notificationView {
                presentingViewController?.view.addSubview(view)
            }
        }
    }
    
    func saveChanges() {
        
        if let pid = place?.id {
            LogService.shared.log(LogService.types.personalInfoSaved,
                                  args: [LogService.args.placeId: pid])
        }
        
        let notificationView: NotificationView? = NotificationView(text: "Updating the personal information...")
        notificationView?.color = color
        notificationView?.frame = CGRect(x: 0, y: 0, width: view.frame.width - 50, height: 50)
        notificationView?.center = CGPoint(x: view.center.x, y: view.frame.height - 100.0)
        
        if selectedPersonalInformation != "", let pid = place?.id,
            let picid = selectedPersonalInformationCategory?.picid {
            
            self.goBack(notificationView)
            
            notificationView?.autoRemove(with: 10, text: "Failed, try again")
            
            UserUpdateHandler.addNewPersonalInformation(for: pid, name: selectedPersonalInformation, picid: picid) {
                notificationView?.text = "Done"
                UIView.animate(withDuration: 1.0, animations: {
                    notificationView?.alpha = 0
                }, completion: { success in
                    notificationView?.remove()
                })
            }
        }
    }
    
    lazy var headerView: PlaceHeader = {
        return PlaceHeader()
    }()
    lazy private var personalInformationView = {
        return PersonalInformationSelectionView()
    }()
    
    let cellId = "CellId"
    let tableCellId = "TableCellId"
    var color = Constants.colors.orange
    var searchActive = false
    var searchResult:[String:[PersonalInformationSearchResult]]? = nil { didSet {
        piFuse = searchResult!.mapValues { $0.map { PersonalInformationSearchResultFuse(picid: $0.picid, pi: $0.pi, icon: $0.icon) } }
        if let picid = personalInformationCategory?.picid, let list = piFuse[picid] {
            pi = list
        }
        tableView.reloadData()
    }}
    var piFuse: [String:[PersonalInformationSearchResultFuse]] = [:]
    var pi: [PersonalInformationSearchResultFuse] = []
    var hasMadeChanges = false
    var isFetchingFromServer = false
    var hasExactMatch = false
    
    var visit: Visit?
    var selectedPersonalInformation: String = "" { didSet {
        personalInformationView.personalInformation = selectedPersonalInformation
        selectedPersonalInformationCategory = personalInformationCategory
    }}
    var selectedPersonalInformationCategory: PersonalInformationCategory?
    var personalInformationCategory: PersonalInformationCategory? {
        didSet {
            if let picid = personalInformationCategory?.picid, oldValue?.picid != picid,  let list = piFuse[picid] {
                pi = list
                tableView.reloadData()
            }
        }
    }
    
    var place: Place? {
        didSet {
            guard let place = place else { return }
            headerView.placeName = place.name
            
            color = place.getPlaceColor()
            headerView.backgroundColor = color
            if let p = PersonalInformationCategory.loadPersonalInformationCategories() {
                pics = p.map { $0.picid }.sorted(by: { $0 < $1 })
                picsDict.removeAll()
                for pic in pics {
                    picsDict[pic] = PersonalInformationCategory.getPersonalInformationCategory(with: pic)
                    if collectionView != nil {
                        collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    var cat: String? {
        didSet {
            if collectionView != nil, let cat = cat, let idx = pics.index(of: cat) {
                collectionView.scrollToItem(at: IndexPath(item: idx, section: 0), at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    var collectionView: UICollectionView!
    var flowLayout: PlaceReviewLayout!
    var searchbarView: UISearchBar!
    var tableView: UITableView!
    
    var picsDict: [String: PersonalInformationCategory] = [:]
    var pics: [String] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
//        DataStoreService.shared.delegate = self
        
        setupNavBarButtons()
    
        collectionView.reloadData()
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
        
        var initialItem = 0
        if let cat = cat, let idx = pics.index(of: cat) {
            initialItem = idx
        }
        collectionView.scrollToItem(at: IndexPath(item: initialItem, section: 0), at: .centeredHorizontally, animated: false)
        let picid = pics[initialItem]
        personalInformationCategory = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        
        // set up the collection view
        flowLayout = PlaceReviewLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // set up the search bar controller
        searchbarView = UISearchBar(frame: view.bounds)
        searchbarView.placeholder = "Search personal information..."
        searchbarView.searchBarStyle = .minimal
        searchbarView.setShowsCancelButton(true, animated: true)
        searchbarView.returnKeyType = .done
        searchbarView.isTranslucent = true
        searchbarView.delegate = self
        searchbarView.translatesAutoresizingMaskIntoConstraints = false
        
        // set up the table view
        tableView = UITableView(frame: view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 40
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // register cell types
        collectionView.register(PersonalInformationCategoryChooserCell.self, forCellWithReuseIdentifier: cellId)
        tableView.register(PersonalInformationChooserTableViewCell.self, forCellReuseIdentifier: tableCellId)
        
        // Enable keyboard notifications when showing and hiding the keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        setupViews()
        
        getPersonalInformation()
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
        self.view.addVisualConstraint("H:|[header]|", views: ["header" : headerView])
        
        self.view.addSubview(collectionView)
        self.view.addVisualConstraint("H:|[collection]|", views: ["collection" : collectionView])
        
        self.view.addSubview(searchbarView)
        self.view.addSubview(tableView)
        self.view.addSubview(personalInformationView)
        
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": searchbarView])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": tableView])
        self.view.addVisualConstraint("H:|[v0]|", views: ["v0": personalInformationView])
        
        self.view.addVisualConstraint("V:|[header][collection(100)][pi][search][table]|", views: ["header": headerView, "collection": collectionView, "pi": personalInformationView, "search": searchbarView, "table": tableView])
        
        collectionView.layoutIfNeeded()
        
        // Setup collection view bounds
        let collectionViewFrame = collectionView.frame
        flowLayout.cellWidth = floor(200)
        flowLayout.cellHeight = floor(collectionViewFrame.height * flowLayout.yCellFrameScaling) // for the tab bar
        
        let insetX = floor((collectionViewFrame.width - flowLayout.cellWidth) / 2.0)
        let insetY = floor((collectionViewFrame.height - flowLayout.cellHeight) / 2.0)
        
        // configure the flow layout
        flowLayout.itemSize = CGSize(width: flowLayout.cellWidth, height: flowLayout.cellHeight)
        flowLayout.minimumInteritemSpacing = insetX - 75.0// to show the next cell
        flowLayout.minimumLineSpacing = insetX - 75.0 // to show the next cell
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.isPagingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
    
    // MARK: - UICollectionViewDataSource delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PersonalInformationCategoryChooserCell
        let category = pics[indexPath.item]
        if let pic = picsDict[category] {
            cell.pic = pic
        }
        cell.color = color
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        
        visibleRect.origin = collectionView.contentOffset
        visibleRect.size = collectionView.bounds.size
        
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        guard let indexPath = visibleIndexPath else { return }
        let picid = pics[indexPath.item]
        personalInformationCategory = PersonalInformationCategory.getPersonalInformationCategory(with: picid)
    }
    
    // MARK: - UISearchBarDelegate Delegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count >= 3 {
            searchPersonalInformation(matching: searchText)
        } else if searchText.count == 0 {
            searchPersonalInformation(matching: "")
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let oldText = searchBar.text {
            let newText = (searchBar.text ?? "").replacingCharacters(in: Range(range, in: oldText)!, with: text)
            if oldText.count > newText.count && newText.count < 3 {
                searchPersonalInformation(matching: newText)
            }
        }
        return true
    }
    
    // MARK: - Keyboard notifications
    
    @objc func keyboardWillShow(_ notification: NSNotification){
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        tableView.keyboardRaised(height: keyboardFrame.height)
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification){
        tableView.keyboardClosed()
    }
    
    // MARK: - UITableViewDataSource delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let offset = showAddOption(for: searchbarView.text) ? 1 : 0
        return pi.count + offset
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCellId, for: indexPath) as! PersonalInformationChooserTableViewCell
        
        
        let offset = showAddOption(for: searchbarView.text) ? 1 : 0
        if let searchText = searchbarView.text, offset == 1 && indexPath.row == 0  {
            // this is a user-custom personal information
            let formattedString = NSMutableAttributedString()
            formattedString
                .normal("Add ")
                .bold("\(searchText)")
            cell.nameLabel.attributedText = formattedString
            cell.color = color
            cell.icon = "plus-circle"
            cell.name = searchText
        } else {
            // this is a search result place
            let idx = indexPath.row - offset
            if idx < pi.count {
                cell.displayText = pi[idx].pi
                cell.name = pi[idx].pi
                cell.icon = pi[idx].icon
                cell.color = color.withAlphaComponent(0.5)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? PersonalInformationChooserTableViewCell {
            if let piName = cell.name {
                // select the personal information
                selectedPersonalInformation = piName
                hasMadeChanges = true
                
                if let pid = place?.id {
                    LogService.shared.log(LogService.types.personalInfoSelected,
                                          args: [LogService.args.placeId: pid,
                                                 LogService.args.personalInfo: piName,
                                                 LogService.args.searchedText: searchbarView.text ?? ""])
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - fetch search result from server
    private func showAddOption(for searchText: String?) -> Bool {
        guard let searchText = searchText else { return false }
        if searchText == "" { return false }
        if hasExactMatch { return false }
        return true
    }
    private func getPersonalInformation() {
        if isFetchingFromServer {
            return
        }
        
        isFetchingFromServer = true
        
        let parameters: Parameters = [
            "userid": Settings.getUserId() ?? "",
            "cat": personalInformationCategory?.picid ?? "",
        ]
        
        Alamofire.request(Constants.urls.piAutcompleteURL, method: .get, parameters: parameters)
            .responseJSON { [weak self] response in
                
                LogService.shared.log(LogService.types.serverResponse,
                                      args: [LogService.args.responseMethod: "get",
                                             LogService.args.responseUrl: Constants.urls.piAutcompleteURL,
                                             LogService.args.responseCode: String(response.response?.statusCode ?? 0)])
                
                guard let strongSelf = self else { return }
                if response.result.isSuccess {
                    guard let data = response.data else { return }
                    do {
                        let decoder = JSONDecoder()
                        strongSelf.searchResult = try decoder.decode([String: [PersonalInformationSearchResult]].self, from: data)
                    } catch {
                        print("Error serializing the json", error)
                    }
                }
                strongSelf.isFetchingFromServer = false
        }
    }
    
    private func searchPersonalInformation(matching text: String) {
        guard let picid = personalInformationCategory?.picid, let searchList = piFuse[picid] else { return }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            if text.count > 2 {
            
                let fuse = Fuse()
                let results = fuse.search(text, in: searchList)
                self?.hasExactMatch = false
                for res in results {
                    if res.score == 0.0 {
                        self?.hasExactMatch = true
                        break
                    }
                }
                self?.pi = results.map { searchList[$0.index] }
            } else {
                self?.pi = searchList
            }

            DispatchQueue.main.async { () -> Void in
                self?.tableView.reloadData()
                self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.middle, animated: true)
            }
        }
    }
}

class PersonalInformationCategoryChooserCell: UICollectionViewCell {
    var pic: PersonalInformationCategory? {
        didSet {
            if let name = pic?.name {
                nameLabel.text = name
            }
            if let icon = pic?.icon {
                iconView.icon = icon
            }
        }
    }
    
    var color: UIColor? = Constants.colors.orange {
        didSet {
            self.bgView.backgroundColor = color!.withAlphaComponent(0.3)
            self.nameLabel.textColor = color!
            self.iconView.iconColor = color
        }
    }
    
    var icon: String = "user-circle" {
        didSet {
            self.iconView.icon = icon
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = color!.withAlphaComponent(0.3)
        return v
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = pic?.name
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = color
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var iconView: IconView = {
        return IconView(icon: icon, iconColor: Constants.colors.primaryLight)
    }()
    
    func setupViews() {
        addSubview(bgView)
        bgView.addSubview(nameLabel)
        bgView.addSubview(iconView)
        
        addVisualConstraint("H:|-[v0]-|", views: ["v0": nameLabel])
        addVisualConstraint("H:|-5-[v0]-|", views: ["v0": iconView])
        addVisualConstraint("V:|-[icon(20)][v0]-|", views: ["v0": nameLabel, "icon": iconView])
        
        addVisualConstraint("H:|[v0]|", views: ["v0": bgView])
        addVisualConstraint("V:|-[v0]-|", views: ["v0": bgView])
    }
}

class PersonalInformationChooserTableViewCell: UITableViewCell {
    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    lazy var iconView: UIImageView = {
        let icon = UIImageView(image: UIImage(named: "map-marker")!.withRenderingMode(.alwaysTemplate))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()
    
    var name: String?
    var displayText: String? { didSet {
        nameLabel.text = displayText
    }}
    
    var icon: String? { didSet {
        iconView.image = UIImage(named: icon!)!.withRenderingMode(.alwaysTemplate)
    }}
    
    var color: UIColor = Constants.colors.primaryLight { didSet {
        iconView.tintColor = color
    }}
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupViews() {
        addSubview(nameLabel)
        addSubview(iconView)
        
        // add constraints
        addVisualConstraint("V:|-[v0(20)]", views: ["v0": iconView])
        addVisualConstraint("H:|-[v0(20)]-[v1]-|", views: ["v0": iconView, "v1": nameLabel])
        addVisualConstraint("V:|[v0]|", views: ["v0": nameLabel])
    }
}

fileprivate class PersonalInformationSelectionView: UIView {
    var personalInformation: String = "" { didSet {
        if personalInformation == "" {
            descriptionLabel.text = "No personal information selected."
        } else {
            let formattedString = NSMutableAttributedString()
            formattedString
                .italic("Selected: ", of: 14.0)
                .bold("\(personalInformation)", of: 16.0)
            descriptionLabel.attributedText = formattedString
        }
        setNeedsLayout()
        layoutIfNeeded()
    }}
    
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "No personal information selected."
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        addSubview(descriptionLabel)
        
        // add constraints
        addVisualConstraint("V:|-[v0]-|", views: ["v0": descriptionLabel])
        addVisualConstraint("H:|-[v0]-|", views: ["v0": descriptionLabel])
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
