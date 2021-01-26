//
//  CHIP_8Tests.swift
//  CHIP-8Tests
//
//  Created by Ryan Grey on 22/01/2021.
//

import XCTest
@testable import CHIP_8

class CHIP_8Tests: XCTestCase {
    func test_initial_pc_is_0x200() {
        let chip8 = Chip8(ram: [Byte]())
        XCTAssertEqual(chip8.pc, 0x200)
    }

    func test_CLS_clears_pixels() {
        let ram = createRamWithOp(0x00, 0x00, 0x0e, 0x00)
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
        let ram = createRamWithOp(0x00, 0x00, 0x0e, 0x00)
        let width = 64, height = 32
        let dirtyPixels = [Byte](repeating: 1, count: width * height)
        let chip8 = Chip8(pixels: dirtyPixels, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_RTS_sets_pc_to_last_stack_address_plus_two() {
        let ram = createRamWithOp(0x00, 0x00, 0x0e, 0x0e)
        let lastPc: Word = 0x02
        let expectedPc: Word = lastPc + 2
        let stack = [lastPc]
        let chip8 = Chip8(stack: stack, ram: ram)

        try! chip8.doOp()
        let observedPc = chip8.pc
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_RTS_removes_last_stack_address() {
        let ram = createRamWithOp(0x00, 0x00, 0x0e, 0x0e)
        let stack: [Word] = [0x03, 0x04]
        let chip8 = Chip8(stack: stack, ram: ram)

        try! chip8.doOp()
        let observedStack = chip8.stack
        let expectedStack = [stack[0]]
        XCTAssertEqual(observedStack, expectedStack)
    }

    func test_JUMP_sets_pc_to_NNN() {
        let n1: Byte = 0x01, n2: Byte = 0x0e, n3: Byte = 0x03
        let ram = createRamWithOp(0x01, n1, n2, n3)
        let chip8 = Chip8(ram: ram)

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = createPcFrom(n1, n2, n3)
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_CALL_adds_current_pc_to_stack() {
        let n1: Byte = 0x02, n2: Byte = 0x0a, n3: Byte = 0x0b
        let ram = createRamWithOp(0x02, n1, n2, n3)
        let initialPc: Word = 0x200
        let chip8 = Chip8(pc: initialPc, ram: ram)
        XCTAssertTrue(chip8.stack.isEmpty)

        try! chip8.doOp()
        let observedStack = chip8.stack
        let expectedStack = [initialPc]
        XCTAssertEqual(observedStack, expectedStack)
    }

    func test_CALL_sets_pc_to_NNN() {
        let n1: Byte = 0x0b, n2: Byte = 0x0c, n3: Byte = 0x0d
        let ram = createRamWithOp(0x02, n1, n2, n3)
        let chip8 = Chip8(ram: ram)

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = createPcFrom(n1, n2, n3)
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_skips_next_instruction_if_Vx_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x0c, n2: Byte = 0x0f
        let ram = createRamWithOp(0x03, x, n1, n2)
        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n2])
        let chip8 = Chip8(v: v, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 4
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_moves_to_next_instruction_if_Vx_NOT_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x0c, n2: Byte = 0x01
        let ram = createRamWithOp(0x03, x, n1, n2)
        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n1])
        let chip8 = Chip8(v: v, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_NE_skips_next_instruction_if_Vx_NOT_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x09, n2: Byte = 0x0c
        let ram = createRamWithOp(0x04, x, n1, n2)
        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n1])
        let chip8 = Chip8(v: v, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 4
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_NE_moves_to_next_instruction_if_Vx_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x05, n2: Byte = 0x0d
        let ram = createRamWithOp(0x04, x, n1, n2)
        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n2])
        let chip8 = Chip8(v: v, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func createPcFrom(_ n1: Byte, _ n2: Byte, _ n3: Byte) -> Word {
        let word = Word(nibbles: [n1, n2, n3])
        return word
    }

    func createOp(_ n1: Byte, _ n2: Byte, _ n3: Byte, _ n4: Byte) -> [Byte] {
        let byte1 = n1 << 4 | n2
        let byte2 = n3 << 4 | n4
        return [byte1, byte2]
    }

    func createRamWithOp(_ n1: Byte, _ n2: Byte, _ n3: Byte, _ n4: Byte) -> [Byte] {
        let leadingRam = [Byte](repeating: 0, count: 0x200)
        return leadingRam + createOp(n1, n2, n3, n4)
    }

    func getHexStr<I: BinaryInteger & CVarArg>(width: Int, _ value: I) -> String {
        let valueStr = String(format:"%02X", value as CVarArg)
        let paddedStr = valueStr.padding(toLength: width, withPad: " ", startingAt: 0)
        return paddedStr
    }
}
