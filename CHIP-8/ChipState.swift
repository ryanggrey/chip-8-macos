//
//  ChipState.swift
//  CHIP-8
//
//  Created by Ryan Grey on 01/02/2021.
//

import Foundation

struct ChipState {
    // 4K memory
    // public var ram = [Byte](repeating: 0, count: 4096)
    // 16 variables
    public var v = [Byte](repeating: 0, count: 16)
    public var i: Word = 0
    // Roms loaded into 0x200. Memory prior to this is reserved (for font etc)
    public var pc: Word = 0x200
    // 64x32 screen
    public var pixels = [Byte](repeating: 0, count: 64 * 32)
    public var delayTimer: Byte = 0
    public var soundTimer: Byte = 0
    // 12 or 16 sized stack in real Chip-8, but allow this to grow dynamically
    public var stack = [Word]()
    // 16 key inputs
    public var keys = [Byte](repeating: 0, count: 16)
}
