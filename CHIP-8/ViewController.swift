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
        self.chip8 = Chip8(state: chipState)
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
}

// handle inputs
extension ViewController {
    @IBAction func loadRomPressed(_ sender: NSButton) {
        timer?.invalidate()
        self.runRomSelectorModal()
    }
}

