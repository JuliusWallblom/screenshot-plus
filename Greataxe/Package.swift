// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Greataxe",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Greataxe", targets: ["Greataxe"])
    ],
    targets: [
        .executableTarget(
            name: "Greataxe",
            path: "Sources/Greataxe"
        ),
        .testTarget(
            name: "GreataxeTests",
            dependencies: ["Greataxe"],
            path: "Tests/GreataxeTests"
        )
    ]
)
