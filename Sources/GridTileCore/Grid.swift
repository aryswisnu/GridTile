import CoreGraphics
import Foundation

/// Splits `area` into `count` cells. Tries every column count and scores each candidate by the
/// worst cell in it: |ln(width / height)| over both the full rows and the stretched last row.
/// Lowest score wins, so cells stay as square as the display allows and a ragged last row
/// with one huge stretched window loses. On a 16:9 display: 2 -> 2x1, 3 -> 3x1, 4 -> 2x2,
/// 5 -> 3+2, 7 -> 4+3, 12 -> 4x3. On a portrait display rows win over columns.
/// Cells are returned left-to-right, top-to-bottom, in CG coordinates (y down).
public func gridLayout(count: Int, in area: CGRect) -> [CGRect] {
    guard count > 0, area.width > 0, area.height > 0 else { return [] }
    var best = (cols: count, rows: 1, score: Double.infinity)
    for cols in stride(from: count, through: 1, by: -1) {   // ties go to fewer rows
        let rows = (count + cols - 1) / cols
        let rowHeight = Double(area.height) / Double(rows)
        let lastCount = count - (rows - 1) * cols
        let full = abs(log((Double(area.width) / Double(cols)) / rowHeight))
        let last = abs(log((Double(area.width) / Double(lastCount)) / rowHeight))
        let score = max(full, last)
        if score < best.score { best = (cols, rows, score) }
    }
    let (cols, rows) = (best.cols, best.rows)
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
