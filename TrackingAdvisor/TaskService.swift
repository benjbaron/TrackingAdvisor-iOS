//
//  TaskService.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/9/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//
// From
// https://github.com/pmwisdom/cordova-background-geolocation-services/blob/master/src/ios/CDVBackgroundLocationServices.swift
//

import Foundation

class TaskService : NSObject {
    static let shared = TaskService()
    
    // let priority = DispatchQueue.GlobalAttributes.qosUserInitiated
    var _bgTaskList = [Int]()
    var _masterTaskId = UIBackgroundTaskInvalid
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
        let app = UIApplication.shared
        
        var bgTaskId = UIBackgroundTaskInvalid
        
        if(app.responds(to: Selector(("beginBackgroundTask")))) {
            bgTaskId = app.beginBackgroundTask(expirationHandler: {
                FileService.shared.log("Background task \(bgTaskId) expired", classname: "TaskManager")
            })
            if(self._masterTaskId == UIBackgroundTaskInvalid) {
                self._masterTaskId = bgTaskId
                FileService.shared.log("Started Master Task ID \(self._masterTaskId)", classname: "TaskManager")
            } else {
                FileService.shared.log("Started Background Task \(bgTaskId)", classname: "TaskManager")
                self._bgTaskList.append(bgTaskId)
                self.endBackgroundTasks()
            }
        }
        
        return bgTaskId
    }
    
    func endBackgroundTasks() {
        self.drainBGTaskList(all: false)
    }
    
    func endAllBackgroundTasks() {
        self.drainBGTaskList(all: true)
    }
    
    func drainBGTaskList(all:Bool){
        let app = UIApplication.shared
        if(app.responds(to: Selector(("endBackgroundTask")))) {
            let count = self._bgTaskList.count
            
            for _ in 0 ..< count {
                let bgTaskId = self._bgTaskList[0] as Int
                FileService.shared.log("Ending Background Task  with ID \(bgTaskId)", classname: "TaskManager")
                app.endBackgroundTask(bgTaskId)
                self._bgTaskList.remove(at: 0)
            }
            
            if(self._bgTaskList.count > 0) {
                FileService.shared.log("Background Task Still Active \(self._bgTaskList[0])", classname: "TaskManager")
            }
            
            if(all) {
                FileService.shared.log("Killing Master Task \(self._masterTaskId)", classname: "TaskManager")
                app.endBackgroundTask(self._masterTaskId)
                self._masterTaskId = UIBackgroundTaskInvalid
            } else {
                FileService.shared.log("Kept Master Task ID \(self._masterTaskId)", classname: "TaskManager")
            }
        }
        
    }
}
