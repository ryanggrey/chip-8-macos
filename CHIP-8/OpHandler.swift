//
//  OpHandler.swift
//  CHIP-8
//
//  Created by Ryan Grey on 01/02/2021.
//

import Foundation

protocol OpHandler {
    func handle(state: ChipState, op: Word) -> ChipState
}
