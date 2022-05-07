//
//  AXUIWindowWrapper.swift
//  WindowsStyleManager
//
//  Created by EVGENII Loshchenko on 04.05.2022.
//

import Cocoa

class AXUIWindowWrapper {
    
    static func windowSize(_ window: AXUIElement) -> CGSize? {
        var axSize: AnyObject!
        _ = AXUIElementCopyAttributeValue(window as AXUIElement, kAXSizeAttribute as CFString, &axSize)
        if axSize != nil {
            return AXValueGetters.asCGSize(value: axSize as! AXValue)
        }
        return nil
    }
    
    static func windowPosition(_ window: AXUIElement) -> CGPoint? {
        var axPosition: AnyObject!
        _ = AXUIElementCopyAttributeValue(window as AXUIElement, kAXPositionAttribute as CFString, &axPosition)
        if axPosition != nil {
            return AXValueGetters.asCGPoint(value: axPosition as! AXValue)
        }
        return nil
    }
    
    static func windowSetPosition(_ window: AXUIElement, point: CGPoint) {
        var newPoint = point
        var position: CFTypeRef
        position = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
    }
    
    static func windowSetPositionSize(_ window: AXUIElement, sgSize: CGSize) {
        var size : CFTypeRef
        var newSize = sgSize
        size = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, size)
    }
}
