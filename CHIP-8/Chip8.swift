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

    init(state: ChipState, hz: TimeInterval) {
        self.state = state
        self.opExecutor = OpExecutor(hz: hz)
    }

    public var shouldPlaySound: Bool {
        return state.shouldPlaySound
    }

    public var pixels: [Byte] {
        return state.pixels
    }

    public func cycle() {
        self.state = try! opExecutor.handle(state: self.state, op: state.currentOp)
    }

    public func handleKeyDown(key: Int) {
        state.downKeys.add(Byte(key))
    }

    public func handleKeyUp(key: Int) {
        state.downKeys.remove(Byte(key))
    }
}
