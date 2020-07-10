//
//  CustomWindow.swift
//  PokerNowGrabber
//
//  Created by PJ Gray on 7/9/20.
//  Copyright © 2020 Say Goodnight Software. All rights reserved.
//

import Cocoa

class CustomWindow: NSWindow {

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
//        super.init(contentRect: contentRect, styleMask: [.resizable, .titled], backing: backingStoreType, defer: flag)
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)

        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.level = .floating

        
        
        if let info = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[ String : Any]] {
            for dict in info {
                if let ownerName = dict["kCGWindowOwnerName"] as? String, ownerName.contains("Chrome"), let rect = dict["kCGWindowBounds"] as? [String:Any], let height = rect["Height"] as? Int, let width = rect["Width"] as? Int, let x = rect["X"] as? Int, let y = rect["Y"] as? Int, height > 100 {
                    DispatchQueue.main.async {
                        let newFrame = CGRect(x: x, y: y, width: width, height: height)
                        self.setFrame( newFrame, display: true, animate: false)
                    }
                }
            }
        }
        
        

    }
}
