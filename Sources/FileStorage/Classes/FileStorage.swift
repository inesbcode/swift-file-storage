import Foundation
import Logging

/// Thread-safe, disk-backed file storage with an inline `NSCache` for in-memory caching.
///
/// Files are persisted in the app's Documents directory under a dedicated subdirectory.
/// The subdirectory is created on demand the first time `store` is called.
/// Every `store` call writes to disk atomically and populates the memory cache.
/// Every `fetch` checks the cache first, falling back to a directory scan on a miss.
///
/// All public operations are `nonisolated` and delegate thread-safety to
/// `NSCache` (cache reads/writes) and atomic file I/O (disk operations).
public final class FileStorage: FileStorageProtocol, @unchecked Sendable {

    /// The directory on disk where files managed by this instance reside.
    private let storageURL: URL

    // FileManager and NSCache are thread-safe but not Sendable; nonisolated(unsafe)
    // opts their properties out of @MainActor isolation so nonisolated methods can
    // access them directly.
    nonisolated(unsafe) private let fileManager: FileManager
    nonisolated(unsafe) private let fileCache: NSCache<NSString, NSData>

    // MARK: - Initialiser

    /// Creates a `FileStorage` instance backed by the app's Documents directory.
    ///
    /// Sets `Logging.subsystem` to `"com.inesb.swift-file-storage"` so all log events
    /// from this package are identifiable in Console.app and `log stream`.
    /// - Parameters:
    ///   - subdirectory: Folder name appended to the Documents directory. Defaults to `"FileStorage"`.
    ///   - fileManager: The `FileManager` used for all disk operations. Defaults to `.default`.
    ///   - fileCache: The `NSCache` instance used for in-memory caching. Defaults to `.medium`.
    public nonisolated init(
        subdirectory: String = "FileStorage",
        fileManager: FileManager = .default,
        fileCache: NSCache<NSString, NSData> = .medium
    ) {
        Logging.subsystem = "com.inesb.swift-file-storage"
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.storageURL = documents.appendingPathComponent(subdirectory, isDirectory: true)
        self.fileManager = fileManager
        self.fileCache = fileCache
    }

    // MARK: - FileStorageProtocol

    /// Generates a UUID, writes `data` atomically to disk, caches it, and returns the identifier.
    ///
    /// The storage subdirectory is created lazily on the first call.
    /// - Parameter data: The binary data to store.
    /// - Returns: A UUID string identifying the stored file, suitable for persistence in SwiftData.
    /// - Throws: `FileStorageError.storeFailure` wrapping any underlying file-system error.
    @discardableResult
    public nonisolated func store(_ data: Data) throws(FileStorageError) -> String {
        Logging.data.debug("Storing \(data.count, privacy: .public) bytes")
        do {
            let identifier = UUID().uuidString
            let fileURL = storageURL.appendingPathComponent(identifier)
            try fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
            fileCache.setObject(data as NSData, forKey: identifier as NSString, cost: data.count)
            Logging.data.notice(
                "Stored \(data.count, privacy: .public) bytes with identifier \(identifier, privacy: .public)"
            )
            return identifier
        } catch {
            Logging.data.error("Store failed: \(error.localizedDescription, privacy: .public)")
            throw FileStorageError.storeFailure(error.localizedDescription)
        }
    }

