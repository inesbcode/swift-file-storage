import Foundation
import FileStorage

/// An in-memory, thread-safe mock of `FileStorageProtocol` for use in tests and Xcode Previews.
///
/// `MockFileStorage` stores data in a dictionary rather than on disk. It records every
/// call made to it and lets you inject a per-operation stub error so you can exercise
/// error paths without touching the file system.
///
/// ## Usage
/// ```swift
/// let mock = MockFileStorage()
///
/// // Happy path
/// let id = try mock.store(imageData)
/// let data = try mock.fetch(identifier: id)
///
/// // Error path
/// mock.fetchStub = .fileNotFound("test-id")
/// #expect { try mock.fetch(identifier: "test-id") } throws: { $0 is FileStorageError }
///
/// // Call tracking
/// #expect(mock.storeCallCount == 1)
/// ```
public final class MockFileStorage: FileStorageProtocol, @unchecked Sendable {

    private let lock = NSLock()
    nonisolated(unsafe) private var storedFiles: [String: Data] = [:]

    // MARK: - Stubs

    /// When set, `store` throws this error instead of persisting the data.
    nonisolated(unsafe) public var storeStub: FileStorageError?

    /// When set, `fetch` throws this error instead of returning the stored data.
    nonisolated(unsafe) public var fetchStub: FileStorageError?

    /// When set, `delete` throws this error instead of removing the entry.
    nonisolated(unsafe) public var deleteStub: FileStorageError?

    /// When set, `clean` throws this error instead of wiping all entries.
    nonisolated(unsafe) public var cleanStub: FileStorageError?

    // MARK: - Call counters

    /// Number of times `store` has been called.
    nonisolated(unsafe) public private(set) var storeCallCount: Int = 0

    /// Number of times `fetch` has been called.
    nonisolated(unsafe) public private(set) var fetchCallCount: Int = 0

    /// Number of times `delete` has been called.
    nonisolated(unsafe) public private(set) var deleteCallCount: Int = 0

    /// Number of times `clean` has been called.
    nonisolated(unsafe) public private(set) var cleanCallCount: Int = 0

    // MARK: - Initialiser

    /// Creates an empty `MockFileStorage` with no stubs and zero call counts.
    public nonisolated init() {}

    // MARK: - FileStorageProtocol

    /// Stores `data` in memory and returns a UUID identifier.
    ///
    /// Increments `storeCallCount` on every call. If `storeStub` is set,
    /// the error is thrown and no data is stored.
    /// - Parameter data: The binary data to store.
    /// - Returns: A UUID string identifying the stored entry.
    /// - Throws: `storeStub` if set; otherwise never throws.
    @discardableResult
    public nonisolated func store(_ data: Data) throws(FileStorageError) -> String {
        lock.lock()
        defer { lock.unlock() }
        storeCallCount += 1
        if let error = storeStub { throw error }
        let identifier = UUID().uuidString
        storedFiles[identifier] = data
        return identifier
    }

    /// Returns the in-memory data associated with `identifier`.
    ///
    /// Increments `fetchCallCount` on every call. If `fetchStub` is set,
    /// the error is thrown regardless of whether the identifier exists.
    /// - Parameter identifier: The identifier previously returned by `store`.
    /// - Returns: The binary data associated with `identifier`.
    /// - Throws: `fetchStub` if set; `FileStorageError.fileNotFound` if the
    ///   identifier is not present in the in-memory store.
    public nonisolated func fetch(identifier: String) throws(FileStorageError) -> Data {
        lock.lock()
        defer { lock.unlock() }
        fetchCallCount += 1
        if let error = fetchStub { throw error }
        guard let data = storedFiles[identifier] else {
            throw FileStorageError.fileNotFound(identifier)
        }
        return data
    }

    /// Removes the in-memory entry for `identifier`.
    ///
    /// Increments `deleteCallCount` on every call. Silently succeeds if the
    /// identifier is not present. If `deleteStub` is set, the error is thrown
    /// and no entry is removed.
    /// - Parameter identifier: The identifier previously returned by `store`.
    /// - Throws: `deleteStub` if set; otherwise never throws.
    public nonisolated func delete(identifier: String) throws(FileStorageError) {
        lock.lock()
        defer { lock.unlock() }
        deleteCallCount += 1
        if let error = deleteStub { throw error }
        storedFiles.removeValue(forKey: identifier)
    }

    /// Removes all in-memory entries.
    ///
    /// Increments `cleanCallCount` on every call. If `cleanStub` is set,
    /// the error is thrown and no entries are removed.
    /// - Throws: `cleanStub` if set; otherwise never throws.
    public nonisolated func clean() throws(FileStorageError) {
        lock.lock()
        defer { lock.unlock() }
        cleanCallCount += 1
        if let error = cleanStub { throw error }
        storedFiles.removeAll()
    }
}
