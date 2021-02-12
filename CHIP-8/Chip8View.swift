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

        // draw white pixels
        pixelColor.setFill()
        let pixelWidth = round(self.frame.size.width / CGFloat(screen.size.width))
        let pixelHeight = round(self.frame.size.height / CGFloat(screen.size.height))
        let pixelSize = CGSize(width: pixelWidth, height: pixelHeight)

        let xRange = 0..<screen.size.width
        let yRange = 0..<screen.size.height
        for x in xRange {
            for y in yRange {
                let pixelAddress = y * screen.size.width + x
                guard screen.pixels[pixelAddress] == 1 else {
                    // skip if we're not meant to draw pixel
                    continue
                }

                let xCoord = CGFloat(x) * pixelSize.width
                let yCoord = CGFloat(y) * pixelSize.height
                let origin = CGPoint(x: xCoord, y: yCoord)
                let frame = NSRect(origin: origin, size: pixelSize)
                frame.fill()
            }
        }
    }
}
