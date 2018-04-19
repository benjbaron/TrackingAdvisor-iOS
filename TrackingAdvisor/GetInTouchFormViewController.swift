//
//  GetInTouchFormViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 12/4/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import Eureka
import Alamofire
import UIKit

class GetInTouchFormViewController: FormViewController {
    
    var name: String = ""
    var email: String = ""
    var reason: String = ""
    var message: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LogService.shared.log(LogService.types.settingsContact)
        
        form +++ Section()
            <<< TextRow(){
                $0.title = "Your name"
                $0.placeholder = "Enter your name here"
                $0.onChange { [unowned self] row in
                    self.name = row.value ?? ""
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.cellUpdate { (cell, row) in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
            }
            <<< EmailRow(){
                $0.title = "Your email"
                $0.placeholder = "Enter your email here"
                $0.onChange { [unowned self] row in
                    self.email = row.value ?? ""
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.cellUpdate { (cell, row) in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
                }
            }
            <<< PickerInlineRow<String>(){
                $0.title = "Reason"
                $0.options = ["Question about the study", "Feature request", "Bug report", "Data request", "Other"]
                $0.value = $0.options[0]
                self.reason = $0.options[0]
                $0.onChange { [unowned self] row in
                    self.reason = row.value ?? ""
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.cellUpdate { (cell, row) in
                    if !row.isValid {
                        cell.textLabel?.textColor = .red
                    }
                }
            }
            <<< TextAreaRow(){
                $0.placeholder = "Type your message"
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 200)
                $0.onChange { [unowned self] row in
                    self.message = row.value ?? ""
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.cellUpdate { (cell, row) in
                    if !row.isValid {
                        cell.textLabel?.textColor = .red
                    }
                }
            }
            +++ Section()
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                row.title = "Send message"
            }.onCellSelection { [weak self] (cell, row) in
                print("clicked on send button")
                guard let strongSelf = self else { return }
                if strongSelf.form.validate().isEmpty {
                    let parameters: Parameters = [
                        "device": UIDevice.current.modelName,
                        "version": UIDevice.current.systemVersion,
                        "uuid": Settings.getUUID() ?? "",
                        "userid": Settings.getUserId() ?? "",
                        "name": strongSelf.name,
                        "email": strongSelf.email,
                        "reason": strongSelf.reason,
                        "message": strongSelf.message
                    ]
                    
                    Alamofire.request(Constants.urls.sendMailURL, method: .post, parameters: parameters, encoding: JSONEncoding.default)
                        .responseJSON { response in
                            if response.result.isSuccess {
                                let alert = UIAlertController(title: "Message sent", message: "Thank you for getting in touch with us, we will get back to you shortly.", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default) { alertAction in
                                    strongSelf.navigationController?.popViewController(animated: true)
                                })
                                strongSelf.present(alert, animated: true, completion: nil)
                            }
                    }
                } else {
                    print("form is not valid")
                }
            }
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

public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "i386", "x86_64":                          return "Simulator"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}
