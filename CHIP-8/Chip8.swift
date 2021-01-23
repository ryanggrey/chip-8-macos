//
//  Chip8.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Foundation

public struct Chip8 {
    private var ram: [Byte]
    private var v = [Byte](repeating: 0, count: 16) // 16 registers, each register is 1 byte / 8 bits
    private var i: Word = 0

    //0x000-0x1FF - Chip 8 interpreter (contains font set in emu)
    //0x050-0x0A0 - Used for the built in 4x5 pixel font set (0-F)
    //0x200-0xFFF - Program ROM and work RAM
    private var pc: Word = 0x200

    private let width: Int
    private let height: Int
    private let pixels: [Byte]

    private var delayTimer: Byte = 0
    private var soundTimer: Byte = 0

    // 16 levels of stack
    private var stack = [Byte](repeating: 0, count: 12)
    private var stackPointer: Byte = 0

    private var key = [Byte](repeating: 0, count: 16)

    init(memorySize: Int = 4096, width: Int = 64, height: Int = 32, rom: [Byte]) {
        // initialize memory
        ram = [Byte](repeating: 0, count: memorySize) // 4096 bytes
        // initialize graphics
        self.width = width
        self.height = height
        pixels = [Byte](repeating: 0, count: width * height)

        // TODO: load the fontset into the first 80 bytes

        // TODO: copy program (rom) into ram starting at byte 512 by convention
    }

    public static func disassembleOp(codeBuffer: [Byte], pc: Word) {
        let code = codeBuffer[pc]
    }
}

extension Array {
    subscript(place: Word) -> Element {
        get {
            return self[Int(place)]
        }
        set {
            self[Int(place)] = newValue
        }
    }

    subscript(place: Byte) -> Element {
        get {
            return self[Int(place)]
        }
        set {
            self[Int(place)] = newValue
        }
    }
}
