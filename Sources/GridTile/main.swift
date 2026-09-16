import AppKit
import Carbon
import ServiceManagement
import GridTileCore

func tileNow() {
    let mouse = NSEvent.mouseLocation
    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main else { return }
    let windows = visibleWindows(on: screen)
    let cells = gridLayout(count: windows.count, in: cgRect(of: screen.visibleFrame))
    for (window, cell) in zip(windows, cells) {
        apply(frame: cell, to: window.ax)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotkey: Hotkey!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        hotkey = Hotkey(keyCode: UInt32(kVK_ANSI_T), modifiers: UInt32(controlKey | optionKey | cmdKey)) {
            tileNow()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⊞"

        let menu = NSMenu()

        let tileItem = NSMenuItem(title: "Tile Now  ⌃⌥⌘T", action: #selector(tile), keyEquivalent: "")
        tileItem.target = self
        menu.addItem(tileItem)

        if !hotkey.isRegistered {
            let item = NSMenuItem(title: "Hotkey ⌃⌥⌘T unavailable (in use by another app)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        if !trusted {
            menu.addItem(NSMenuItem(title: "Accessibility: not granted", action: nil, keyEquivalent: ""))
        }

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func tile() { tileNow() }

    @objc private func toggleLogin(_ item: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                item.state = .off
            } else {
                try SMAppService.mainApp.register()
                item.state = .on
            }
        } catch {
            NSLog("Launch at Login failed: \(error)")
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
