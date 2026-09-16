// Renders the GridTile app icon. Usage: swift scripts/make-icon.swift assets/icon-1024.png
import AppKit

let out = CommandLine.arguments[1]
let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Background: rounded square, dark gradient (macOS icon grid margin ~10%)
let inset: CGFloat = 100
let bg = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
let path = CGPath(roundedRect: bg, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.addPath(path); ctx.clip()
let colors = [NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.16, alpha: 1).cgColor,
              NSColor(calibratedRed: 0.17, green: 0.19, blue: 0.27, alpha: 1).cgColor] as CFArray
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

// Grid: 3 top, 2 bottom (stretched), the signature "auto-fit" layout
let pad: CGFloat = 78, gap: CGFloat = 34
let area = bg.insetBy(dx: pad, dy: pad)
let rowH = (area.height - gap) / 2
let accent = [NSColor(calibratedRed: 0.36, green: 0.62, blue: 1.0, alpha: 1),
              NSColor(calibratedRed: 0.55, green: 0.86, blue: 0.99, alpha: 1)]
func cell(_ r: CGRect, _ c: NSColor) {
    let p = CGPath(roundedRect: r, cornerWidth: 44, cornerHeight: 44, transform: nil)
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(p); ctx.setFillColor(c.cgColor); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    // window title bar hint
    let bar = CGRect(x: r.minX + 26, y: r.maxY - 62, width: r.width - 52, height: 22)
    ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 11, cornerHeight: 11, transform: nil))
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.55).cgColor); ctx.fillPath()
}
let topW = (area.width - 2 * gap) / 3
for i in 0..<3 {
    cell(CGRect(x: area.minX + CGFloat(i) * (topW + gap), y: area.minY + rowH + gap, width: topW, height: rowH), accent[i % 2])
}
let botW = (area.width - gap) / 2
for i in 0..<2 {
    cell(CGRect(x: area.minX + CGFloat(i) * (botW + gap), y: area.minY, width: botW, height: rowH), accent[(i + 1) % 2])
}
img.unlockFocus()

let tiff = img.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
rep.size = NSSize(width: S, height: S)
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
