# swift-file-storage

Disk-backed file storage for Apple platforms, designed to complement SwiftData.
SwiftData is not suited for large blobs: this package saves files to the Documents
directory and returns a stable string identifier to store in SwiftData instead.

## Project structure

```
Sources/   – production code (FileStorage target)
Mocks/     – mock implementations (FileStorageMocks target)
Tests/     – unit tests (FileStorageTests target)
```

`FileStorageMocks` is intentionally kept outside `Sources/` to make clear it is
not production code. SPM resolves it via an explicit `path: "Mocks/FileStorageMocks"`
in `Package.swift`. Add `FileStorageMocks` as a dependency only in test targets or
Xcode Preview targets — never in a production app target.

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

## Documentation

All public declarations must have a doc comment (`///`). Protocol methods must
include `- Parameter`, `- Returns` (if non-Void), and `- Throws` (if throwing)
sections. Concrete implementations repeat the same sections so the docs are
visible directly on the type without navigating to the protocol.

## Error handling

All throwing functions must use typed throws. The error type is always
`FileStorageError`:

```swift
func store(_ data: Data) throws(FileStorageError) -> String
```

Private helpers that call framework APIs (e.g. `FileManager`) may use untyped
`throws` internally, but must re-throw as `FileStorageError` before surfacing
to callers.

## Commands

```bash
swift build
swift test

# Format (uses Xcode-bundled swift-format via active toolchain)
xcrun swift-format format --in-place --recursive --configuration swift-format.json Sources/ Tests/
```
