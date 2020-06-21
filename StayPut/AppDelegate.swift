//
//  AppDelegate.swift
//  MonMem
//
//  Created by Steve Wiley on 2/29/20.
//  Copyright © 2020 Steve Wiley. All rights reserved.
//

import Cocoa
import SwiftUI
import os

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var displayConfigs: [String: DisplayConfig] = [:]
    
    fileprivate func registerCallbacks() {
        let dnc = DistributedNotificationCenter.default()
        
        dnc.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) {
            notification in
            self.onLocked(notification: notification)
        }
        
        dnc.addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) {
            notification in
            self.onUnlocked(notification: notification)
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        os_log("entered appliationWillFinishLaunching()")
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            os_log("applicationWillFinishLaunching(): Access Not Enabled")
        }
        
        registerCallbacks()

        os_log("exited applicationWillFinishLaunching()")
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        os_log("entered applicationDidFinishLaunching()")
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()
        
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
       
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "Icon")
            button.action = #selector(togglePopover(_:))
        }
        
        constructMenu()
        os_log("exited appliationDidFinishLaunching()")
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        os_log("entered togglePopover()")
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
        os_log("exited togglePopover()")
    }
       
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Snapshot", action: #selector(snapshot), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Restore", action: #selector(restore), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        statusBarItem.button?.toolTip = "StayPut"
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        os_log("entered applicationWillTerminate()")
    }

    func getActiveDisplays() -> [CGDirectDisplayID] {
        os_log("entered getActiveDisplays()")
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        os_log("Found %{public}d displays", displayCount)
        
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)

        var ret = [CGDirectDisplayID]()
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        if result != CGError.success {
            os_log("ERROR: Failed to get displays via CGGetActiveDisplayList()")
            return ret
        }

        var ptr = activeDisplays
        for _ in 0 ..< displayCount {
            ret.append(ptr.pointee)
            ptr = ptr.successor()
        }
        
        activeDisplays.deallocate()
        os_log("exited getActiveDisplays()")
        return ret
    }

    @objc func restore() {
        os_log("entered restore()")
        
        let displays = getActiveDisplays()
        let key = DisplayConfig.makeKey(displays: displays)
        
        if displayConfigs[key] != nil {
            os_log("restore(): Found matching display configuration, moving windows")
            let displayConfig = displayConfigs[key]
            for process in (displayConfig?.processes)! {
                process.repositionWindows()
            }
        } else {
            os_log("restore(): No matching display configuration found")
        }
        os_log("exited restore()")
    }
    
    @objc func onUnlocked(notification: Notification) {
        os_log("entered onUnlocked(notification) with %{public}s", notification.name.rawValue)
        restore()
        os_log("exited onUnlocked(notification)")
    }

    @objc func snapshot() {
        let displays = getActiveDisplays()
        let key = DisplayConfig.makeKey(displays: displays)

        displayConfigs[key] = DisplayConfig(displays: displays, processes: Process.getProcesses())
    }

    func onLocked(notification: Notification) {
        os_log("entered onLocked() with %{public}s", notification.name.rawValue)
        snapshot()
        os_log("exited onLocked()")
    }
}

