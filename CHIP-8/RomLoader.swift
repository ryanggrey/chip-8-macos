//
//  RomLoader.swift
//  CHIP-8
//
//  Created by Ryan Grey on 23/01/2021.
//

import Foundation

public struct RomLoader {
    public static func read(romPath path: String) -> [Byte] {
        guard FileManager.default.fileExists(atPath: path) else {
            print("Rom not found: " + path)
            return []
        }

        do {
            let url = URL(fileURLWithPath: path)
            let contents = try Data(contentsOf: url)
            let romBytes = [Byte](contents)
            let leadingRam = [Byte](repeating: 0, count: 0x200)
            var ram = leadingRam + romBytes

            let fontBytes = Font.bytes
            ram.replaceSubrange(0..<fontBytes.count, with: fontBytes)
            return ram
        } catch {
            // contents could not be loaded
            print("Rom not found: " + path)
            return []
        }
    }
}
