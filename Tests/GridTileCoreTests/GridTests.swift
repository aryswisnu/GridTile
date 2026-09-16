import XCTest
@testable import GridTileCore

final class GridTests: XCTestCase {
    let area = CGRect(x: 0, y: 25, width: 1200, height: 800)

    func testZeroReturnsEmpty() {
        XCTAssertEqual(gridLayout(count: 0, in: area), [])
    }

    func testOneFillsArea() {
        XCTAssertEqual(gridLayout(count: 1, in: area), [area])
    }

    func testTwoIsSideBySide() {
        let cells = gridLayout(count: 2, in: area)
        XCTAssertEqual(cells, [
            CGRect(x: 0, y: 25, width: 600, height: 800),
            CGRect(x: 600, y: 25, width: 600, height: 800),
        ])
    }

    func testFourIsTwoByTwo() {
        let cells = gridLayout(count: 4, in: area)
        XCTAssertEqual(cells.count, 4)
        XCTAssertEqual(cells[0], CGRect(x: 0, y: 25, width: 600, height: 400))
        XCTAssertEqual(cells[1], CGRect(x: 600, y: 25, width: 600, height: 400))
        XCTAssertEqual(cells[2], CGRect(x: 0, y: 425, width: 600, height: 400))
        XCTAssertEqual(cells[3], CGRect(x: 600, y: 425, width: 600, height: 400))
    }

    func testSevenIsThreeColsLastRowStretched() {
        let cells = gridLayout(count: 7, in: area)
        XCTAssertEqual(cells.count, 7)
        // rows of 3,3,1. row height 800/3.
        let rowH = 800.0 / 3.0
        XCTAssertEqual(cells[0].width, 400, accuracy: 0.001)
        XCTAssertEqual(cells[0].height, rowH, accuracy: 0.001)
        XCTAssertEqual(cells[6].minX, 0)
        XCTAssertEqual(cells[6].width, 1200)
        XCTAssertEqual(cells[6].minY, 25 + 2 * rowH, accuracy: 0.001)
    }

    func testTwelveIsFourByThree() {
        let cells = gridLayout(count: 12, in: area)
        XCTAssertEqual(cells.count, 12)
        XCTAssertEqual(cells[0].width, 300)
        XCTAssertEqual(cells[0].height, 800.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(cells[11].maxX, 1200, accuracy: 0.001)
        XCTAssertEqual(cells[11].maxY, 825, accuracy: 0.001)
    }

    func testCellsDoNotOverlap() {
        for n in 1...16 {
            let cells = gridLayout(count: n, in: area)
            let covered = cells.reduce(0) { $0 + $1.width * $1.height }
            XCTAssertEqual(covered, area.width * area.height, accuracy: 0.01, "n=\(n) cells leave gaps")
            for i in 0..<cells.count {
                for j in (i + 1)..<cells.count {
                    XCTAssertFalse(cells[i].insetBy(dx: 0.01, dy: 0.01).intersects(cells[j]), "n=\(n) cells \(i),\(j) overlap")
                }
            }
        }
    }
}
