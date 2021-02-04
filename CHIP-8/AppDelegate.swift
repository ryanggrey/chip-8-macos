//
//  AppDelegate.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let window = NSApp.mainWindow
        window?.aspectRatio = NSSize(width: 2, height: 1)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}

