import AppKit
import ApplicationServices

struct VisibleWindow {
    let frame: CGRect      // CG coordinates
    let ax: AXUIElement
}

private let excludedOwners: Set<String> = [
    "Dock", "WindowServer", "Window Server", "Control Center",
    "Notification Center", "Spotlight", "GridTile",
]

/// Vertical tolerance for treating two windows as being in the same row.
private let rowTolerance: CGFloat = 40

/// Converts an AppKit rect (origin bottom-left of primary display, y up)
/// to CG coordinates (origin top-left of primary display, y down).
func cgRect(of nsRect: CGRect) -> CGRect {
    let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first
    guard let primary else { return nsRect }
    return CGRect(x: nsRect.minX, y: primary.frame.height - nsRect.maxY, width: nsRect.width, height: nsRect.height)
}

/// Windows currently on screen (current Space, not minimized, not hidden) whose center
/// lies on `screen`. Sorted top-to-bottom by row, then left-to-right within each row.
func visibleWindows(on screen: NSScreen) -> [VisibleWindow] {
    let target = cgRect(of: screen.frame)
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }

    var used = Set<AXUIElement>()
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
              let ax = axWindow(pid: pid, matching: frame, used: &used)
        else { continue }
        result.append(VisibleWindow(frame: frame, ax: ax))
    }
    return rowMajorSorted(result)
}

/// Sorts top-to-bottom, then groups windows whose minY is within `rowTolerance`
/// of the group's first window into a row and sorts that row left-to-right.
private func rowMajorSorted(_ windows: [VisibleWindow]) -> [VisibleWindow] {
    let byTop = windows.sorted { $0.frame.minY < $1.frame.minY }
    var out: [VisibleWindow] = []
    out.reserveCapacity(byTop.count)
    var row: [VisibleWindow] = []
    for w in byTop {
        if let first = row.first, w.frame.minY - first.frame.minY > rowTolerance {
            out.append(contentsOf: row.sorted { $0.frame.minX < $1.frame.minX })
            row = []
        }
        row.append(w)
    }
    out.append(contentsOf: row.sorted { $0.frame.minX < $1.frame.minX })
    return out
}

private func axWindow(pid: pid_t, matching frame: CGRect, used: inout Set<AXUIElement>) -> AXUIElement? {
    let app = AXUIElementCreateApplication(pid)
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
          let windows = value as? [AXUIElement] else { return nil }
    let match = windows.first { w in
        guard !used.contains(w), axRole(w) == kAXWindowRole, let f = axFrame(w) else { return false }
        return abs(f.minX - frame.minX) <= 2 && abs(f.minY - frame.minY) <= 2
            && abs(f.width - frame.width) <= 2 && abs(f.height - frame.height) <= 2
    }
    if let match { used.insert(match) }
    return match
}

private func axRole(_ w: AXUIElement) -> String? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(w, kAXRoleAttribute as CFString, &value) == .success else { return nil }
    return value as? String
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

/// Sets size, then position, then size again. Setting position first makes some apps
/// overshoot the requested height by a pixel. Apps with minimum sizes keep whatever
/// size they accept.
func apply(frame: CGRect, to w: AXUIElement) {
    setSize(frame.size, on: w)
    setPosition(frame.origin, on: w)
    setSize(frame.size, on: w)
}

private func setPosition(_ origin: CGPoint, on w: AXUIElement) {
    var pos = origin
    if let v = AXValueCreate(.cgPoint, &pos) {
        AXUIElementSetAttributeValue(w, kAXPositionAttribute as CFString, v)
    }
}

private func setSize(_ size: CGSize, on w: AXUIElement) {
    var s = size
    if let v = AXValueCreate(.cgSize, &s) {
        AXUIElementSetAttributeValue(w, kAXSizeAttribute as CFString, v)
    }
}
