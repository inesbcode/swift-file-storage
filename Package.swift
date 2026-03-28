// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-file-storage",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
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
    targets: [
        .target(
            name: "FileStorage",
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
