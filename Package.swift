// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusicStreamMatcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MusicStreamMatcher",
            targets: ["MusicStreamMatcher"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MusicStreamMatcher",
            dependencies: [],
            path: "Sources"
        )
    ]
)