//
//  Chip8.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Foundation

struct NotImplemented: Error {}

public class Chip8 {
    private var ram: [Byte]
    private(set) var v: [Byte]
    private var i: Word = 0
    private(set) var pc: Word
    
    private(set) var pixels: [Byte]

    private var delayTimer: Byte = 0
    private var soundTimer: Byte = 0

    private(set) var stack: [Word]

    private var keys = [Byte](repeating: 0, count: 16)

    init(
        // 16 registers, each register is 1 byte / 8 bits
        v: [Byte] = [Byte](repeating: 0, count: 16),

        //0x000-0x1FF - Chip 8 interpreter (contains font set in emu)
        //0x050-0x0A0 - Used for the built in 4x5 pixel font set (0-F)
        //0x200-0xFFF - Program ROM and work RAM
        pc: Word = 0x200,

        // 64 * 32 screen
        pixels: [Byte] = [Byte](repeating: 0, count: 64 * 32),

        // stack is 12 or 16 deep, but nothing to stop it from being larger
        stack: [Word] = [Word](),

        // Should be 4k, but allow this to be dictated by 0x200 + rom size
        ram: [Byte]) {

        self.v = v
        self.pc = pc
        self.pixels = pixels
        self.stack = stack
        self.ram = ram
    }

    func doOp() throws {
        let byte1 = ram[pc]
        let byte2 = ram[pc + 1]
        let nibble1 = byte1 >> 4 // shift everything right by 4 bits, prefixing with 0s
        let nibble2 = byte1 & 0x0F // & with 00001111, causing the 1st nibble to be 0ed and the 2nd nibble to be preserved
        let nibble3 = byte2 >> 4
        let nibble4 = byte2 & 0x0F

        switch (nibble1, nibble2, nibble3, nibble4)
        {
        case (0x00, 0x00, 0x0e, 0x00):
            // 00E0, Display, Clears the screen.
            // CLS
            self.pixels = self.pixels.map { _ in 0 }
            pc += 2
        case (0x00, 0x00, 0x0e, 0x0e):
            // 00EE, Flow, Returns from a subroutine.
            // RTS
            pc = stack.removeLast()
            pc += 2
        case (0x00, _, _, _):
            // 0NNN, Call, Calls machine code routine (RCA 1802 for COSMAC VIP) at address NNN. Not necessary for most ROMs.
            // Noop
            return
        case (0x01, let n1, let n2, let n3):
            // 1NNN, Flow, Jumps to address NNN.
            // JUMP
            pc = Word(nibbles: [n1, n2, n3])

        case (0x02, let n1, let n2, let n3):
            // 2NNN, Flow, Calls subroutine at NNN.
            // CALL
            stack.append(pc)
            pc = Word(nibbles: [n1, n2, n3])

        case (0x03, let x, let n1, let n2):
            // 3XNN, Cond, Skips the next instruction if VX equals NN. (Usually the next instruction is a jump to skip a code block)
            // SKIP.EQ
            let nn = Byte(nibbles: [n1, n2])
            if nn == v[x] {
                pc += 4
            } else {
                pc += 2
            }

        case (0x04, let x, let n1, let n2):
            // 4XNN, Cond, Skips the next instruction if VX doesn't equal NN. (Usually the next instruction is a jump to skip a code block)
            // SKIP.NE
            let nn = Byte(nibbles: [n1, n2])
            if nn != v[x] {
                pc += 4
            } else {
                pc += 2
            }

        case (0x05, let x, let y, 0x00):
            // 5XY0, Cond, Skips the next instruction if VX equals VY. (Usually the next instruction is a jump to skip a code block)
            // SKIP.EQ
            if v[x] == v[y] {
                pc += 4
            } else {
                pc += 2
            }

        case (0x06, let x, let n1, let n2):
            // 6XNN, Const, Sets VX to NN.
            // MVI
            v[x] = Byte(nibbles: [n1, n2])
            pc += 2

        case (0x07, let x, let n1, let n2):
            // 7XNN, Const, Adds NN to VX. (Carry flag is not changed)
            // ADD
            v[x] &+= Byte(nibbles: [n1, n2])
            pc += 2
            
        case (0x08, let x, let y, 0x00):
            // 8XY0, Assign, Sets VX to the value of VY.
            // MOV
            v[x] = v[y]
            pc += 2
        case (0x08, let x, let y, 0x01):
            // 8XY1, BitOp, Sets VX to VX or VY. (Bitwise OR operation)
            // OR
            v[x] = v[x] | v[y]
            pc += 2
        case (0x08, let x, let y, 0x02):
            // 8XY2, BitOp, Sets VX to VX and VY. (Bitwise AND operation)
            // AND
            v[x] = v[x] & v[y]
            pc += 2
        case (0x08, let x, let y, 0x03):
            // 8XY3, BitOp, Sets VX to VX xor VY.
            // XOR
            v[x] = v[x] ^ v[y]
            pc += 2
        case (0x08, let x, let y, 0x04):
            // 8XY4, Math, Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't.
            // ADD.
            let (result, hasOverflow) = v[x].addingReportingOverflow(v[y])
            v[x] = result
            v[0x0f] = hasOverflow ? 1 : 0
            pc += 2
        case (0x08, let x, let y, 0x05):
            // 8XY5, Math, VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
            // SUB.
            let (result, hasOverflow) = v[x].subtractingReportingOverflow(v[y])
            v[x] = result
            v[0x0f] = hasOverflow ? 0 : 1
            pc += 2
        case (0x08, let x, _, 0x06):
            // 8XY6, BitOp, Stores the least significant bit of VX in VF and then shifts VX to the right by 1.
            // SHR.
            let lsbX = v[x] & 0b00000001
            v[0x0f] = lsbX
            v[x] = v[x] >> 1
            pc += 2
        case (0x08, let x, let y, 0x07):
            // 8XY7, Math, Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
            throw NotImplemented()
        case (0x08, let x, _, 0x0e):
            // 8XYE, BitOp, Stores the most significant bit of VX in VF and then shifts VX to the left by 1.
            throw NotImplemented()

        case (0x09, let x, let y, 0x00):
            // 9XY0, Cond, Skips the next instruction if VX doesn't equal VY. (Usually the next instruction is a jump to skip a code block)
            throw NotImplemented()

        case (0x0a, let n1, let n2, let n3):
            // ANNN, MEM, Sets I to the address NNN.
            throw NotImplemented()

        case (0x0b, let n1, let n2, let n3):
            // BNNN, Flow, Jumps to the address NNN plus V0.
            throw NotImplemented()

        case (0x0c, let x, let n1, let n2):
            // CXNN, Rand, Sets VX to the result of a bitwise AND operation on a random number (Typically: 0 to 255) and NN.
            throw NotImplemented()

        case (0x0d, let x, let y, let n):
            // DXYN, Disp, Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N+1 pixels. Each row of 8 pixels is read as bit-coded starting from memory location I; I value doesn’t change after the execution of this instruction. As described above, VF is set to 1 if any screen pixels are flipped from set to unset when the sprite is drawn, and to 0 if that doesn’t happen
            throw NotImplemented()

        case (0x0e, let x, 0x09, 0x0e):
            // EX9E, KeyOp, Skips the next instruction if the key stored in VX is pressed. (Usually the next instruction is a jump to skip a code block)
            throw NotImplemented()

        case (0x0e, let x, 0x0a, 0x01):
            // EXA1, KeyOp, Skips the next instruction if the key stored in VX isn't pressed. (Usually the next instruction is a jump to skip a code block)
            throw NotImplemented()

        case (0x0f, let x, 0x00, 0x07):
            // FX07, Timer, Sets VX to the value of the delay timer.
            throw NotImplemented()
        case (0x0f, let x, 0x00, 0x0a):
            // FX0A, KeyOp, A key press is awaited, and then stored in VX. (Blocking Operation. All instruction halted until next key event)
            throw NotImplemented()
        case (0x0f, let x, 0x01, 0x05):
            // FX15, Timer, Sets the delay timer to VX.
            throw NotImplemented()
        case (0x0f, let x, 0x01, 0x08):
            // FX18, Sound, Sets the sound timer to VX.
            throw NotImplemented()
        case (0x0f, let x, 0x01, 0x0e):
            // FX1E, MEM, Adds VX to I. VF is not affected.
            throw NotImplemented()
        case (0x0f, let x, 0x02, 0x09):
            // FX29, MEM, Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) are represented by a 4x5 font.
            throw NotImplemented()
        case (0x0f, let x, 0x03, 0x03):
            // FX33, BCD, Stores the binary-coded decimal representation of VX, with the most significant of three digits at the address in I, the middle digit at I plus 1, and the least significant digit at I plus 2. (In other words, take the decimal representation of VX, place the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.)
            throw NotImplemented()
        case (0x0f, let x, 0x05, 0x05):
            // FX55, MEM, Stores V0 to VX (including VX) in memory starting at address I. The offset from I is increased by 1 for each value written, but I itself is left unmodified
            throw NotImplemented()
        case (0x0f, let x, 0x06, 0x05):
            // FX65, MEM, Fills V0 to VX (including VX) with values from memory starting at address I. The offset from I is increased by 1 for each value written, but I itself is left unmodified.
            throw NotImplemented()
        default:
            throw NotImplemented()
        }
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
