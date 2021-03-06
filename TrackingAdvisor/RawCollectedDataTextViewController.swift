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
        
        LogService.shared.log(LogService.types.settingsDataFile,
                              args: [LogService.args.filename: filename])
        
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
        
//        let sendButton = UIAlertAction(title: "Upload the file", style: .default) { [weak self] (action) in
//            print("upload button tapped")
//            guard let strongSelf = self else { return }
//            FileService.upload(file: strongSelf.file) { response in
//                // TODO: Show on-screen confirmation
//            }
//        }
        
        let showMapButton = UIAlertAction(title: "Show map", style: .default) { [weak self] (action) in
            guard let strongSelf = self else { return }
            
            LogService.shared.log(LogService.types.settingsDataFileMap,
                                  args: [LogService.args.filename: strongSelf.filename])
            
            // show the modal map
            if let controller = strongSelf.storyboard?.instantiateViewController(withIdentifier: "PositionMapModalViewController") as? UINavigationController {
                if let mapViewVC = controller.topViewController as? PositionMapModalViewController {
                    mapViewVC.filename = strongSelf.filename
                    mapViewVC.file = strongSelf.file
                    strongSelf.present(controller, animated: true, completion: nil)
                }
            }
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
//        alertController.addAction(sendButton)
        alertController.addAction(showMapButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
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
