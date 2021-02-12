//
//  KeyMapping.swift
//  CHIP-8
//
//  Created by Ryan Grey on 07/02/2021.
//

import Foundation
import Chip8Emulator

typealias KeyMapping = [MacKeyCode : Chip8KeyCode]

extension KeyMapping {
    static var wasd: KeyMapping {
        /*
         A key mapping that attemps to allow for a more natural WASD
         and Up, Left, Down, Right mapping. Note that the mapping is
         incomplete (not all 16 Chip8 keys are included). This is
         because there's no "natural" fit for the remaining keys that
         would be easy to remember. So we either assume a game is a good
         fit for WASD or that the "literal" scheme needs to be used.
         */

        return [
            .up : .two,
            .w : .two,
            .right : .six,
            .d : .six,
            .down: .eight,
            .s : .eight,
            .left : .four,
            .a : .four,
            .space : .five,
            .e : .five,
        ]
    }

    static var literal: KeyMapping {
        return [
            .zero : .zero,
            .one : .one,
            .two : .two,
            .three : .three,
            .four : .four,
            .five : .five,
            .six : .six,
            .seven : .seven,
            .eight : .eight,
            .nine : .nine,
            .a : .a,
            .b : .b,
            .c : .c,
            .d : .d,
            .e : .e,
            .f : .f,
        ]
    }
}
