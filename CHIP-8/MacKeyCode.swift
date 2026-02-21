//
//  MacKeyCode.swift
//  CHIP-8
//
//  Created by Ryan Grey on 07/02/2021.
//

import Foundation
import Carbon

enum MacKeyCode: CGKeyCode {
    case zero = 0x1D
    case one = 0x12
    case two = 0x13
    case three = 0x14
    case four = 0x15
    case five = 0x17
    case six = 0x16
    case seven = 0x1A
    case eight = 0x1C
    case nine = 0x19
    // case a = 0x00
    case b = 0x0B
    case c = 0x08
    // case d = 0x02
    // case e = 0x0E
    case f = 0x03

    case up = 0x7E
    case w = 0x0D
    case right = 0x7C
    case d = 0x02
    case down = 0x7D
    case s = 0x01
    case left = 0x7B
    case a = 0x00
    case space = 0x31
    case e = 0x0E
}
