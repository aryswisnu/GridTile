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

    func testThreeIsThreeColumns() {
        let cells = gridLayout(count: 3, in: area)
        XCTAssertEqual(cells, [
            CGRect(x: 0, y: 25, width: 400, height: 800),
            CGRect(x: 400, y: 25, width: 400, height: 800),
            CGRect(x: 800, y: 25, width: 400, height: 800),
        ])
    }

    func testFiveIsThreeOverTwo() {
        let cells = gridLayout(count: 5, in: area)
        XCTAssertEqual(cells.count, 5)
        XCTAssertEqual(cells[0], CGRect(x: 0, y: 25, width: 400, height: 400))
        XCTAssertEqual(cells[3], CGRect(x: 0, y: 425, width: 600, height: 400))
        XCTAssertEqual(cells[4], CGRect(x: 600, y: 425, width: 600, height: 400))
    }

    func testSevenIsFourOverThree() {
        let cells = gridLayout(count: 7, in: area)
        XCTAssertEqual(cells.count, 7)
        XCTAssertEqual(cells[0], CGRect(x: 0, y: 25, width: 300, height: 400))
        XCTAssertEqual(cells[3], CGRect(x: 900, y: 25, width: 300, height: 400))
        XCTAssertEqual(cells[4].width, 400)
        XCTAssertEqual(cells[6], CGRect(x: 800, y: 425, width: 400, height: 400))
    }

    func testRealDisplaysGiveExpectedShapes() {
        // 16:9 minus menu bar, 16:10 MacBook minus menu bar
        for area in [CGRect(x: 0, y: 30, width: 1920, height: 975), CGRect(x: 0, y: 30, width: 1728, height: 1050)] {
            func shape(_ n: Int) -> [Int] {
                let cells = gridLayout(count: n, in: area)
                var rows: [CGFloat: Int] = [:]
                cells.forEach { rows[$0.minY, default: 0] += 1 }
                return rows.keys.sorted().map { rows[$0]! }
            }
            XCTAssertEqual(shape(2), [2], "\(area)")
            XCTAssertEqual(shape(3), [3], "\(area)")
            XCTAssertEqual(shape(4), [2, 2], "\(area)")
            XCTAssertEqual(shape(5), [3, 2], "\(area)")
            XCTAssertEqual(shape(6), [3, 3], "\(area)")
            XCTAssertEqual(shape(7), [4, 3], "\(area)")
            XCTAssertEqual(shape(8), [4, 4], "\(area)")
            XCTAssertEqual(shape(9), [5, 4], "\(area)")
            XCTAssertEqual(shape(12), [4, 4, 4], "\(area)")
        }
    }

    func testPortraitAreaStacksRows() {
        let portrait = CGRect(x: 0, y: 0, width: 800, height: 1200)
        let cells = gridLayout(count: 2, in: portrait)
        XCTAssertEqual(cells, [
            CGRect(x: 0, y: 0, width: 800, height: 600),
            CGRect(x: 0, y: 600, width: 800, height: 600),
        ])
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
