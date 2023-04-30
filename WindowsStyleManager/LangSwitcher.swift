//
//  LangSwitcher.swift
//  WindowsStyleManager
//
//  Created by jack on 30.04.2023.
//

import Foundation

import Carbon

class LangSwitcher {
    
    static func getLayoutFromInputSourseU(sourse:  Unmanaged<TISInputSource>) -> String {
        var description = "\(sourse)".split(separator: "Layout: ")[1].dropLast()
        return "\(description)"
    }
    
    static func getLayoutFromInputSourse(sourse:  TISInputSource) -> String? {
        var descriptionArray = "\(sourse)".split(separator: "Layout: ")
        if descriptionArray.count > 1
        {
            return "\(descriptionArray[1])"
        }
        return nil
    }
    
    static func selectNextLang() {
        var current = TISCopyCurrentKeyboardInputSource()!

        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        var inputSourceList = inputSourceNSArray as! [TISInputSource]
        
        inputSourceList = inputSourceList.filter { sourse in
            return getLayoutFromInputSourse(sourse: sourse) != nil
        }
//        print(inputSourceList)
        var index = 0
        for lang in inputSourceList {
            
            index += 1
            if getLayoutFromInputSourse(sourse: lang) == getLayoutFromInputSourseU(sourse: current) {
                break
            }
        }
        index = index % inputSourceList.count
        TISSelectInputSource(inputSourceList[index])
    }
}
