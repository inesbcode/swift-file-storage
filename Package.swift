// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-file-storage",
    products: [
        .library(
            name: "swift-file-storage",
            targets: ["swift-file-storage"]
        ),
    ],
    targets: [
        .target(
            name: "swift-file-storage"
        ),
        .testTarget(
            name: "swift-file-storageTests",
            dependencies: ["swift-file-storage"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
