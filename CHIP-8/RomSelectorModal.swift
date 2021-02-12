//
//  Rom.swift
//  CHIP-8
//
//  Created by Ryan Grey on 23/01/2021.
//

import Foundation
import AppKit
import Chip8Emulator

public struct RomSelectorModal {

    public static func runModal(onDataLoad: @escaping ([Byte]) -> Void) {
        let dialog = NSOpenPanel();

        dialog.title = "Choose a rom";
        dialog.showsResizeIndicator = true;
        dialog.showsHiddenFiles = false;
        dialog.allowsMultipleSelection = false;
        dialog.canChooseDirectories = false;

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            guard let path = dialog.url?.path else {
                print("Cannot get path of file")
                return
            }

            let loadedRom = RomLoader.read(romPath: path)
            onDataLoad(loadedRom)
        }
    }
}
