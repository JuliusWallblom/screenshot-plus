// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Preview+",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Preview+", targets: ["Preview+"])
    ],
    targets: [
        .executableTarget(
            name: "Preview+",
            path: "Sources/Greataxe",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "GreataxeTests",
            dependencies: ["Preview+"],
            path: "Tests/GreataxeTests"
        )
    ]
)
