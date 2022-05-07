//
//  ViewController.swift
//  WindowsStyleManager
//
//  Created by EVGENII Loshchenko on 16.06.2021.
//

import Cocoa
import CoreFoundation

protocol NSTableViewClickableDelegate: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, didClickRow row: Int, didClickColumn: Int, commandPressed: Bool)
}

class ELTabBarTable: NSTableView {
    override func mouseDown(with event: NSEvent) {
        let localLocation = self.convert(event.locationInWindow, to: nil)
        let clickedRow = self.row(at: localLocation)
        let clickedColumn = self.column(at: localLocation)

        super.mouseDown(with: event)

        guard clickedRow >= 0, clickedColumn >= 0, let delegate = self.delegate as? NSTableViewClickableDelegate else {
            return
        }
        let openWindowNotCollapsingOthersBorderWidth = 24.0
        
        var commandPressed = event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command
        if event.locationInWindow.x < openWindowNotCollapsingOthersBorderWidth {
            commandPressed = true
        }
        
        delegate.tableView(self, didClickRow: clickedRow, didClickColumn: clickedColumn, commandPressed: commandPressed)
    }
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTableViewClickableDelegate {
    
    @IBOutlet var tableView: NSTableView!
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet var textLabel : NSTextField!
    
    var openedWindows: [ELWindow] = []
    var openedApplications: [ELWindow] = []
    
    let defaultTaskBarWidth: CGFloat = 140
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { event in
            if self.hideAllLocationMatch(mouseLocation: event.locationInWindow) {
                ELWindowListManager.hideAll()
            }
        }
        
        fixTaskBarWindowPosition()
        
        ViewController.fixWindowSize(forWidth: self.view.window?.frame.width ?? self.defaultTaskBarWidth)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            ELWindowListManager.updateCurrentWindows()
            ViewController.fixWindowSize(forWidth: self.view.window?.frame.width ?? self.defaultTaskBarWidth)
            self.openedWindows = ELWindowListManager.openedWindows()
            self.tableView.reloadData()
        }
    }
    
    func fixTaskBarWindowPosition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.view.window?.setFrame(CGRect(x: 0, y: 0, width: self.defaultTaskBarWidth, height: ELScreenWrapper.height()), display: true)
        }
    }
    
    func hideAllLocationMatch(mouseLocation: NSPoint) -> Bool {
        return mouseLocation.x > ELScreenWrapper.width() - ELWindowListManager.toolbarHeight && mouseLocation.y < ELWindowListManager.toolbarHeight
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return openedWindows.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? TabBarTableViewCell
        var title = openedWindows[row].windowTitle ?? ""
        if title.isEmpty {
            title = openedWindows[row].appName
        }
        cell?.textField1?.stringValue = title
        cell?.imageView1.image = openedWindows[row].icon
        return cell
    }

    func tableView(_ tableView: NSTableView, didClickRow row: Int, didClickColumn: Int, commandPressed: Bool) {
        ELWindowListManager.selectWindow(self.openedWindows[row], shouldHideOthers: !commandPressed)
    }
    
    static func fixWindowSize(forWidth tabBarWidth: CGFloat) {
        for application in ELWindowListManager.currentApplicationsWithWindows.values {
            for AXUIwindow in application.windows {
                
                let size: CGSize! = AXUIWindowWrapper.windowSize(AXUIwindow)
                let position: CGPoint! = AXUIWindowWrapper.windowPosition(AXUIwindow)
                guard size != nil else {
                    return
                }
                guard position != nil else {
                    return
                }
                if size.height != ELScreenWrapper.height() {
                    let dif = position.x - tabBarWidth
                    if position.x < tabBarWidth {
                        var x: CGFloat = 0
                        var width: CGFloat = 0.0
                        if dif < tabBarWidth + ELScreenWrapper.width() {
                            x = tabBarWidth
                            width = size.width
                        } else {
                            x = tabBarWidth
                            width = ELScreenWrapper.width() - tabBarWidth
                        }
                        width = min(width, ELScreenWrapper.width() - tabBarWidth)
                        let newPosition = CGPoint(x: x, y: position.y)
                        let newSize = CGSize(width: width, height: size.height)
                        AXUIWindowWrapper.windowSetPosition(AXUIwindow, point: newPosition)
                        AXUIWindowWrapper.windowSetPositionSize(AXUIwindow, sgSize: newSize)
                    }
                }
            }
        }
    }
}
