//
//  ELApiWrapper.swift
//  WindowsStyleManager
//
//  Created by EVGENII Loshchenko on 21.06.2021.
//

import Cocoa

class AXValueGetters {

    class func asCGRect(value: AXValue) -> CGRect {
        var val = CGRect.zero
        AXValueGetValue(value, AXValueType.cgRect, &val)
        return val
    }

    class func asCGPoint(value: AXValue) -> CGPoint {
        var val = CGPoint.zero
        AXValueGetValue(value, AXValueType.cgPoint, &val)
        return val
    }

    class func asCFRange(value: AXValue) -> CFRange {
        var val = CFRange(location: 0, length: 0)
        AXValueGetValue(value, AXValueType.cfRange, &val)
        return val
    }

    class func asCGSize(value: AXValue) -> CGSize {
        var val = CGSize.zero
        AXValueGetValue(value, AXValueType.cgSize, &val)
        return val
    }
}
