# swift-file-storage

Disk-backed file storage for Apple platforms, designed to complement SwiftData.
SwiftData is not suited for large blobs: this package saves files to the Documents
directory and returns a stable string identifier to store in SwiftData instead.

## How it works

`FileStorage.store(_:)` generates a UUID, writes the file atomically to
`Documents/<subdirectory>/`, caches it in an `NSCache`, and returns the identifier.
`fetch`, `delete`, and `clean` use the same identifier as the key.

## Swift 6 notes

- `swiftSettings` includes `.defaultIsolation(MainActor.self)`, so every
  declaration in the target is implicitly `@MainActor` unless marked otherwise.
- All public methods are `nonisolated` — they can be called from any isolation
  context without `await`.
- `FileManager` and `NSCache` are not `Sendable`, so their stored properties use
  `nonisolated(unsafe)`. Both types are documented as thread-safe by Apple.

## Commands

```bash
swift build
swift test

# Format (uses Xcode-bundled swift-format via active toolchain)
xcrun swift-format format --in-place --recursive --configuration swift-format.json Sources/ Tests/
```
