//
//  PedometerSettingsViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 4/24/18.
//  Copyright © 2018 Benjamin BARON. All rights reserved.
//

import Eureka
import UIKit

class PedometerSettingsViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        form +++ Section("Daily goals")
            <<< StepperRow() {
                let steps = Settings.getPedometerStepsGoal()
                $0.tag = "step"
                $0.cell.stepper.stepValue = 100
                $0.cell.stepper.minimumValue = 100
                $0.cell.stepper.maximumValue = 100000
                $0.cell.valueLabel?.text = "\(steps)"
                $0.title = "Step goal"
                $0.value = Double(steps)
                $0.cellUpdate { (cell, row) in
                    cell.valueLabel?.text = "\(Int(row.value!))"
                }
            }
            <<< StepperRow() {
                let distance = Settings.getPedometerDistanceGoal()
                $0.tag = "distance"
                $0.cell.stepper.stepValue = 0.1
                $0.cell.stepper.minimumValue = 0.1
                $0.cell.stepper.maximumValue = 100000
                $0.title = "Distance goal (km)"
                $0.value = distance
            }
            <<< StepperRow() {
                let time = Settings.getPedometerTimeGoal()
                $0.tag = "time"
                $0.cell.stepper.stepValue = 5
                $0.cell.stepper.minimumValue = 5
                $0.cell.stepper.maximumValue = 1440
                $0.cell.valueLabel?.text = "\(time)"
                $0.title = "Duration goal (min)"
                $0.value = Double(time)
                $0.cellUpdate { (cell, row) in
                    cell.valueLabel?.text = "\(Int(row.value!))"
                }
            }
            +++ Section("Configuration")
            <<< SegmentedRow<String>() {
                $0.tag = "unit"
                $0.title = "Distance unit     "
                $0.options = ["Miles", "Kilometers"]
                $0.value = Settings.getPedometerUnit()
            }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LogService.shared.log(LogService.types.settingsPedometer)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let values = form.values()
        let steps = Int(values["step"] as! Double)
        let distance = values["distance"] as! Double
        let time = Int(values["time"] as! Double)
        let unit = values["unit"] as! String
        Settings.savePedometerStepsGoal(with: steps)
        Settings.savePedometerDistanceGoal(with: distance)
        Settings.savePedometerTimeGoal(with: time)
        Settings.savePedometerUnit(with: unit)
        
        LogService.shared.log(LogService.types.settingsPedometer, args: [LogService.args.pedometerSteps: "\(steps)", LogService.args.pedometerDistance: "\(distance)", LogService.args.pedometerTime: "\(time)", LogService.args.pedometerUnit: unit])
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
