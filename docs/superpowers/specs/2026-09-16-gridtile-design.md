# GridTile design

Menu-bar macOS app. One hotkey tiles every visible window on the current display into an auto-sized grid.

## Behavior

- Hotkey: Ctrl+Opt+Cmd+T (global, Carbon `RegisterEventHotKey`).
- Target display: the one under the mouse cursor. Usable area: `NSScreen.visibleFrame` (excludes menu bar and Dock).
- Window set: windows from `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements])` with layer 0, alpha > 0, width and height > 50, owner not Dock / WindowServer / Control Center / Notification Center / Window Server / GridTile itself, and center point inside the target display. This yields only windows on the current Space and display, not minimized, not hidden.
- Order: sort by y then x of current frame (top-left first). Cells fill left to right, top to bottom.
- Grid: N windows. `cols = ceil(sqrt(N))`, `rows = ceil(N / cols)`. Every full row has `cols` cells. Last row has `N - (rows-1)*cols` cells, each stretched to `width / lastCount`. Gap 0.
  - 1 -> 1x1. 2 -> 2x1. 4 -> 2x2. 7 -> 3 cols, rows 3,3,1. 12 -> 4x3.
- Apply: for each window, find AX window (`AXUIElementCreateApplication(pid)` -> `kAXWindowsAttribute`) whose current AX frame matches the CG frame within 2px. Set `kAXPositionAttribute` then `kAXSizeAttribute`. Windows that refuse a size (minimum-size apps) are left at whatever size they accept. No retry.
- 0 windows: no-op.
- Accessibility permission: on launch call `AXIsProcessTrustedWithOptions` with prompt. Menu shows "Accessibility: not granted" item if false.
- Menu bar: `NSStatusItem`, items: Tile Now (same action as hotkey), Launch at Login (toggle, `SMAppService.mainApp`), Quit.
- App is `LSUIElement` (no Dock icon).

## Layout

```
gridtile/
  Package.swift            # executable target GridTile, test target GridTileTests, macOS 13+
  Sources/GridTile/
    Grid.swift             # func gridLayout(count: Int, in area: CGRect) -> [CGRect]
    Windows.swift          # struct VisibleWindow {pid, cgFrame, ax: AXUIElement}; func visibleWindows(on: NSScreen) -> [VisibleWindow]; func apply(frame:to:)
    Hotkey.swift           # register Carbon hotkey, call closure
    main.swift             # NSApplication setup, status item, wiring
    Info.plist             # LSUIElement, bundle id com.local.gridtile
  Tests/GridTileTests/GridTests.swift
  build.sh                 # swift build -c release; assemble build/GridTile.app; ad-hoc codesign; cp -R to /Applications
```

## Coordinate systems

- CGWindowList frames: origin top-left of primary display, y down.
- AX position/size: same as CG (top-left origin, y down).
- `NSScreen.visibleFrame`: origin bottom-left, y up. Convert to CG: `cgY = primaryHeight - (frame.origin.y + frame.height)`.
- `gridLayout` operates in CG coordinates only.

## Testing

- Unit tests for `gridLayout`: counts 0, 1, 2, 4, 7, 12. Assert cell count, rects tile the area without overlap, last row stretches to full width.
- Windows/AX/hotkey verified manually: run app, open 7 windows, press hotkey.

## Out of scope

Gaps, multi-display tiling in one press, saved layouts, undo, per-app exclusions, configurable hotkey.
