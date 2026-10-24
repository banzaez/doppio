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
    targets: [
        .executableTarget(
            name: "Doppio",
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
