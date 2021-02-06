//
//  ViewController.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var chip8View: Chip8View!
    private var chip8: Chip8!
    private var timer: Timer?
    private let hz: TimeInterval = 1/600
    private let beep = NSSound(data: NSDataAsset(name: "chip8-beep")!.data)!

    private func runRomSelectorModal() {
        RomSelectorModal.runModal { [weak self] loadedRom in
            self?.runEmulator(with: loadedRom)
        }
    }

    private func runEmulator(with rom: [Byte]) {
        let chipState = ChipState(ram: rom)
        self.chip8 = Chip8(state: chipState, hz: hz)
        timer = Timer.scheduledTimer(
            timeInterval: hz,
            target: self,
            selector: #selector(self.timerFired),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func timerFired() {
        chip8.cycle()
        render(pixels: chip8.pixels)
        if chip8.shouldPlaySound && !beep.isPlaying {
            beep.play()
        }
    }

    private func render(pixels: [Byte]) {
        chip8View.bitmap = pixels
    }

    override func keyDown(with event: NSEvent) {
        guard let key = chip8Key(from: event.keyCode), !event.isARepeat else { return }
        chip8.handleKeyDown(key: key)
    }

    override func keyUp(with event: NSEvent) {
        guard let key = chip8Key(from: event.keyCode), !event.isARepeat else { return }
        chip8.handleKeyUp(key: key)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    private func chip8Key(from input: UInt16) -> Int? {
        guard let key = MacKeyCode(rawValue: input) else { return nil }
        let keyMapping: [MacKeyCode : Chip8KeyCode] = [
            .up : .up,
            .w : .up,
            .right : .right,
            .d : .right,
            .down: .down,
            .s : .down,
            .left : .left,
            .a : .left,
            .space : .centre,
            .e : .centre,
        ]

        return keyMapping[key]?.rawValue
    }
}

enum MacKeyCode: CGKeyCode {
    case up = 0x7E
    case w = 0x0D
    case right = 0x7C
    case d = 0x02
    case down = 0x7D
    case s = 0x01
    case left = 0x7B
    case a = 0x00
    case space = 0x31
    case e = 0x0E
}

enum Chip8KeyCode: Int {
    case up = 2
    case right = 6
    case down = 8
    case left = 4
    case centre = 5
}

// handle inputs
extension ViewController {
    @IBAction func loadRomPressed(_ sender: NSButton) {
        timer?.invalidate()
        self.runRomSelectorModal()
    }
}

