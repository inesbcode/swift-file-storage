import Testing
import Foundation
@testable import FileStorage

@Suite("FileStorage")
struct FileStorageTests {

    /// Each test gets an isolated subdirectory so tests never interfere.
    let storage: FileStorage

    init() {
        storage = FileStorage(subdirectory: "FileStorageTests-\(UUID().uuidString)")
    }

    // MARK: - store

    @Test("store returns a non-empty identifier")
    func storeReturnsNonEmptyIdentifier() throws {
        let identifier = try storage.store(Data("hello".utf8))
        #expect(!identifier.isEmpty)
    }

    @Test("store returns a different identifier on each call")
    func storeReturnsUniqueIdentifiers() throws {
        let id1 = try storage.store(Data("a".utf8))
        let id2 = try storage.store(Data("b".utf8))
        #expect(id1 != id2)
    }

    @Test("store is discardable")
    func storeIsDiscardable() throws {
        // Calling store without using the returned identifier must compile without warnings.
        try storage.store(Data("discard".utf8))
    }

    // MARK: - fetch

    @Test("fetch returns the same data that was stored")
    func fetchReturnsStoredData() throws {
        let data = Data("cached".utf8)
        let identifier = try storage.store(data)
        let result = try storage.fetch(identifier: identifier)
        #expect(result == data)
    }

    @Test("fetch reads correct data from disk on cache miss")
    func fetchReadsFromDisk() throws {
        // Use a shared subdirectory so two separate instances point to the same files.
        let subdir = "FileStorageTests-disk-\(UUID().uuidString)"
        let writer = FileStorage(subdirectory: subdir)
        let data = Data("persistent".utf8)
        let identifier = try writer.store(data)

        // Fresh instance → empty memory cache → must read from disk.
        let reader = FileStorage(subdirectory: subdir)
        let result = try reader.fetch(identifier: identifier)
        #expect(result == data)

        try writer.clean()
    }

    @Test("fetch throws fileNotFound for unknown identifier")
    func fetchThrowsForUnknownIdentifier() {
        #expect {
            try self.storage.fetch(identifier: "ghost")
        } throws: { error in
            guard case FileStorageError.fileNotFound(let id) = error else { return false }
            return id == "ghost"
        }
    }

    // MARK: - delete

    @Test("delete removes file so fetch throws fileNotFound")
    func deleteRemovesFile() throws {
        let identifier = try storage.store(Data("bye".utf8))
        try storage.delete(identifier: identifier)

        #expect {
            try self.storage.fetch(identifier: identifier)
        } throws: { error in
            guard case FileStorageError.fileNotFound = error else { return false }
            return true
        }
    }

    @Test("delete is idempotent for unknown identifier")
    func deleteUnknownIdentifierDoesNotThrow() throws {
        try storage.delete(identifier: "unknown")
    }

    @Test("delete on storage with no directory does not throw")
    func deleteBeforeAnyStoreDoesNotThrow() throws {
        // storage directory has never been created (no store called yet)
        let fresh = FileStorage(subdirectory: "FileStorageTests-empty-\(UUID().uuidString)")
        try fresh.delete(identifier: "ghost")
    }

    // MARK: - clean

    @Test("clean removes all files so subsequent fetches throw")
    func cleanRemovesAllFiles() throws {
        let id1 = try storage.store(Data("a".utf8))
        try storage.store(Data("b".utf8))
        try storage.clean()

        #expect {
            try self.storage.fetch(identifier: id1)
        } throws: { error in
            error is FileStorageError
        }
    }

    @Test("clean on storage with no directory does not throw")
    func cleanBeforeAnyStoreDoesNotThrow() throws {
        let fresh = FileStorage(subdirectory: "FileStorageTests-empty-\(UUID().uuidString)")
        try fresh.clean()
    }

    @Test("clean allows subsequent stores and fetches")
    func cleanThenStore() throws {
        try storage.store(Data("pre".utf8))
        try storage.clean()

        let data = Data("post".utf8)
        let identifier = try storage.store(data)
        let result = try storage.fetch(identifier: identifier)
        #expect(result == data)
    }
}
