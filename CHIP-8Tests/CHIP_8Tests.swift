//
//  CHIP_8Tests.swift
//  CHIP-8Tests
//
//  Created by Ryan Grey on 22/01/2021.
//

import XCTest
@testable import CHIP_8

class CHIP_8Tests: XCTestCase {

    func test_CLS_clears_pixels() {
        let ram = ramWithOp(0x00, 0x00, 0x0e, 0x00)
        let width = 64, height = 32
        let dirtyPixels = [Byte](repeating: 1, count: width * height)
        let chip8 = Chip8(pixels: dirtyPixels, ram: ram)
        XCTAssertEqual(chip8.pixels, dirtyPixels)

        try! chip8.doOp()
        let observedPixels = chip8.pixels
        let expectedPixels = [Byte](repeating: 0, count: width * height)
        XCTAssertEqual(observedPixels, expectedPixels)
    }

    func test_CLS_increments_pc() {
        let ram = ramWithOp(0x00, 0x00, 0x0e, 0x00)
        let width = 64, height = 32
        let dirtyPixels = [Byte](repeating: 1, count: width * height)
        let chip8 = Chip8(pixels: dirtyPixels, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func ramWithOp(_ n1: Byte, _ n2: Byte, _ n3: Byte, _ n4: Byte) -> [Byte] {
        let byte1 = n1 << 4 | n2
        let byte2 = n3 << 4 | n4
        let leadingRam = [Byte](repeating: 0, count: 0x200)
        return leadingRam + [byte1, byte2]
    }
}
