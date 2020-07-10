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
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.level = .floating
    }
}