    /// Returns data for `identifier`, reading from the memory cache before hitting disk.
    ///
    /// On a cache hit the result is returned immediately. On a miss the file is located
    /// via a directory scan, loaded, and inserted into the cache for subsequent calls.
    /// - Parameter identifier: The identifier previously returned by `store`.
    /// - Returns: The binary data associated with `identifier`.
    /// - Throws: `FileStorageError.fileNotFound` if no file exists for `identifier`;
    ///   `FileStorageError.fetchFailure` if the file cannot be read from disk.
    public nonisolated func fetch(identifier: String) throws(FileStorageError) -> Data {
        if let cached = fileCache.object(forKey: identifier as NSString) as? Data {
            Logging.cache.debug("Cache hit for \(identifier, privacy: .public)")
            return cached
        }
        Logging.cache.debug("Cache miss for \(identifier, privacy: .public) — reading from disk")
        do {
            let url = try url(for: identifier)
            let data = try Data(contentsOf: url)
            fileCache.setObject(data as NSData, forKey: identifier as NSString, cost: data.count)
            Logging.data.debug(
                "Fetched \(data.count, privacy: .public) bytes for \(identifier, privacy: .public)"
            )
            return data
        } catch let error as FileStorageError {
            Logging.data.error(
                "Fetch failed for \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw error
        } catch {
            Logging.data.error(
                "Fetch failed for \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw FileStorageError.fetchFailure(error.localizedDescription)
        }
    }

    /// Removes the file and its memory-cache entry for `identifier`.
    ///
    /// Silently succeeds if no file exists for `identifier`.
    /// - Parameter identifier: The identifier previously returned by `store`.
    /// - Throws: `FileStorageError.deleteFailure` if the file cannot be removed from disk.
    public nonisolated func delete(identifier: String) throws(FileStorageError) {
        Logging.data.debug("Deleting \(identifier, privacy: .public)")
        fileCache.removeObject(forKey: identifier as NSString)
        do {
            let matches = try files(for: identifier)
            for url in matches {
                try fileManager.removeItem(at: url)
            }
            Logging.data.notice("Deleted \(identifier, privacy: .public)")
        } catch let error as FileStorageError {
            Logging.data.error(
                "Delete failed for \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw error
        } catch {
            Logging.data.error(
                "Delete failed for \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw FileStorageError.deleteFailure(error.localizedDescription)
        }
    }

    /// Evicts all memory-cache entries and deletes every managed file on disk.
    ///
    /// Silently succeeds if the storage directory does not exist yet.
    /// - Throws: `FileStorageError.cleanFailure` if the directory contents cannot be removed.
    public nonisolated func clean() throws(FileStorageError) {
        Logging.data.debug("Cleaning storage at \(self.storageURL.path, privacy: .public)")
        fileCache.removeAllObjects()
        guard fileManager.fileExists(atPath: storageURL.path) else {
            Logging.data.debug("Storage directory does not exist — nothing to clean")
            return
        }
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: storageURL,
                includingPropertiesForKeys: nil
            )
            for url in contents {
                try fileManager.removeItem(at: url)
            }
            Logging.data.notice("Cleaned \(contents.count, privacy: .public) file(s) from storage")
        } catch {
            Logging.data.error("Clean failed: \(error.localizedDescription, privacy: .public)")
            throw FileStorageError.cleanFailure(error.localizedDescription)
        }
    }

    // MARK: - Private helpers

    /// Returns the on-disk URL for `identifier`, scanning the storage directory.
    ///
    /// - Parameter identifier: The identifier to look up.
    /// - Returns: The URL of the matching file.
    /// - Throws: `FileStorageError.fileNotFound` if no matching file exists;
    ///   `FileStorageError.fetchFailure` if the directory cannot be read.
    private nonisolated func url(for identifier: String) throws(FileStorageError) -> URL {
        do {
            let matches = try files(for: identifier)
            guard let url = matches.first else {
                throw FileStorageError.fileNotFound(identifier)
            }
            return url
        } catch let error as FileStorageError {
            throw error
        } catch {
            throw FileStorageError.fetchFailure(error.localizedDescription)
        }
    }

    /// Returns all URLs in the storage directory whose name (without extension) matches `identifier`.
    ///
    /// Returns an empty array if the storage directory does not exist yet.
    /// - Parameter identifier: The identifier to match against file names.
    /// - Returns: Matching file URLs, or `[]` if the directory is absent.
    /// - Throws: Any error thrown by `FileManager.contentsOfDirectory`.
    private nonisolated func files(for identifier: String) throws -> [URL] {
        guard fileManager.fileExists(atPath: storageURL.path) else { return [] }
        let contents = try fileManager.contentsOfDirectory(
            at: storageURL,
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.deletingPathExtension().lastPathComponent == identifier }
    }
}
