//
//  DisplayConfig.swift
//  MonMem
//
//  Created by Steve Wiley on 3/14/20.
//  Copyright © 2020 Steve Wiley. All rights reserved.
//

import Foundation

class DisplayConfig {
    var displayNums: [CGDirectDisplayID]
    var processes = [Process]()
    
    init(displays: [CGDirectDisplayID], processes: [Process]) {
        self.displayNums = displays
        self.processes.append(contentsOf: processes)
    }
    
    class func makeKey(displays: [CGDirectDisplayID]) -> String {
        var ret = String(displays.count)
        for displayNum in displays {
            ret += "." + String(displayNum)
        }
        return ret
    }
    
    func key() -> String {
        return DisplayConfig.makeKey(displays: self.displayNums)
    }
    
    func isEqualTo(displayList: [CGDirectDisplayID]) -> Bool {
        if self.displayNums.count != displayList.count {
            return false
        }
        for i in 0 ..< displayList.count {
            if self.displayNums[i] != displayList[i] {
                return false
            }
        }
        return true
    }
}
