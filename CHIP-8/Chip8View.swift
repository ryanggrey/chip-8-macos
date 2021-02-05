//
//  Chip8View.swift
//  CHIP-8
//
//  Created by Ryan Grey on 03/02/2021.
//

import Cocoa

class Chip8View: NSView {
    var bitmap: [Byte] {
        didSet {
            needsDisplay = true
        }
    }

    // TODO: inject
    private let bitmapWidth = 64
    private let bitmapHeight = 32

    required init?(coder: NSCoder) {
        bitmap = [Byte](repeating: 0, count: bitmapWidth * bitmapHeight)
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawBackground()
        drawPixels()
    }

    override var isFlipped: Bool { return true }

    private func drawBackground() {
        // draw black background
        NSColor.black.setFill()
        bounds.fill()
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    private func drawPixels() {
        // draw white pixels
        NSColor.white.setFill()
        let pixelWidth = round(self.frame.size.width / CGFloat(bitmapWidth))
        let pixelHeight = round(self.frame.size.height / CGFloat(bitmapHeight))
        let pixelSize = CGSize(width: pixelWidth, height: pixelHeight)

        let xRange = 0..<bitmapWidth
        let yRange = 0..<bitmapHeight
        for x in xRange {
            for y in yRange {
                let pixelAddress = y * bitmapWidth + x
                guard bitmap[pixelAddress] == 1 else {
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
