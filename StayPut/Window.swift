//
//  Window.swift
//  MonMem
//
//  Created by Steve Wiley on 3/14/20.
//  Copyright © 2020 Steve Wiley. All rights reserved.
//
import Foundation
import os
import SwiftUI


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
        let tmp = getAXValue(window, attributeName: kAXPositionAttribute)
        var point = CGPoint()
        if tmp == nil {
            return point
        }
        AXValueGetValue(tmp!, .cgPoint, &point)
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
        let retValue = AXUIElementCopyAttributeValue(window, atName as CFString, &tmp)
        if retValue != AXError.success || tmp == nil {
            return nil
        }
        return (tmp as! AXValue)
    }
    
    fileprivate class func getSizeAttribute(_ window: AXUIElement) -> CGSize {
        let tmp = getAXValue(window, attributeName: kAXSizeAttribute)
        var size = CGSize()
        if tmp == nil {
            return size
        }
        AXValueGetValue(tmp!, .cgSize, &size)
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
            if windowTitle.count == 0 {
                os_log("Window.getWindows(%{public}d), error getting window title", pid)
                continue
            }
            let bounds = getSizeAttribute(window)
            if bounds.height.isNaN || bounds.width.isNaN {
                os_log("Window.getWindows(%{public}d), error getting size of `%{public}s`", pid, windowTitle)
                continue
            }
            let origin = getOriginAttribute(window)
            if origin.x.isNaN || origin.y.isNaN {
                os_log("Window.getWindows(%{public}d), error getting origin of `%{public}s`", pid, windowTitle)
                continue
            }
            os_log("Window.getWindows(%{public}d), saving %{public}s", pid, windowTitle)
            ret.append(Window(windowTitle, bounds, origin))
        }
        
        return ret
    }


    private static let gmailTitle = "inbox ("
    private class func isGmailInbox(_ to: String, _ title: String) -> Bool {
        to.prefix(gmailTitle.count) == title.prefix(gmailTitle.count)
    }

    private class func isSlackWindow(_ to: String, _ title: String) -> Bool {
        to.replacingOccurrences(of: "*", with: "") == title.replacingOccurrences(of: "*", with: "")
    }

    typealias CallbackForTitle = (Window?) -> Void

    class func forMatching(to: String, savedWindows: [String:Window], selector:CallbackForTitle) {
        let to = to.lowercased()
        for key in savedWindows.keys {
            let lcTitle = key.lowercased()
            if to == lcTitle {
                os_log("Window.reposition() - title match: moving window '%{public}s'", key)
                selector(savedWindows[key])
                return
            }
            if isGmailInbox(to, lcTitle) {
                os_log("Window.reposition() - gmail inbox: moving window '%{public}s'", key)
                selector(savedWindows[key])
                return
            }
            if isSlackWindow(to, lcTitle) {
                os_log("Window.reposition() - slack window: moving window '%{public}s'", key)
                selector(savedWindows[key])
                return
            }
        }
        os_log("Window.reposition(): window '%{public}s' not found", to)
    }

        
    class func reposition(allFor pid: Int32, using savedWindows: [String:Window]) {
        let foundWindows = Window.getWindowList(AXUIElementCreateApplication(pid))
        for window in foundWindows {
            Window.forMatching(to: Window.getTitleAttribute(window), savedWindows: savedWindows, selector: {(savedWindow) in
                Window.setOriginAttribute(of: window, toThatOf: savedWindow!)
                Window.setSizeAttribute(of: window, toThatOf: savedWindow!)
            })
//            let title = Window.getTitleAttribute(window)
//            if savedWindows[title] != nil {
//                Window.setOriginAttribute(of: window, toThatOf: savedWindows[title]!)
//                Window.setSizeAttribute(of: window, toThatOf: savedWindows[title]!)
//            } else {
//                os_log("Window.reposition(): unfound window: %{public}s", title)
//            }
        }
    }
}
