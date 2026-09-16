import AppKit
import Carbon
import ServiceManagement
import GridTileCore

func tileNow() {
    let mouse = NSEvent.mouseLocation
    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main else { return }
    let windows = visibleWindows(on: screen)
    let cells = gridLayout(count: windows.count, in: cgRect(of: screen.visibleFrame))
    var rowCounts: [CGFloat: Int] = [:]
    cells.forEach { rowCounts[$0.minY, default: 0] += 1 }
    let line = "\(Date()) trusted=\(AXIsProcessTrusted()) screen=\(NSStringFromRect(screen.visibleFrame)) windows=\(windows.count) rows=\(rowCounts.keys.sorted().map { String(rowCounts[$0]!) }.joined(separator: "+"))\n"
    let logURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/GridTile.log")
    if let h = try? FileHandle(forWritingTo: logURL) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() }
    else { try? line.write(to: logURL, atomically: true, encoding: .utf8) }
    for (window, cell) in zip(windows, cells) {
        apply(frame: cell, to: window.ax)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var hotkey: Hotkey!
    private let axItem = NSMenuItem(title: "", action: #selector(openAccessibilitySettings), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        // Bound every AX call, not only per-app ones (per-element timeouts do not cover window elements).
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.5)

        hotkey = Hotkey(keyCode: UInt32(kVK_ANSI_T), modifiers: UInt32(controlKey | optionKey | cmdKey)) {
            tileNow()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⊞"

        let menu = NSMenu()
        menu.delegate = self

        let tileItem = NSMenuItem(title: "Tile Now  ⌃⌥⌘T", action: #selector(tile), keyEquivalent: "")
        tileItem.target = self
        menu.addItem(tileItem)

        if !hotkey.isRegistered {
            let item = NSMenuItem(title: "Hotkey ⌃⌥⌘T failed to register", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        axItem.target = self
        menu.addItem(axItem)

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // Re-check Accessibility every time the menu opens; the grant can change while running.
    func menuNeedsUpdate(_ menu: NSMenu) {
        let trusted = AXIsProcessTrusted()
        axItem.title = trusted ? "Accessibility: granted" : "Accessibility: not granted (click to open settings)"
        axItem.isEnabled = !trusted
    }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
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

// Debug trigger: `kill -USR1 $(pgrep -x GridTile)` tiles without the hotkey.
signal(SIGUSR1, SIG_IGN)
let usr1 = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
usr1.setEventHandler { tileNow() }
usr1.resume()

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
