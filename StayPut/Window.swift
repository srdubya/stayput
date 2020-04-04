//
//  Window.swift
//  MonMem
//
//  Created by Steve Wiley on 3/14/20.
//  Copyright © 2020 Steve Wiley. All rights reserved.
//
import Foundation
import os

class Window {
    var title: String
    var bounds: CGSize
    var origin: CGPoint
    
    init(_ title: String, _ bounds: CGSize, _ origin: CGPoint) {
        self.title = title
        self.bounds = bounds
        self.origin = origin
    }
    
    fileprivate class func getTitleAttribute(_ window: AXUIElement) -> String {
        var tmp: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &tmp)
        if tmp == nil {
            return ""
        }
        return tmp as! String
    }
    
    fileprivate class func getOriginAttribute(_ window: AXUIElement) -> CGPoint {
        let tmp = getAXValue(window, attributeName: kAXPositionAttribute)!
        var point = CGPoint()
        AXValueGetValue(tmp, .cgPoint, &point)
        return point
    }
    
    fileprivate class func setOriginAttribute(of window: AXUIElement, toThatOf savedWindow: Window) {
        var origin = CGPoint(x: savedWindow.origin.x, y: savedWindow.origin.y)
        let position = AXValueCreate(
            AXValueType(rawValue: kAXValueCGPointType)!,
            &origin
            ) as CFTypeRef
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
    }
    
    fileprivate class func getAXValue(_ window: AXUIElement, attributeName atName: String) -> AXValue? {
        var tmp: AnyObject?
        AXUIElementCopyAttributeValue(window, atName as CFString, &tmp)
        return (tmp as! AXValue)
    }
    
    fileprivate class func getSizeAttribute(_ window: AXUIElement) -> CGSize {
        let tmp = getAXValue(window, attributeName: kAXSizeAttribute)!
        var size = CGSize()
        AXValueGetValue(tmp, .cgSize, &size)
        return size
    }
    
    fileprivate class func setSizeAttribute(of window: AXUIElement, toThatOf savedWindow: Window) {
        var size = CGSize(width: savedWindow.bounds.width, height: savedWindow.bounds.height)
        let newSize = AXValueCreate(
            AXValueType(rawValue: kAXValueCGSizeType)!,
            &size
            )! as CFTypeRef
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, newSize)
    }
    
    fileprivate class func getWindowList(_ app: AXUIElement) -> [AXUIElement] {
        var tmp: AnyObject?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &tmp)
        if result != AXError.success {
            NSLog("ERROR: Failed to get window list for process")
            return []
        }
        return (tmp as? [AXUIElement])!
    }

    class func getWindows(pid: Int32) -> [Window] {
        let appRef = AXUIElementCreateApplication(pid)

        var ret = [Window]()
        for window in getWindowList(appRef) {
            let windowTitle = getTitleAttribute(window)
            let bounds = getSizeAttribute(window)
            let origin = getOriginAttribute(window)
            if windowTitle.count == 0 {
                os_log("Window.getWindows(%{public}d), error getting window title", pid)
            } else {
                os_log("Window.getWindows(%{public}d), saving %{public}s", pid, windowTitle)
                ret.append(Window(windowTitle, bounds, origin))
            }
        }
        
        return ret
    }
        
    class func reposition(allFor pid: Int32, using savedWindows: [String:Window]) {
        let foundWindows = Window.getWindowList(AXUIElementCreateApplication(pid))
        for window in foundWindows {
            let title = Window.getTitleAttribute(window)
            if savedWindows[title] != nil {
                Window.setOriginAttribute(of: window, toThatOf: savedWindows[title]!)
                Window.setSizeAttribute(of: window, toThatOf: savedWindows[title]!)
            } else {
                os_log("Window.reposition(): unfound window: %{public}s", title)
            }
        }
    }
}
