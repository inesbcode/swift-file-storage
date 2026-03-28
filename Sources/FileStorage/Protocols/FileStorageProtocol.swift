import Foundation

/// Defines the interface for an in-memory-cached, disk-backed file storage.
///
/// Typical SwiftData integration:
/// ```swift
/// let identifier = try storage.store(imageData)
/// photo.imageIdentifier = identifier  // persist only the identifier in SwiftData
///
/// // Retrieve later:
/// let data = try storage.fetch(identifier: photo.imageIdentifier)
/// ```
public protocol FileStorageProtocol: Sendable {

    /// Persists `data` to disk, caches it in memory, and returns a stable identifier.
    ///
    /// - Parameter data: The binary data to store.
    /// - Returns: A unique identifier suitable for storage in SwiftData.
    /// - Throws: `FileStorageError.storeFailure` if the file cannot be written to disk.
    @discardableResult
    nonisolated func store(_ data: Data) throws(FileStorageError) -> String

    /// Returns data for `identifier`, reading from the memory cache before hitting disk.
    ///
    /// - Parameter identifier: The identifier previously returned by `store`.
    /// - Returns: The binary data associated with `identifier`.
    /// - Throws: `FileStorageError.fileNotFound` if no file exists for `identifier`;
    ///   `FileStorageError.fetchFailure` if the file cannot be read from disk.
    nonisolated func fetch(identifier: String) throws(FileStorageError) -> Data

    /// Removes the file and its memory-cache entry for `identifier`.
    ///
    /// Silently succeeds if no file exists for `identifier`.
    /// - Parameter identifier: The identifier previously returned by `store`.
    /// - Throws: `FileStorageError.deleteFailure` if the file cannot be removed from disk.
    nonisolated func delete(identifier: String) throws(FileStorageError)

    /// Evicts all memory-cache entries and deletes every managed file on disk.
    ///
    /// Silently succeeds if the storage directory does not exist yet.
    /// - Throws: `FileStorageError.cleanFailure` if the directory contents cannot be removed.
    nonisolated func clean() throws(FileStorageError)
}
