import Carbon

/// Global hotkey via Carbon. Keep the instance alive for as long as the hotkey should work.
final class Hotkey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let handler: () -> Void
    /// False when registration failed. A cross-app conflict is not reported by Carbon; the key then never fires.
    let isRegistered: Bool

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.handler = handler
        let id = EventHotKeyID(signature: 0x4752_4454 /* "GRDT" */, id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        isRegistered = status == noErr
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            Unmanaged<Hotkey>.fromOpaque(userData).takeUnretainedValue().handler()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
    }

    deinit {
        if let ref = handlerRef { RemoveEventHandler(ref) }
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
    }
}
