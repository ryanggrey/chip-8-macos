//
//  Chip8View.swift
//  CHIP-8
//
//  Created by Ryan Grey on 03/02/2021.
//

import Cocoa
import Chip8Emulator

class Chip8View: NSView {
    var screen: Chip8Screen?
    var backgroundColor: NSColor?
    var pixelColor: NSColor?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawBackground()
        drawPixels()
    }

    override var isFlipped: Bool { return true }

    private func drawBackground() {
        guard let backgroundColor = backgroundColor else { return }
        
        backgroundColor.setFill()
        bounds.fill()
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    private func drawPixels() {
        guard let screen = screen, let pixelColor = pixelColor else { return }

        guard let context = NSGraphicsContext.current else { return }
        let path = PathFactory.from(
            screen: screen,
            containerSize: self.frame.size,
            isYReversed: false
            )
        context.cgContext.setFillColor(pixelColor.cgColor)
        context.cgContext.addPath(path)
        context.cgContext.fillPath()
    }
}
