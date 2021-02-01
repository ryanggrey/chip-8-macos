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
        // TODO: allow loading of any rom
        let loadedRom = Rom.read("Fishie")
        Disassembler.disassemble(codeBuffer: loadedRom)
        let chip8 = Chip8()
        // TODO: run the chip
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

