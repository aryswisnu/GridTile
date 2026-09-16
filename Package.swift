// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GridTile",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "GridTileCore"),
        .executableTarget(name: "GridTile", dependencies: ["GridTileCore"]),
        .testTarget(name: "GridTileCoreTests", dependencies: ["GridTileCore"]),
    ]
)
