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
        self = nibbles.reduce(0x0) { (last, next) -> Word in
            return last << 4 | Word(next)
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
}
