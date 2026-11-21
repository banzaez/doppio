// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Doppio",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Doppio", targets: ["Doppio"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Doppio",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("UserNotifications")
            ]
        ),
        .testTarget(
            name: "DoppioTests",
            dependencies: ["Doppio"]
        ),
    ]
)
