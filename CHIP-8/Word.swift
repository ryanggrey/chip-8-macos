//
//  Word.swift
//  CHIP-8
//
//  Created by Ryan Grey on 25/01/2021.
//

import Foundation

public typealias Word = UInt16 // 16 bits

extension Word {
    init(nibbles: [Byte]) {
        self = nibbles.reduce(0x0) { (last, next) -> UInt16 in
            return last << 4 | Word(next)
        }
    }
}
