// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Screenshot+",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Screenshot+", targets: ["Screenshot+"])
    ],
    targets: [
        .executableTarget(
            name: "Screenshot+",
            path: "Sources/ScreenshotPlus",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "GreataxeTests",
            dependencies: ["Screenshot+"],
            path: "Tests/GreataxeTests"
        )
    ]
)
