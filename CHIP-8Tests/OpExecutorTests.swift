//
//  CHIP_8Tests.swift
//  CHIP-8Tests
//
//  Created by Ryan Grey on 22/01/2021.
//

import XCTest
@testable import CHIP_8

class OpExecutorTests: XCTestCase {
    let registerSize = 0x0f + 0x01
    let opExecutor = OpExecutor()

    func test_CLS_0x00_clears_pixels() {
        let width = 64, height = 32
        let dirtyPixels = [Byte](repeating: 1, count: width * height)

        var state = ChipState()
        state.pixels = dirtyPixels
        XCTAssertEqual(state.pixels, dirtyPixels)

        let op = Word(nibbles: [0x00, 0x00, 0x0e, 0x00])
        let newState = opExecutor.handle(state: state, op: op)

        let observedPixels = newState.pixels
        let expectedPixels = [Byte](repeating: 0, count: width * height)
        XCTAssertEqual(observedPixels, expectedPixels)
    }

    func test_CLS_0x00_increments_pc() {
        let op = Word(nibbles: [0x00, 0x00, 0x0e, 0x00])
        assertPcIncremented(op: op)
    }

    func test_RTS_0x00_sets_pc_to_last_stack_address_plus_two() {
        let lastPc: Word = 0x02
        let expectedPc: Word = lastPc + 2
        let stack = [lastPc]

        var state = ChipState()
        state.stack = stack

        let op = Word(nibbles: [0x00, 0x00, 0x0e, 0x0e])
        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_RTS_0x00_removes_last_stack_address() {
        let stack: [Word] = [0x03, 0x04]

        var state = ChipState()
        state.stack = stack

        let op = Word(nibbles: [0x00, 0x00, 0x0e, 0x0e])
        let newState = opExecutor.handle(state: state, op: op)

        let observedStack = newState.stack
        let expectedStack = [stack[0]]
        XCTAssertEqual(observedStack, expectedStack)
    }

    func test_JUMP_0x01_sets_pc_to_NNN() {
        let n1: Byte = 0x01, n2: Byte = 0x0e, n3: Byte = 0x03
        let op = Word(nibbles: [0x01, n1, n2, n3])
        let state = ChipState()
        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = createPcFrom(n1, n2, n3)
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_CALL_0x02_adds_current_pc_to_stack() {
        let n1: Byte = 0x02, n2: Byte = 0x0a, n3: Byte = 0x0b
        let op = Word(nibbles: [0x02, n1, n2, n3])
        let initialPc: Word = 0x2b1
        var state = ChipState()
        state.pc = initialPc
        XCTAssertTrue(state.stack.isEmpty)

        let newState = opExecutor.handle(state: state, op: op)
        let observedStack = newState.stack
        let expectedStack = [initialPc]
        XCTAssertEqual(observedStack, expectedStack)
    }

    func test_CALL_0x02_sets_pc_to_NNN() {
        let n1: Byte = 0x0b, n2: Byte = 0x0c, n3: Byte = 0x0d
        let op = Word(nibbles: [0x02, n1, n2, n3])

        let newState = opExecutor.handle(state: ChipState(), op: op)
        let observedPc = newState.pc
        let expectedPc = createPcFrom(n1, n2, n3)
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_0x03_skips_next_instruction_if_Vx_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x0c, n2: Byte = 0x0f
        let op = Word(nibbles: [0x03, x, n1, n2])

        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n2])
        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 4
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_0x03_moves_to_next_instruction_if_Vx_NOT_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x0c, n2: Byte = 0x01
        let op = Word(nibbles: [0x03, x, n1, n2])
        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n1])

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_NE_0x04_skips_next_instruction_if_Vx_NOT_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x09, n2: Byte = 0x0c
        let op = Word(nibbles: [0x04, x, n1, n2])
        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n1])

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 4
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_NE_0x04_moves_to_next_instruction_if_Vx_equal_to_NN() {
        let x: Byte = 2, n1: Byte = 0x05, n2: Byte = 0x0d
        let op = Word(nibbles: [0x04, x, n1, n2])
        var v = [Byte](repeating: 0, count: 3)
        v[x] = Byte(nibbles: [n1, n2])

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_0x05_skips_next_instruction_if_Vx_equal_to_Vy() {
        let x: Byte = 2, y: Byte = 13
        let op = Word(nibbles: [0x05, x, y, 0x00])
        var v = [Byte](repeating: 0, count: 14)
        v[x] = 0x4e
        v[y] = v[x]

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 4
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_EQ_0x05_moves_to_next_instruction_if_Vx_NOT_equal_to_Vy() {
        let x: Byte = 2, y: Byte = 13
        let op = Word(nibbles: [0x05, x, y, 0x00])
        var v = [Byte](repeating: 0, count: 14)
        v[x] = 0x4e
        v[y] = 0x5b

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_MVI_0x06_sets_Vx_to_NN() {
        let x: Byte = 11, n1: Byte = 0x03, n2: Byte = 0x03
        let op = Word(nibbles: [0x06, x, n1, n2])
        var v = [Byte](repeating: 0, count: 12)
        let expectedVx = Byte(nibbles: [n1, n2])
        v[x] = expectedVx

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_MVI_0x06_moves_to_next_instruction() {
        let x: Byte = 11, n1: Byte = 0x03, n2: Byte = 0x03
        let op = Word(nibbles: [0x06, x, n1, n2])
        var v = [Byte](repeating: 0, count: 12)
        v[x] = Byte(nibbles: [n1, n2])

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_ADD_0x07_adds_NN_to_Vx() {
        let x: Byte = 5, n1: Byte = 0x0c, n2: Byte = 0x0c
        let op = Word(nibbles: [0x07, x, n1, n2])
        var v = [Byte](repeating: 0, count: 6)
        v[x] = 0x07

        var state = ChipState()
        state.v = v

        let expectedVx = v[x] + Byte(nibbles: [n1, n2])

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_ADD_0x07_adds_NN_to_Vx_with_overflow() {
        let x: Byte = 5, n1: Byte = 0x00, n2: Byte = 0x01
        let op = Word(nibbles: [0x07, x, n1, n2])
        var v = [Byte](repeating: 0, count: 6)
        v[x] = Byte.max
        let expectedVx = v[x] &+ Byte(nibbles: [n1, n2])

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_ADD_0x07_does_NOT_change_flag() {
        let x: Byte = 0x0e, n1: Byte = 0x0b, n2: Byte = 0x01, f = 0x0f
        let op = Word(nibbles: [0x07, x, n1, n2])
        var v = [Byte](repeating: 0, count: 0x0f + 0x01)
        let expectedCarryFlag: Byte = 0x06
        v[f] = expectedCarryFlag

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        // v[f] is carry flag
        let observedCarryFlag = newState.v[0x0f]
        XCTAssertEqual(observedCarryFlag, expectedCarryFlag)
    }

    func test_ADD_0x07_increments_pc() {
        let x: Byte = 0x0e, n1: Byte = 0x0b, n2: Byte = 0x01
        let op = Word(nibbles: [0x07, x, n1, n2])
        assertPcIncremented(op: op)
    }

    func test_MOV_0x08_sets_Vx_to_Vy() {
        let x: Byte = 0x0e, y: Byte = 0x0b
        let op = Word(nibbles: [0x08, x, y, 0x00])
        let initialVy: Byte = 0x06
        var v = [Byte](repeating: 0, count: registerSize)
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        let expectedVx = initialVy
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_MOV_0x08_increments_pc() {
        let x: Byte = 0x0a, y: Byte = 0x07
        let op = Word(nibbles: [0x08, x, y, 0x00])
        assertPcIncremented(op: op)
    }

    func test_OR_0x08_sets_Vx_to_Vy_bitwise_or_Vx() {
        let x: Byte = 2, y: Byte = 3
        let op = Word(nibbles: [0x08, x, y, 0x01])
        let initialVx: Byte = 0b1101
        let initialVy: Byte = 0b0110
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b1101 | 0b0110 = 0b1111
        let expectedVx: Byte = 0b1111
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_OR_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let op = Word(nibbles: [0x08, x, y, 0x01])
        assertPcIncremented(op: op)
    }

    func test_AND_0x08_sets_Vx_to_Vy_bitwise_and_Vx() {
        let x: Byte = 3, y: Byte = 14
        let op = Word(nibbles: [0x08, x, y, 0x02])
        let initialVx: Byte = 0b1100
        let initialVy: Byte = 0b1010
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b1100 & 0b1010 = 0b1000 = 8
        let expectedVx: Byte = 8
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_AND_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let op = Word(nibbles: [0x08, x, y, 0x02])
        assertPcIncremented(op: op)
    }

    func test_XOR_0x08_sets_Vx_to_Vy_bitwise_xor_Vx() {
        let x: Byte = 7, y: Byte = 13
        let op = Word(nibbles: [0x08, x, y, 0x03])
        let initialVx: Byte = 0b1100
        let initialVy: Byte = 0b1010
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b1100 ^ 0b1010 = 0b0110 = 6
        let expectedVx: Byte = 6
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_XOR_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let op = Word(nibbles: [0x08, x, y, 0x03])
        assertPcIncremented(op: op)
    }

    func test_ADD_dot_0x08_adds_Vy_to_Vx_and_sets_flag() {
        let x: Byte = 0, y: Byte = 1
        let op = Word(nibbles: [0x08, x, y, 0x04])
        let initialVx: Byte = 0b11111111
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b11111111 + 0b00000001 = 0b00000000 = 0 with overflow
        let expectedVx: Byte = 0b00000000
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 1
        let observedVf = newState.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_ADD_dot_0x08_adds_Vy_to_Vx_and_does_not_set_flag() {
        let x: Byte = 0, y: Byte = 1
        let op = Word(nibbles: [0x08, x, y, 0x04])
        let initialVx: Byte = 0b11111110
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)

        let observedVx = newState.v[x]
        // 0b11111110 + 0b00000001 = 0b11111111 = 255 with no overflow
        let expectedVx: Byte = 0b11111111
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 0
        let observedVf = newState.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_ADD_dot_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let op = Word(nibbles: [0x08, x, y, 0x04])
        assertPcIncremented(op: op)
    }

    func test_SUB_dot_0x08_sbtracts_Vy_from_Vx_and_does_not_set_flag() {
        let x: Byte = 0, y: Byte = 1
        let op = Word(nibbles: [0x08, x, y, 0x05])
        let initialVx: Byte = 0b00000000
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b00000000 - 0b00000001 = 0b11111111 = 255 with borrow
        let expectedVx: Byte = 0b11111111
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 0
        let observedVf = newState.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUB_dot_0x08_sbtracts_Vy_from_Vx_and_does_set_flag() {
        let x: Byte = 0, y: Byte = 1
        let op = Word(nibbles: [0x08, x, y, 0x05])
        let initialVx: Byte = 0b00000001
        let initialVy: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)

        let observedVx = newState.v[x]
        // 0b00000001 - 0b00000001 = 0b00000000 = 0 without borrow
        let expectedVx: Byte = 0b00000000
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 1
        let observedVf = newState.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUB_dot_0x08_increments_pc() {
        let x: Byte = 3, y: Byte = 7
        let op = Word(nibbles: [0x08, x, y, 0x05])
        assertPcIncremented(op: op)
    }

    func test_SHR_dot_0x08_stores_the_lsb_of_Vx_in_Vf_when_lsb_is_1() {
        let x: Byte = 0x0c
        let f: Byte = 0x0f
        let op = Word(nibbles: [0x08, x, 0x00, 0x06])
        let initialVx: Byte = 0b10100101
        let initialVf: Byte = 0b00000000
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[f] = initialVf

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVf = newState.v[f]
        // lsb of 0b10110101 is 0b00000001
        let expectedVf: Byte = 0b00000001
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SHR_dot_0x08_stores_the_lsb_of_Vx_in_Vf_when_lsb_is_0() {
        let x: Byte = 0x0c
        let f: Byte = 0x0f
        let op = Word(nibbles: [0x08, x, 0x00, 0x06])
        let initialVx: Byte = 0b11110100
        let initialVf: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[f] = initialVf

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVf = newState.v[f]
        // lsb of 0b10110101 is 0b00000000
        let expectedVf: Byte = 0b00000000
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SHR_dot_0x08_shifts_Vx_right_by_1() {
        let x: Byte = 0x0c
        let op = Word(nibbles: [0x08, x, 0x00, 0x06])
        let initialVx: Byte = 0b10100101
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b10100101 shifted right by 1 = 0b01010010
        let expectedVx: Byte = 0b01010010
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_SHR_dot_0x08_increments_pc() {
        let x: Byte = 0, y: Byte = 15
        let op = Word(nibbles: [0x08, x, y, 0x06])
        assertPcIncremented(op: op)
    }

    func test_SUBB_dot_0x08_sets_Vx_to_Vy_minus_Vx_and_does_set_flag() {
        // Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.

        let x: Byte = 0, y: Byte = 1
        let op = Word(nibbles: [0x08, x, y, 0x07])
        let initialVx: Byte = 0b00000010
        let initialVy: Byte = 0b00000011
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b00000011 - 0b00000010 = 0b00000001 with NO borrow
        let expectedVx: Byte = 0b00000001
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 1
        let observedVf = newState.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUBB_dot_0x08_sets_Vx_to_Vy_minus_Vx_and_does_NOT_set_flag() {
        let x: Byte = 4, y: Byte = 5
        let op = Word(nibbles: [0x08, x, y, 0x07])
        let initialVx: Byte = 0b00000110
        let initialVy: Byte = 0b00000011
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b00000011 - 0b00000110 = 3 - 6 = 0 - 3 = 255 - 2 = 253 = 0b11111101 with borrow
        let expectedVx: Byte = 0b11111101
        XCTAssertEqual(observedVx, expectedVx)

        let expectedVf: Byte = 0
        let observedVf = newState.v[0x0f]
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SUBB_dot_0x08_increments_pc() {
        let x: Byte = 1, y: Byte = 4
        let op = Word(nibbles: [0x08, x, y, 0x07])
        assertPcIncremented(op: op)
    }

    func test_SHL_dot_0x08_stores_the_msb_of_Vx_in_Vf_when_msb_is_1() {
        let x: Byte = 0x0c
        let f: Byte = 0x0f
        let op = Word(nibbles: [0x08, x, 0x00, 0x0e])
        let initialVx: Byte = 0b10100101
        let initialVf: Byte = 0b00000000
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[f] = initialVf

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVf = newState.v[f]
        // msb of 0b10110101 is 0b1000000
        let expectedVf: Byte = 0b10000000
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SHL_dot_0x08_stores_the_msb_of_Vx_in_Vf_when_msb_is_0() {
        let x: Byte = 0x0c
        let f: Byte = 0x0f
        let op = Word(nibbles: [0x08, x, 0x00, 0x0e])
        let initialVx: Byte = 0b01010100
        let initialVf: Byte = 0b00000001
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[f] = initialVf

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVf = newState.v[f]
        // msb of 0b01010100 is 0b00000000
        let expectedVf: Byte = 0b00000000
        XCTAssertEqual(observedVf, expectedVf)
    }

    func test_SHL_dot_0x08_shifts_Vx_left_by_1() {
        let x: Byte = 0x0c
        let op = Word(nibbles: [0x08, x, 0x00, 0x0e])
        let initialVx: Byte = 0b10100101
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedVx = newState.v[x]
        // 0b10100101 shifted left by 1 = 0b01001010
        let expectedVx: Byte = 0b01001010
        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_SHL_dot_0x08_increments_pc() {
        let x: Byte = 5, y: Byte = 9
        let op = Word(nibbles: [0x08, x, y, 0x0e])
        assertPcIncremented(op: op)
    }

    func test_SKIP_NE_0x09_skips_if_Vx_does_NOT_equal_Vy() {
        let x: Byte = 0x0c, y: Byte = 0x0e
        let op = Word(nibbles: [0x09, x, y, 0x00])
        let initialVx: Byte = 1, initialVy: Byte = 2
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v


        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 4
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_SKIP_NE_0x09_increments_if_Vx_does_equal_Vy() {
        let x: Byte = 0x0c, y: Byte = 0x0e
        let op = Word(nibbles: [0x09, x, y, 0x00])
        let initialVx: Byte = 3, initialVy: Byte = 3
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx
        v[y] = initialVy

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)

        let observedPc = newState.pc
        let expectedPc = state.pc + 2
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_MVI_0x0a_sets_i_to_NNN() {
        let n1: Byte = 0x0a, n2: Byte = 0x0b, n3: Byte = 0x0c
        let op = Word(nibbles: [0x0a, n1, n2, n3])

        let state = ChipState()

        let newState = opExecutor.handle(state: state, op: op)

        let observedI = newState.i
        let expectedI = Word(nibbles: [n1, n2, n3])
        XCTAssertEqual(observedI, expectedI)
    }

    func test_MVI_0x0a_increments_pc() {
        let n1: Byte = 0x0a, n2: Byte = 0x0b, n3: Byte = 0x0c
        let op = Word(nibbles: [0x0a, n1, n2, n3])
        assertPcIncremented(op: op)
    }

    func test_JUMP_0x0b_sets_pc_to_NNN_plus_V0() {
        let x: Byte = 0, n1: Byte = 0x02, n2: Byte = 0x0a, n3: Byte = 0x06
        let op = Word(nibbles: [0x0b, n1, n2, n3])
        let initialVx: Byte = 0b00011010
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        // nnn + V0 = 0x02, 0x0a, 0x06 + 0b00011010 = 0b0000, 0b0010, 0b1010, 0b0110 + 0b00011010
        // 0b0000, 0b0010, 0b1010, 0b0110 = 0b0000001010100110 + 0b00011010 = 678 + 26 = 704
        let expectedPc: Word = 704
        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_JUMP_0x0b_sets_pc_to_NNN_plus_V0_with_maximums() {
        let x: Byte = 0, n1: Byte = 0b1111, n2: Byte = 0b1111, n3: Byte = 0b1111
        let op = Word(nibbles: [0x0b, n1, n2, n3])
        let initialVx: Byte = 0b11111111
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx

        var state = ChipState()
        state.v = v

        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        // nnn + V0 = 0b1111, 0b1111, 0b1111 + 0b11111111 =
        // 0b0000111111111111 + 0b11111111 = 4095 + 255 = 4350
        // TODO: this address is outside of the normal 4k Chip-8 memory, should rom programmer or Chip-8 implementation handle this?
        let expectedPc: Word = 4350

        XCTAssertEqual(observedPc, expectedPc)
    }

    func test_RAND_0x0c_sets_Vx_to_rand_bitwise_and_nn() {
        let x: Byte = 0, n1: Byte = 0b0011, n2: Byte = 0b1001
        let op = Word(nibbles: [0x0c, x, n1, n2])
        let initialVx: Byte = 0b11111111
        var v = [Byte](repeating: 0, count: registerSize)
        v[x] = initialVx

        var state = ChipState()
        state.v = v

        // inject a random byte generating function to allow deterministic test
        let randomByteFunction: () -> Byte = { 0b10001001 }
        let opExecutor = OpExecutor(randomByteFunction: randomByteFunction )
        let newState = opExecutor.handle(state: state, op: op)

        let observedVx = newState.v[x]
        // rand() & nn = 0b10001001 & 0b0011,0b1001
        // = 0b10001001 & 0b00111001 = 0b00001001

        let expectedVx: Byte = 0b00001001

        XCTAssertEqual(observedVx, expectedVx)
    }

    func test_RAND_0x0a_increments_pc() {
        let x: Byte = 0, n1: Byte = 0b0011, n2: Byte = 0b1001
        let op = Word(nibbles: [0x0c, x, n1, n2])
        assertPcIncremented(op: op)
    }

    func assertPcIncremented(op: Word) {
        let state = ChipState()
        let newState = opExecutor.handle(state: state, op: op)
        let observedPc = newState.pc
        let expectedPc = state.pc + 2
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
