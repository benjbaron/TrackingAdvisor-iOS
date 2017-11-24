//
//  RawCollectedDataTextViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/6/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

class RawCollectedDataTextViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    var file: URL!
    var filename: String!
    var filecontent: String!
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = filename
        self.textView.text = filecontent
        
        // add an upload button in the view
        let addButton = UIBarButtonItem(title: "Upload", style: .done, target: self, action: #selector(addTapped))
        self.navigationItem.rightBarButtonItem = addButton
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func addTapped(sender: UIBarButtonItem) {
        print("uploading file \(filename)")
        
//        let userUpdate = UserUpdate(userid: "678912345", from: Date(), to: Date(),
//                                    movements: [UserMove(moveid: "678912345",
//                                                         departurePlace: UserPlace(placeid: "01a08d4d5cef9080943bbb6465821a79", name: "Home", city: "Home city", category: "Home", longitude: -0.123987639372744, latitude: 51.524737706966903, address: "Home address", userEntered: false),
//                                                         arrivalPlace: UserPlace(placeid: "56387431cd10060b84383ec4", name: "Noble Rot", city: "London", category: "Restaurant", longitude: -0.11859634989517259, latitude: 51.521879770610425, address: "51 Lamb’s Conduit St", userEntered: false),
//                                                         departureDate: Date(),
//                                                         arrivalDate: Date(),
//                                                         activity: "Unknown")],
//                                    places: [UserPlace(placeid: "01a08d4d5cef9080943bbb6465821a79", name: "Home", city: "Home city", category: "Home", longitude: -0.123987639372744, latitude: 51.524737706966903, address: "Home address", userEntered: false),
//                                             UserPlace(placeid: "56387431cd10060b84383ec4", name: "Noble Rot", city: "London", category: "Restaurant", longitude: -0.11859634989517259, latitude: 51.521879770610425, address: "51 Lamb’s Conduit St", userEntered: false)],
//                                    visits: [UserVisit(visitid: "a9a9f0fc3fc1357b3d47355ae3237c7b", place: UserPlace(placeid: "01a08d4d5cef9080943bbb6465821a79", name: "Home", city: "Home city", category: "Home", longitude: -0.123987639372744, latitude: 51.524737706966903, address: "Home address", userEntered: false), placeid: "01a08d4d5cef9080943bbb6465821a79", arrival: Date(), departure: Date(), confidence: 1.0),
//                                             UserVisit(visitid: "4c550440330c67e1d0f862c5e545b5de", place: UserPlace(placeid: "56387431cd10060b84383ec4", name: "Noble Rot", city: "London", category: "Restaurant", longitude: -0.11859634989517259, latitude: 51.521879770610425, address: "51 Lamb’s Conduit St", userEntered: false), placeid: "56387431cd10060b84383ec4", arrival: Date(), departure: Date(), confidence: 1.0)])
        
        FileService.shared.upload(file: file) { response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let userUpdate = try decoder.decode(UserUpdate.self, from: data)
                print(userUpdate)
                DataStoreService.shared.updateDatabase(with: userUpdate)
            } catch {
                print("Error serializing the json", error)
            }
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
