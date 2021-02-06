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

            var ram = [Byte](repeating: 0, count: 4096)

            let fontBytes = Font.bytes
            ram.replaceSubrange(0..<fontBytes.count, with: fontBytes)

            let romBytes = [Byte](contents)
            ram.replaceSubrange(0x200..<0x200+romBytes.count, with: romBytes)

            return ram
        } catch {
            // contents could not be loaded
            print("Rom not found: " + path)
            return []
        }
    }
}
