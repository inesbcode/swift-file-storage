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
    nonisolated func store(_ data: Data) throws -> String

    /// Returns data for `identifier`, reading from memory cache before hitting disk.
    nonisolated func fetch(identifier: String) throws -> Data

    /// Removes the file and its memory-cache entry for `identifier`.
    nonisolated func delete(identifier: String) throws

    /// Evicts all memory-cache entries and deletes every managed file on disk.
    nonisolated func clean() throws
}
