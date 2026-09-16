import CoreGraphics

/// Splits `area` into `count` cells, choosing the row count from the area's aspect ratio
/// so cells stay close to square: rows = round(sqrt(count * height / width)), cols = ceil(count / rows).
/// On a 16:9 display: 2 -> 2x1, 3 -> 3x1, 4 -> 2x2, 5 -> 3+2, 7 -> 4+3, 12 -> 4x3.
/// Full rows have `cols` cells. The last row stretches its cells to fill the width.
/// Cells are returned left-to-right, top-to-bottom, in CG coordinates (y down).
public func gridLayout(count: Int, in area: CGRect) -> [CGRect] {
    guard count > 0, area.width > 0, area.height > 0 else { return [] }
    let ideal = (Double(count) * Double(area.height) / Double(area.width)).squareRoot()
    var rows = max(1, min(count, Int(ideal.rounded())))
    let cols = (count + rows - 1) / rows
    rows = (count + cols - 1) / cols   // drop rows that would be empty
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
