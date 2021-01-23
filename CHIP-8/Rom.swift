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
            let byteData = [Byte](contents)
            print(contents)
            return byteData
        } catch {
            // contents could not be loaded
            print("Rom not found: " + romName)
            return []
        }
    }
}
