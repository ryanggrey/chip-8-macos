//
//  ViewController.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Cocoa

class Chip8ViewController: NSViewController {
    
    @IBOutlet weak var chip8View: Chip8View!
    @IBOutlet weak var controlSchemeComboBox: NSComboBox!
    @IBOutlet weak var backgroundColorWell: NSColorWell!
    @IBOutlet weak var pixelColorWell: NSColorWell!
    
    private var chip8: Chip8!
    private var loadedRom: [Byte]?
    private var timer: Timer?
    private let cpuHz: TimeInterval = 1/600
    private let beep = NSSound(data: NSDataAsset(name: "chip8-beep")!.data)!
    private var activeKeyMapping: KeyMapping?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetControlScheme()
        resetColors()
    }
    
    private func resetColors() {
        backgroundColorWell.color = NSColor.black
        updateBackground(color: backgroundColorWell.color)
        pixelColorWell.color = NSColor.white
        updatePixel(color: pixelColorWell.color)
    }
    
    private func updateBackground(color: NSColor) {
        chip8View.backgroundColor = color
        chip8View.needsDisplay = true
    }
    
    private func updatePixel(color: NSColor) {
        chip8View.pixelColor = color
        chip8View.needsDisplay = true
    }
    
    private func runRomSelectorModal() {
        RomSelectorModal.runModal { [weak self] loadedRom in
            self?.loadedRom = loadedRom
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
    
    private func resetControlScheme() {
        controlSchemeComboBox.dataSource = self
        controlSchemeComboBox.delegate = self
        controlSchemeComboBox.selectItem(at: 0)
    }
    
    private func getControlSchemes() -> [ControlScheme] {
        let wasdScheme = ControlScheme(name: "WASD Controls", mapping: KeyMapping.wasd)
        let fullScheme = ControlScheme(name: "Literal Controls", mapping: KeyMapping.literal)
        return [wasdScheme, fullScheme]
    }
    
    private func updateControlScheme(index: Int) {
        activeKeyMapping = getControlSchemes()[index].mapping
    }
}

extension Chip8ViewController: NSComboBoxDataSource, NSComboBoxDelegate {
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

// handle control actions
extension Chip8ViewController {
    @IBAction func loadRomPressed(_ sender: NSButton) {
        timer?.invalidate()
        self.runRomSelectorModal()
    }
    
    @IBAction func restartPressed(_ sender: NSButton) {
        timer?.invalidate()
        guard let loadedRom = loadedRom else { return }
        self.runEmulator(with: loadedRom)
    }
    
    @IBAction func backgroundColorChanged(_ sender: NSColorWell) {
        updateBackground(color: sender.color)
    }
    
    @IBAction func pixelColourChanged(_ sender: NSColorWell) {
        updatePixel(color: sender.color)
    }
}

