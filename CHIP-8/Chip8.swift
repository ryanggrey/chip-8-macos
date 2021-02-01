//
//  Chip8.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Foundation

struct NotImplemented: Error {}

public class Chip8 {
    private var state = ChipState()
    private let opExecutor: OpHandler

    init() {
        opExecutor = OpExecutor()
    }

    public func performCycle() {
        // TODO:
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
