// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-file-storage",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "FileStorage",
            targets: ["FileStorage"]
        ),
        .library(
            name: "FileStorageMocks",
            targets: ["FileStorageMocks"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/inesbcode/swift-logging", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "FileStorage",
            dependencies: [
                .product(name: "Logging", package: "swift-logging"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .target(
            name: "FileStorageMocks",
            dependencies: ["FileStorage"],
            path: "Mocks/FileStorageMocks",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .testTarget(
            name: "FileStorageTests",
            dependencies: ["FileStorage"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
        .v5,
    ]
)
