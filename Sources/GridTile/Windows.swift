import AppKit
import ApplicationServices

struct VisibleWindow {
    let pid: pid_t
    let frame: CGRect      // CG coordinates
    let ax: AXUIElement
}

private let excludedOwners: Set<String> = [
    "Dock", "WindowServer", "Window Server", "Control Center",
    "Notification Center", "Spotlight", "GridTile",
]

/// Converts an AppKit rect (origin bottom-left of primary display, y up)
/// to CG coordinates (origin top-left of primary display, y down).
func cgRect(of nsRect: CGRect) -> CGRect {
    let primaryHeight = NSScreen.screens[0].frame.height
    return CGRect(x: nsRect.minX, y: primaryHeight - nsRect.maxY, width: nsRect.width, height: nsRect.height)
}

/// Windows currently on screen (current Space, not minimized, not hidden) whose center
/// lies on `screen`. Sorted top-to-bottom, then left-to-right.
func visibleWindows(on screen: NSScreen) -> [VisibleWindow] {
    let target = cgRect(of: screen.frame)
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }

    var result: [VisibleWindow] = []
    for info in list {
        guard (info[kCGWindowLayer as String] as? Int) == 0,
              (info[kCGWindowAlpha as String] as? Double ?? 1) > 0,
              let pid = info[kCGWindowOwnerPID as String] as? pid_t,
              let owner = info[kCGWindowOwnerName as String] as? String,
              !excludedOwners.contains(owner),
              let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
              let frame = CGRect(dictionaryRepresentation: boundsDict),
              frame.width > 50, frame.height > 50,
              target.contains(CGPoint(x: frame.midX, y: frame.midY)),
              let ax = axWindow(pid: pid, matching: frame)
        else { continue }
        result.append(VisibleWindow(pid: pid, frame: frame, ax: ax))
    }
    return result.sorted { a, b in
        a.frame.minY != b.frame.minY ? a.frame.minY < b.frame.minY : a.frame.minX < b.frame.minX
    }
}

private func axWindow(pid: pid_t, matching frame: CGRect) -> AXUIElement? {
    let app = AXUIElementCreateApplication(pid)
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
          let windows = value as? [AXUIElement] else { return nil }
    return windows.first { w in
        guard let f = axFrame(w) else { return false }
        return abs(f.minX - frame.minX) <= 2 && abs(f.minY - frame.minY) <= 2
            && abs(f.width - frame.width) <= 2 && abs(f.height - frame.height) <= 2
    }
}

private func axFrame(_ w: AXUIElement) -> CGRect? {
    var posRef: CFTypeRef?
    var sizeRef: CFTypeRef?
    guard AXUIElementCopyAttributeValue(w, kAXPositionAttribute as CFString, &posRef) == .success,
          AXUIElementCopyAttributeValue(w, kAXSizeAttribute as CFString, &sizeRef) == .success,
          let posVal = posRef, let sizeVal = sizeRef,
          CFGetTypeID(posVal) == AXValueGetTypeID(), CFGetTypeID(sizeVal) == AXValueGetTypeID()
    else { return nil }
    var pos = CGPoint.zero
    var size = CGSize.zero
    AXValueGetValue(posVal as! AXValue, .cgPoint, &pos)
    AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
    return CGRect(origin: pos, size: size)
}

/// Sets position then size. Apps with minimum sizes keep whatever size they accept.
func apply(frame: CGRect, to w: AXUIElement) {
    var pos = frame.origin
    var size = frame.size
    if let v = AXValueCreate(.cgPoint, &pos) {
        AXUIElementSetAttributeValue(w, kAXPositionAttribute as CFString, v)
    }
    if let v = AXValueCreate(.cgSize, &size) {
        AXUIElementSetAttributeValue(w, kAXSizeAttribute as CFString, v)
    }
}
