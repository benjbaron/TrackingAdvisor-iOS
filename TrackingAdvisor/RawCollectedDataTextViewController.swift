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
        let addButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(addTapped))
        self.navigationItem.rightBarButtonItem = addButton
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc func addTapped(sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "Choose an action", message: "What would you like to do?", preferredStyle: .actionSheet)
        
        let sendButton = UIAlertAction(title: "Upload the file", style: .default) { [weak self] (action) in
            print("upload button tapped")
            guard let strongSelf = self else { return }
            FileService.upload(file: strongSelf.file) { response in
                print("data sent to the server!")
            }

        }
        
        let showMapButton = UIAlertAction(title: "Show map", style: .default) { [weak self] (action) in
            print("Show map button tapped")
            guard let strongSelf = self else { return }
            // show the modal map
            if let controller = strongSelf.storyboard?.instantiateViewController(withIdentifier: "PositionMapModalViewController") as? UINavigationController {
                if let mapViewVC = controller.topViewController as? PositionMapModalViewController {
                    mapViewVC.filename = strongSelf.filename
                    mapViewVC.file = strongSelf.file
                    print("Show PositionMapModalViewController")
                    strongSelf.present(controller, animated: true, completion: nil)
                }
            }
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        alertController.addAction(sendButton)
        alertController.addAction(showMapButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
        
        
//        print("uploading file \(filename)")

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
