//
//  Chip8.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Foundation

struct NotImplemented: Error {}

public class Chip8 {
    private var state: ChipState
    private let opExecutor: OpExecutor

    init(state: ChipState) {
        self.state = state
        self.opExecutor = OpExecutor()
    }

    public var pixels: [Byte] {
        return state.pixels
    }

    public func cycle() {
        self.state = try! opExecutor.handle(state: self.state, op: state.currentOp)
    }
}
