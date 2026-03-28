# FileStorage

Disk-backed file storage for Apple platforms, designed to complement SwiftData.

SwiftData is a great fit for structured data, but storing large blobs (images, documents, audio) directly in the database degrades performance. `FileStorage` solves this by writing files to the app's Documents directory and returning a stable string identifier that you persist in SwiftData instead of the file itself.

## Requirements

| Platform | Minimum version |
|----------|----------------|
| iOS      | 15             |
| macOS    | 12             |
| watchOS  | 8              |
| tvOS     | 15             |
| visionOS | 1              |

Swift 6 · Swift Package Manager

## Installation

### Xcode

**File → Add Package Dependencies…**, paste the repository URL, then add `FileStorage` to your app target. If you need the mock, add `FileStorageMocks` to your test or preview target as well.

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/inesbcode/swift-file-storage.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "FileStorage", package: "swift-file-storage"),
        ]
    ),
    .testTarget(
        name: "MyAppTests",
        dependencies: [
            .product(name: "FileStorageMocks", package: "swift-file-storage"),
        ]
    ),
]
```

## Usage

### Storing a file

```swift
import FileStorage

let storage = FileStorage()

// Store an image picked by the user
let identifier = try storage.store(imageData)

// Persist only the identifier in SwiftData, not the data itself
photo.imageIdentifier = identifier
```

### Fetching a file

```swift
let data = try storage.fetch(identifier: photo.imageIdentifier)
let image = UIImage(data: data)
```

### Deleting a file

```swift
try storage.delete(identifier: photo.imageIdentifier)
```

### Clearing all files

```swift
try storage.clean()
```

## Configuration

### Custom subdirectory

Files are stored under `Documents/FileStorage/` by default. Pass a `subdirectory` to isolate storage by feature or entity:

```swift
let storage = FileStorage(subdirectory: "Avatars")
```

### NSCache presets

`FileStorage` keeps recently accessed files in an `NSCache` to avoid redundant disk reads. Three presets are available:

| Preset | Max files | Max memory |
|--------|-----------|------------|
| `.small` | 50 | 25 MB |
| `.medium` *(default)* | 100 | 50 MB |
| `.large` | 200 | 100 MB |

```swift
let storage = FileStorage(fileCache: .large)
```

## Testing with Mocks

The `FileStorageMocks` library provides `MockFileStorage`, an in-memory implementation of `FileStorageProtocol` with no disk I/O, configurable stub errors, and per-method call counters.

```swift
import FileStorageMocks

let mock = MockFileStorage()

// Use it anywhere FileStorageProtocol is expected
let id = try mock.store(Data("hello".utf8))
assert(mock.storeCallCount == 1)

// Simulate an error
mock.fetchStub = .fileNotFound("test-id")
// try mock.fetch(identifier: "test-id") now throws .fileNotFound
```

`FileStorageMocks` is a separate library so it is never accidentally linked into a production build.

## License

MIT — see [LICENSE](LICENSE).
