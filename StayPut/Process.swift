//
//  Process.swift
//  MonMem
//
//  Created by Steve Wiley on 3/15/20.
//  Copyright © 2020 Steve Wiley. All rights reserved.
//

import Foundation
import os

class Process {
    var pid: Int32
    var windows: [String:Window]
    
    init(_ pid: Int32) {
        self.pid = pid
        self.windows = [:]
    }
    
    class func getProcesses() -> [Process] {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowsListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let infoList = windowsListInfo as! [[String:Any]]
        let visibleWindows = infoList.filter{ $0["kCGWindowLayer"] as! Int == 0 }
        
        return fromWindowList(list: visibleWindows)
    }
    
    fileprivate class func fromWindowList(list: [[String:Any]]) -> [Process] {
        var processIds: [Int32: Bool] = [:]
        for window in list {
            processIds[window[kCGWindowOwnerPID as String] as! Int32] = true
        }

        var ret = [Process]()
        for processId in processIds.keys {
            let newProcess = Process(processId)
            newProcess.addWindows()
            ret.append(newProcess)
        }
        return ret
    }
    
    func addWindows() {
        for window in Window.getWindows(pid: self.pid) {
            if self.windows[window.title] != nil {
                os_log("Process.addWindows(): Warning, duplicate window title: %{public}s", window.title)
            }
            self.windows[window.title] = window
        }
    }
    
    func repositionWindows() {
        Window.reposition(allFor: pid, using: windows)
    }
}
