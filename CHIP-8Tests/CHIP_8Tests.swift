//
//  CHIP_8Tests.swift
//  CHIP-8Tests
//
//  Created by Ryan Grey on 22/01/2021.
//

import XCTest
@testable import CHIP_8

class CHIP_8Tests: XCTestCase {
    let registerSize = 0x0f + 0x01

    func test_initial_pc_is_0x200() {
        let chip8 = Chip8(ram: [Byte]())
        XCTAssertEqual(chip8.pc, 0x200)
    }

    func test_CLS_0x00_clears_pixels() {
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

    func test_CLS_0x00_increments_pc() {
        let initialPc: Word = 0x31a
        assertPcIncremented(0x00, 0x00, 0x0e, 0x00, initialPc: initialPc)
    }

    func test_RTS_0x00_sets_pc_to_last_stack_address_plus_two() {
        let ram = createRamWithOp(0x00, 0x00, 0x0e, 0x0e)
        let lastPc: Word = 0x02
        let expectedPc: Word = lastPc + 2
        let stack = [lastPc]
        let chip8 = Chip8(stack: stack, ram: ram)

        try! chip8.doOp()
        let observedPc = chip8.pc
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_RTS_0x00_removes_last_stack_address() {
        let ram = createRamWithOp(0x00, 0x00, 0x0e, 0x0e)
        let stack: [Word] = [0x03, 0x04]
        let chip8 = Chip8(stack: stack, ram: ram)

        try! chip8.doOp()
        let observedStack = chip8.stack
        let expectedStack = [stack[0]]
        XCTAssertEqual(observedStack, expectedStack)
    }

    func test_JUMP_0x01_sets_pc_to_NNN() {
        let n1: Byte = 0x01, n2: Byte = 0x0e, n3: Byte = 0x03
        let ram = createRamWithOp(0x01, n1, n2, n3)
        let chip8 = Chip8(ram: ram)

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = createPcFrom(n1, n2, n3)
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_CALL_0x02_adds_current_pc_to_stack() {
        let n1: Byte = 0x02, n2: Byte = 0x0a, n3: Byte = 0x0b
        let initialPc: Word = 0x2b1
        let ram = createRamWithOp(0x02, n1, n2, n3, pc: initialPc)
        let chip8 = Chip8(pc: initialPc, ram: ram)
        XCTAssertTrue(chip8.stack.isEmpty)

        try! chip8.doOp()
        let observedStack = chip8.stack
        let expectedStack = [initialPc]
        XCTAssertEqual(observedStack, expectedStack)
    }

    func test_CALL_0x02_sets_pc_to_NNN() {
        let n1: Byte = 0x0b, n2: Byte = 0x0c, n3: Byte = 0x0d
        let ram = createRamWithOp(0x02, n1, n2, n3)
        let chip8 = Chip8(ram: ram)

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = createPcFrom(n1, n2, n3)
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_0x03_skips_next_instruction_if_Vx_equal_to_NN() {
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

    func test_SKIP_EQ_0x03_moves_to_next_instruction_if_Vx_NOT_equal_to_NN() {
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

    func test_SKIP_NE_0x04_skips_next_instruction_if_Vx_NOT_equal_to_NN() {
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

    func test_SKIP_NE_0x04_moves_to_next_instruction_if_Vx_equal_to_NN() {
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

    func test_SKIP_EQ_0x05_skips_next_instruction_if_Vx_equal_to_Vy() {
        let x: Byte = 2, y: Byte = 13
        let ram = createRamWithOp(0x05, x, y, 0x00)
        var v = [Byte](repeating: 0, count: 14)
        v[x] = 0x4e
        v[y] = v[x]
        let chip8 = Chip8(v: v, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 4
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_0x05_moves_to_next_instruction_if_Vx_NOT_equal_to_Vy() {
        let x: Byte = 2, y: Byte = 13
        let ram = createRamWithOp(0x05, x, y, 0x00)
        var v = [Byte](repeating: 0, count: 14)
        v[x] = 0x4e
        v[y] = 0x5b
        let chip8 = Chip8(v: v, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_MVI_0x06_sets_Vx_to_NN() {
        let x: Byte = 11, n1: Byte = 0x03, n2: Byte = 0x03
        let ram = createRamWithOp(0x06, x, n1, n2)
        var v = [Byte](repeating: 0, count: 12)
        let expectedVx = Byte(nibbles: [n1, n2])
        v[x] = Byte(nibbles: [n1, n2])
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_MVI_0x06_moves_to_next_instruction() {
        let x: Byte = 11, n1: Byte = 0x03, n2: Byte = 0x03
        let ram = createRamWithOp(0x06, x, n1, n2)
        var v = [Byte](repeating: 0, count: 12)
        v[x] = Byte(nibbles: [n1, n2])
        let chip8 = Chip8(v: v, ram: ram)
        let initialPc = chip8.pc

        try! chip8.doOp()
        let observedPc = chip8.pc
        let expectedPc = initialPc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_ADD_0x07_adds_NN_to_Vx() {
        let x: Byte = 5, n1: Byte = 0x0c, n2: Byte = 0x0c
        let ram = createRamWithOp(0x07, x, n1, n2)
        var v = [Byte](repeating: 0, count: 6)
        v[x] = 0x07
        let expectedVx = v[x] + Byte(nibbles: [n1, n2])
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_ADD_0x07_adds_NN_to_Vx_with_overflow() {
        let x: Byte = 5, n1: Byte = 0x00, n2: Byte = 0x01
        let ram = createRamWithOp(0x07, x, n1, n2)
        var v = [Byte](repeating: 0, count: 6)
        v[x] = Byte.max
        let expectedVx = v[x] &+ Byte(nibbles: [n1, n2])
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_ADD_0x07_does_NOT_change_flag() {
        let x: Byte = 0x0e, n1: Byte = 0x0b, n2: Byte = 0x01, f = 0x0f
        let ram = createRamWithOp(0x07, x, n1, n2)
        var v = [Byte](repeating: 0, count: 0x0f + 0x01)
        let expectedCarryFlag: Byte = 0x06
        v[f] = expectedCarryFlag
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        // v[f] is carry flag
        let observedCarryFlag = chip8.v[0x0f]
        XCTAssertEqual(observedCarryFlag, expectedCarryFlag)
    }

    func test_ADD_0x07_increments_pc() {
        let x: Byte = 0x0e, n1: Byte = 0x0b, n2: Byte = 0x01
        let initialPc: Word = 0x40c
        assertPcIncremented(0x07, x, n1, n2, initialPc: initialPc)
    }

    func test_MOV_0x08_sets_Vx_to_Vy() {
        let x: Byte = 0x0e, y: Byte = 0x0b
        let initialVy: Byte = 0x06
        var v = [Byte](repeating: 0, count: registerSize)
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x00)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        let expectedVx = initialVy
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_MOV_0x08_increments_pc() {
        let x: Byte = 0x0a, y: Byte = 0x07
        let initialPc: Word = 0x3d1
        assertPcIncremented(0x08, x, y, 0x00, initialPc: initialPc)
    }

    func test_OR_0x08_sets_Vx_to_Vy_bitwise_or_Vx() {
        let x: Byte = 2, y: Byte = 3
        let initialVx: Byte = 0b1101
        let initialVy: Byte = 0b0110
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x01)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b1101 | 0b0110 = 0b1111 = 15
        let expectedVx: Byte = 15
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_OR_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let initialPc: Word = 0x40a
        assertPcIncremented(0x08, x, y, 0x01, initialPc: initialPc)
    }

    func test_AND_0x08_sets_Vx_to_Vy_bitwise_and_Vx() {
        let x: Byte = 3, y: Byte = 14
        let initialVx: Byte = 0b1100
        let initialVy: Byte = 0b1010
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x02)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b1100 & 0b1010 = 0b1000 = 8
        let expectedVx: Byte = 8
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_AND_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let initialPc: Word = 0x2db
        assertPcIncremented(0x08, x, y, 0x02, initialPc: initialPc)
    }

    func test_XOR_0x08_sets_Vx_to_Vy_bitwise_xor_Vx() {
        let x: Byte = 7, y: Byte = 13
        let initialVx: Byte = 0b1100
        let initialVy: Byte = 0b1010
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x03)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b1100 ^ 0b1010 = 0b0110 = 6
        let expectedVx: Byte = 6
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_XOR_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let initialPc: Word = 0x2db
        assertPcIncremented(0x08, x, y, 0x03, initialPc: initialPc)
    }

    func test_ADD_dot_0x08_adds_Vy_to_Vx_and_sets_flag() {
        let x: Byte = 0, y: Byte = 1
        let initialVx: Byte = 0b11111111
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x04)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b11111111 + 0b00000001 = 0b00000000 = 0 with overflow
        let expectedVx: Byte = 0b00000000
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 1
        let observedVf = chip8.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_ADD_dot_0x08_adds_Vy_to_Vx_and_does_not_set_flag() {
        let x: Byte = 0, y: Byte = 1
        let initialVx: Byte = 0b11111110
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x04)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b11111110 + 0b00000001 = 0b11111111 = 255 with no overflow
        let expectedVx: Byte = 0b11111111
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 0
        let observedVf = chip8.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_ADD_dot_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let initialPc: Word = 0x2db
        assertPcIncremented(0x08, x, y, 0x04, initialPc: initialPc)
    }

    func test_SUB_dot_0x08_sbtracts_Vy_from_Vx_and_does_not_set_flag() {
        let x: Byte = 0, y: Byte = 1
        let initialVx: Byte = 0b00000000
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x05)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b00000000 - 0b00000001 = 0b11111111 = 255 with borrow
        let expectedVx: Byte = 0b11111111
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 0
        let observedVf = chip8.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUB_dot_0x08_sbtracts_Vy_from_Vx_and_does_set_flag() {
        let x: Byte = 0, y: Byte = 1
        let initialVx: Byte = 0b00000001
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x05)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b00000001 - 0b00000001 = 0b00000000 = 0 without borrow
        let expectedVx: Byte = 0b00000000
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 1
        let observedVf = chip8.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUB_dot_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let initialPc: Word = 0x2db
        assertPcIncremented(0x08, x, y, 0x05, initialPc: initialPc)
    }

    func test_SHR_dot_0x08_stores_the_lsb_of_Vx_in_Vf_when_lsb_is_1() {
        let x: Byte = 0x0c
        let f: Byte = 0x0f
        let initialVx: Byte = 0b10100101
        let initialVf: Byte = 0b00000000
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[f] = initialVf
        let ram = createRamWithOp(0x08, x, 0x00, 0x06)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVf = chip8.v[f]
        // lsb of 0b10110101 is 0b00000001
        let expectedVf: Byte = 0b00000001
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SHR_dot_0x08_stores_the_lsb_of_Vx_in_Vf_when_lsb_is_0() {
        let x: Byte = 0x0c
        let f: Byte = 0x0f
        let initialVx: Byte = 0b11110100
        let initialVf: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[f] = initialVf
        let ram = createRamWithOp(0x08, x, 0x00, 0x06)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVf = chip8.v[f]
        // lsb of 0b10110101 is 0b00000000
        let expectedVf: Byte = 0b00000000
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SHR_dot_0x08_shifts_Vx_right_by_1() {
        let x: Byte = 0x0c
        let f: Byte = 0x0f
        let initialVx: Byte = 0b10100101
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        let ram = createRamWithOp(0x08, x, 0x00, 0x06)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b10100101 shifted right by 1 = 0b01010010
        let expectedVx: Byte = 0b01010010
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_SHR_dot_0x08_increments_pc() {
        let x: Byte = 0, y: Byte = 15
        let initialPc: Word = 0x21c
        assertPcIncremented(0x08, x, y, 0x06, initialPc: initialPc)
    }

    func test_SUBB_dot_0x08_sets_Vx_to_Vy_minus_Vx_and_does_set_flag() {
        // Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.

        let x: Byte = 0, y: Byte = 1
        let initialVx: Byte = 0b00000010
        let initialVy: Byte = 0b00000011
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x07)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b00000011 - 0b00000010 = 0b00000001 with NO borrow
        let expectedVx: Byte = 0b00000001
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 1
        let observedVf = chip8.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUBB_dot_0x08_sets_Vx_to_Vy_minus_Vx_and_does_NOT_set_flag() {
        let x: Byte = 4, y: Byte = 5
        let initialVx: Byte = 0b00000110
        let initialVy: Byte = 0b00000011
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy
        let ram = createRamWithOp(0x08, x, y, 0x07)
        let chip8 = Chip8(v: v, ram: ram)

        try! chip8.doOp()
        let observedVx = chip8.v[x]
        // 0b00000011 - 0b00000110 = 3 - 6 = 0 - 3 = 255 - 2 = 253 = 0b11111101 with borrow
        let expectedVx: Byte = 0b11111101
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 0
        let observedVf = chip8.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUBB_dot_0x08_increments_pc() {
        let x: Byte = 1, y: Byte = 4
        let initialPc: Word = 0x5cc
        assertPcIncremented(0x08, x, y, 0x07, initialPc: initialPc)
    }

    func assertPcIncremented(_ n1: Byte, _ n2: Byte, _ n3: Byte, _ n4: Byte, initialPc: Word) {
        let ram = createRamWithOp(n1, n2, n3, n4, pc: initialPc)
        let chip8 = Chip8(pc: initialPc, ram: ram)

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

    func createRamWithOp(_ n1: Byte, _ n2: Byte, _ n3: Byte, _ n4: Byte, pc: Word = 0x200) -> [Byte] {
        var ram = [Byte](repeating: 0, count: 4096)
        let opBytes = createOp(n1, n2, n3, n4)
        let pcInt = Int(pc)
        let opRange = pcInt..<pcInt + opBytes.count
        ram.replaceSubrange(opRange, with: opBytes)
        return ram
    }

    func getHexStr<I: BinaryInteger & CVarArg>(width: Int, _ value: I) -> String {
        let valueStr = String(format:"%02X", value as CVarArg)
        let paddedStr = valueStr.padding(toLength: width, withPad: " ", startingAt: 0)
        return paddedStr
    }
}
