import CoreGraphics

/// Splits `area` into `count` cells. cols = ceil(sqrt(count)), rows = ceil(count/cols).
/// Full rows have `cols` cells. The last row stretches its cells to fill the width.
/// Cells are returned left-to-right, top-to-bottom, in CG coordinates (y down).
public func gridLayout(count: Int, in area: CGRect) -> [CGRect] {
    guard count > 0 else { return [] }
    let cols = Int(Double(count).squareRoot().rounded(.up))
    let rows = (count + cols - 1) / cols
    let rowHeight = area.height / CGFloat(rows)
    var cells: [CGRect] = []
    cells.reserveCapacity(count)
    for row in 0..<rows {
        let inRow = min(cols, count - row * cols)
        let width = area.width / CGFloat(inRow)
        for col in 0..<inRow {
            cells.append(CGRect(
                x: area.minX + CGFloat(col) * width,
                y: area.minY + CGFloat(row) * rowHeight,
                width: width,
                height: rowHeight))
        }
    }
    return cells
}
