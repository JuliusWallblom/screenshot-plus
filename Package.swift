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
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/AppIcon.icns"),
                .copy("Resources/AppIcon.png"),
                .copy("Resources/AppIcon.iconset")
            ]
        ),
        .testTarget(
            name: "ScreenshotPlusTests",
            dependencies: ["Screenshot+"],
            path: "Tests/ScreenshotPlusTests"
        )
    ]
)
