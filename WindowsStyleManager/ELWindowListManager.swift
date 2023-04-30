//
//  ELWindowListManager.swift
//  WindowsStyleManager
//
//  Created by EVGENII Loshchenko on 17.06.2021.
//

import Cocoa
import CoreFoundation

class ELWindow {
    var window: AXUIElement!
    var appName: String!
    var windowTitle: String!
    var icon: NSImage?
}

class AppWrapper {
    var name: String!
    var windows: [AXUIElement] = [AXUIElement]()
    var pid:Int32 = -1
    var appRef: AXUIElement!
    var icon: NSImage?
}

class ELScreenWrapper {
    
    static func width() -> CGFloat {
        return NSScreen.main?.frame.width ?? 1920
    }
    
    static func height() -> CGFloat {
        return NSScreen.main?.frame.height ?? 1080
    }
}

class ELWindowListManager: NSObject {

    static var toolbarHeight: CGFloat = 29
    static let tabBarHeight: CGFloat = 30
    
    static var currentApplicationsWithWindows = getWindows()
    
    static func updateCurrentWindows() {
        currentApplicationsWithWindows = getWindows()
    }
    
    static func getWindows() -> [String: AppWrapper] {
        
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements)
        let windowListInfo: [[String: AnyObject]] = CGWindowListCopyWindowInfo(options, CGWindowID(0)) as? [[String: AnyObject]] ?? []
        
        var processedApplications = [String]()
        
        var applicationsWithWindows = [AppWrapper]()
        
        var applicationToSkipUI = [String]()
        applicationToSkipUI.append("WindowsStyleManager")
        applicationToSkipUI.append("uBar")
//        print(windowListInfo)
        for systemWindowData in windowListInfo {
            let appName = systemWindowData["kCGWindowOwnerName"] as? String ?? ""
            if !processedApplications.contains(appName) {
                if applicationToSkipUI.contains(appName) {
                    continue
                }
                
                processedApplications.append(appName)
                
                let pid = systemWindowData["kCGWindowOwnerPID"] as? Int32 ?? -1
                if pid != -1 {
                    let application = AppWrapper()
                    applicationsWithWindows.append(application)
                    
                    application.name = appName
                    application.pid = systemWindowData["kCGWindowOwnerPID"] as? Int32 ?? -1
                    application.icon = NSRunningApplication(processIdentifier: application.pid)?.icon
                    let appRef = AXUIElementCreateApplication(pid);
                    application.appRef = appRef
                    application.windows = AXUIwindows(pid: pid, appRef: appRef, appName: appName)
                }
            }
        }
        var applicationDictionary = [String: AppWrapper]()
        for appWrapper in applicationsWithWindows {
            applicationDictionary[appWrapper.name] = appWrapper
        }
        
        return applicationDictionary
    }
    
    static func AXUIwindows(pid: Int32, appRef: AXUIElement, appName: String) -> [AXUIElement] {
        var AXUIwindowList = [AXUIElement]()
        var value: AnyObject?
        
        var xcodeProjectsPaths = [String]()
//        xcodeProjectsPaths.append("file:///Users/username/Documents/git/WindowsStyleManager/") // add your project paths to fix duplicated tabs problem
        
        var skipXcodeWindowsKeys = [String]()
        
        _ = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)
        if let windowList = value as? [AXUIElement] {
            
            var windowsDictionary = [String:AXUIElement]()
            
            for AXUIwindow in windowList {
                if self.copyAXUIElementValue(element: AXUIwindow, key: "AXRole") == "" {
                    continue
                }
                let title = self.copyAXUIElementValue(element: AXUIwindow, key: "AXTitle")
                if appName == "Finder" && title == nil {
                    continue
                }
                
                var skipWindow = false
                if appName == "Xcode" {
                    let properties = copyAXUIElementProperties(element: AXUIwindow, appRef: appRef) ?? []
                    
                    for property in properties {
                        let value = self.copyAXUIElementValue(element: AXUIwindow, key: property)
                        
                        if property == "AXDocument" {
                            
                            for projectPath in skipXcodeWindowsKeys {
                                if (value ?? "").contains(projectPath) {
                                    skipWindow = true
                                }
                            }
                            if !skipWindow {
                                for projectPath in xcodeProjectsPaths {
                                    if (value ?? "").contains(projectPath) {
                                        skipXcodeWindowsKeys.append(projectPath)
                                    }
                                }
                            }
                        }
                    }
                }
                if skipWindow {
                    continue
                }
                windowsDictionary[title ?? ""] = AXUIwindow
                
            }
            for title in windowsDictionary.keys.sorted() {
                AXUIwindowList.append(windowsDictionary[title]!)
            }
        }
        return AXUIwindowList
    }
    
    static func selectWindow(_ window: ELWindow, shouldHideOthers: Bool) {
        
        if let appWrapper = self.currentApplicationsWithWindows[window.appName] {
            
            for AXUIwindow in appWrapper.windows {
                let title = self.copyAXUIElementValue(element: AXUIwindow, key: "AXTitle") ?? "no data"
                if title == window.windowTitle {
                    AXUIElementSetAttributeValue(AXUIwindow, "AXHidden" as CFString, kCFBooleanFalse)
                    AXUIElementSetAttributeValue(AXUIwindow, "AXMinimized" as CFString, kCFBooleanFalse)
                    NSRunningApplication(processIdentifier: appWrapper.pid)?.activate(options: NSApplication.ActivationOptions.activateIgnoringOtherApps)
                    AXUIElementSetAttributeValue(AXUIwindow, NSAccessibility.Attribute.main as CFString, kCFBooleanTrue)
                }
                else {
                    if shouldHideOthers {
                        AXUIElementSetAttributeValue(AXUIwindow, "AXHidden" as CFString, kCFBooleanTrue)
                        AXUIElementSetAttributeValue(AXUIwindow, "AXMinimized" as CFString, kCFBooleanTrue)
                    }
                }
            }
        }
    }
    
    static func openedWindows() -> [ELWindow] {
        
        var opendWindowsList = [ELWindow]()
        
        let applicationNames = self.currentApplicationsWithWindows.keys.sorted()
        for appName in applicationNames {
            
            if let appWrapper = self.currentApplicationsWithWindows[appName] {
                for AXUIwindow in appWrapper.windows {
                    let window = ELWindow()
                    window.window = AXUIwindow
                    window.windowTitle = self.copyAXUIElementValue(element: AXUIwindow, key: "AXTitle") ?? "no data"
                    window.appName = appName
                    window.icon = appWrapper.icon
                    opendWindowsList.append(window)
                }
            }
        }
        return opendWindowsList
    }
    
    static func copyAXUIElementValue(element: AXUIElement, key: String) -> String? {
        var axValue: AnyObject?
        AXUIElementCopyAttributeValue(element, key as CFString, &axValue)
        return axValue as? String
    }
    
    static func copyAXUIElementProperties(element: AXUIElement, appRef: AXUIElement) -> [String]? {
        var ans : CFArray?
        _ = AXUIElementCopyAttributeNames(element, &ans)
        return ans as? [String]
    }
    
    static func hideAll() {
        let applicationNames = self.currentApplicationsWithWindows.keys
        for appName in applicationNames {
            
            if let appWrapper = self.currentApplicationsWithWindows[appName] {
                for AXUIwindow in appWrapper.windows {
                    AXUIElementSetAttributeValue(AXUIwindow, "AXHidden" as CFString, kCFBooleanTrue)
                    AXUIElementSetAttributeValue(AXUIwindow, "AXMinimized" as CFString, kCFBooleanTrue)
                }
            }
        }
    }
}
