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
        // TODO: better mapping
        // macKey : chip8Key
        let keyMapping: [UInt16 : Int] = [
            0 : 0,
            1 : 1,
            2 : 2,
            3 : 3,
            4 : 4,
            5 : 5,
            6 : 6,
            7 : 7,
            8 : 8,
            9 : 9,
            10 : 10,
            11 : 11,
            12 : 12,
            13 : 13,
            14 : 14,
            15 : 15,
        ]

        return keyMapping[input]
    }
}

// handle inputs
extension ViewController {
    @IBAction func loadRomPressed(_ sender: NSButton) {
        timer?.invalidate()
        self.runRomSelectorModal()
    }
}

