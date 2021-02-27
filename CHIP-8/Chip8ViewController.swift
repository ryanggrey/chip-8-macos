//
//  ViewController.swift
//  CHIP-8
//
//  Created by Ryan Grey on 22/01/2021.
//

import Cocoa
import Chip8Emulator

class Chip8ViewController: NSViewController {
    
    @IBOutlet weak var chip8View: Chip8View!
    @IBOutlet weak var controlSchemeComboBox: NSComboBox!
    @IBOutlet weak var backgroundColorWell: NSColorWell!
    @IBOutlet weak var pixelColorWell: NSColorWell!

    private var loadedRom: [Byte]?
    private var activeKeyMapping: KeyMapping?
    private let chip8Engine = Chip8Engine()
    private let beepPlayer = BeepPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupChip8Engine()
        setupControlScheme()
        setupColors()
    }

    private func setupChip8Engine() {
        chip8Engine.delegate = self
    }
    
    private func setupColors() {
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
        chip8Engine.start(with: rom)
    }
    
    override func keyDown(with event: NSEvent) {
        guard let key = chip8Key(from: event.keyCode), !event.isARepeat else { return }
        chip8Engine.handleKeyDown(key: key)
    }
    
    override func keyUp(with event: NSEvent) {
        guard let key = chip8Key(from: event.keyCode), !event.isARepeat else { return }
        chip8Engine.handleKeyUp(key: key)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    private func chip8Key(from input: UInt16) -> Chip8InputCode? {
        guard let key = MacKeyCode(rawValue: input),
              let inputCode = activeKeyMapping?[key]
              else { return nil }

        return inputCode
    }
    
    private func setupControlScheme() {
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
        chip8Engine.stop()
        self.runRomSelectorModal()
    }
    
    @IBAction func restartPressed(_ sender: NSButton) {
        chip8Engine.stop()
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

extension Chip8ViewController: Chip8EngineDelegate {
    func beep() {
        beepPlayer.play()
    }
    
    func render(screen: Chip8Screen) {
        chip8View.screen = screen
        chip8View.needsDisplay = true
    }
}

