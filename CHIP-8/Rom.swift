//
//  Rom.swift
//  CHIP-8
//
//  Created by Ryan Grey on 23/01/2021.
//

import Foundation

public struct Rom {
    public static func read(_ romName: String) -> [Byte] {
        guard let filepath = Bundle.main.path(forResource: romName, ofType: "ch8") else {
            print("Rom not found: " + romName)
            return []
        }

        do {
            let url = URL(fileURLWithPath: filepath)
            let contents = try Data(contentsOf: url)
            let romBytes = [Byte](contents)
            // TODO: load the fontset into the first 80 bytes
            let leadingRam = [Byte](repeating: 0, count: 0x200)
            let ram = leadingRam + romBytes
            return ram
        } catch {
            // contents could not be loaded
            print("Rom not found: " + romName)
            return []
        }
    }
}
