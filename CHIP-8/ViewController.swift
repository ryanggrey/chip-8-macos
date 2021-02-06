//
//  ViewController.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var chip8View: Chip8View!
    @IBOutlet weak var controlSchemeComboBox: NSComboBox!

    private var chip8: Chip8!
    private var timer: Timer?
    private let cpuHz: TimeInterval = 1/600
    private let beep = NSSound(data: NSDataAsset(name: "chip8-beep")!.data)!

    override func viewDidLoad() {
        super.viewDidLoad()
        resetControlScheme()
    }

    private func runRomSelectorModal() {
        RomSelectorModal.runModal { [weak self] loadedRom in
            self?.runEmulator(with: loadedRom)
        }
    }

    private func runEmulator(with rom: [Byte]) {
        var chipState = ChipState()
        chipState.ram = rom

        self.chip8 = Chip8(
            state: chipState,
            cpuHz: cpuHz
        )
        timer = Timer.scheduledTimer(
            timeInterval: cpuHz,
            target: self,
            selector: #selector(self.timerFired),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func timerFired() {
        chip8.cycle()
        render(screen: chip8.screen)
        if chip8.shouldPlaySound && !beep.isPlaying {
            beep.play()
        }
    }

    private func render(screen: Chip8Screen) {
        chip8View.screen = screen
        chip8View.needsDisplay = true
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
        return activeKeyMapping?[key]?.rawValue
    }

    let wasdKeyMapping: KeyMapping = [
        .up : .two,
        .w : .two,
        .right : .six,
        .d : .six,
        .down: .eight,
        .s : .eight,
        .left : .four,
        .a : .four,
        .space : .five,
        .e : .five,
    ]

    let literalKeyMapping: KeyMapping = [
        .zero : .zero,
        .one : .one,
        .two : .two,
        .three : .three,
        .four : .four,
        .five : .five,
        .six : .six,
        .seven : .seven,
        .eight : .eight,
        .nine : .nine,
        .a : .a,
        .b : .b,
        .c : .c,
        .d : .d,
        .e : .e,
        .f : .f,
    ]

    private func resetControlScheme() {
        controlSchemeComboBox.dataSource = self
        controlSchemeComboBox.delegate = self
        controlSchemeComboBox.selectItem(at: 0)
    }

    private func getControlSchemes() -> [ControlScheme] {
        let wasdScheme = ControlScheme(name: "WASD Controls", mapping: wasdKeyMapping)
        let fullScheme = ControlScheme(name: "Literal Controls", mapping: literalKeyMapping)
        return [wasdScheme, fullScheme]
    }

    private func updateControlScheme(index: Int) {
        activeKeyMapping = getControlSchemes()[index].mapping
    }

    private var activeKeyMapping: KeyMapping?
}

typealias KeyMapping = [MacKeyCode : Chip8KeyCode]

struct ControlScheme {
    let name: String
    let mapping: KeyMapping
}

enum MacKeyCode: CGKeyCode {
    case zero = 0x1D
    case one = 0x12
    case two = 0x13
    case three = 0x14
    case four = 0x15
    case five = 0x17
    case six = 0x16
    case seven = 0x1A
    case eight = 0x1C
    case nine = 0x19
    // case a = 0x00
    case b = 0x0B
    case c = 0x08
    // case d = 0x02
    // case e = 0x0E
    case f = 0x03

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

enum Chip8KeyCode: Int {case zero = 0x0
    case one = 0x1
    case two = 0x2 // up
    case three = 0x3
    case four = 0x4 // left
    case five = 0x5 // centre
    case six = 0x6 // right
    case seven = 0x7
    case eight = 0x8 // down
    case nine = 0x9
    case a = 0xa
    case b = 0xb
    case c = 0xc
    case d = 0xd
    case e = 0xe
    case f = 0xf
}

extension ViewController: NSComboBoxDataSource, NSComboBoxDelegate {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return getControlSchemes().count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return getControlSchemes()[index].name
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        guard let comboBox = notification.object as? NSComboBox else { return }

        updateControlScheme(index: comboBox.indexOfSelectedItem)
    }
}

// handle inputs
extension ViewController {
    @IBAction func loadRomPressed(_ sender: NSButton) {
        timer?.invalidate()
        self.runRomSelectorModal()
    }
}

