import Testing
import Foundation
@testable import FileStorage

@Suite("FileStorage", .serialized)
struct FileStorageTests {

    let storage: FileStorage

    init() throws {
        storage = FileStorage()
        try storage.clean()
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

    @Test("store preserves all files independently")
    func storePreservesMultipleFiles() throws {
        let data1 = Data("first".utf8)
        let data2 = Data("second".utf8)
        let id1 = try storage.store(data1)
        let id2 = try storage.store(data2)
        #expect(try storage.fetch(identifier: id1) == data1)
        #expect(try storage.fetch(identifier: id2) == data2)
    }

    @Test("store handles empty data")
    func storeHandlesEmptyData() throws {
        let identifier = try storage.store(Data())
        let result = try storage.fetch(identifier: identifier)
        #expect(result.isEmpty)
    }

    // MARK: - fetch

    @Test("fetch returns the same data that was stored")
    func fetchReturnsStoredData() throws {
        let data = Data("hello".utf8)
        let identifier = try storage.store(data)
        #expect(try storage.fetch(identifier: identifier) == data)
    }

    @Test("fetch reads correct data from disk on cache miss")
    func fetchReadsFromDisk() throws {
        let data = Data("persistent".utf8)
        let identifier = try storage.store(data)

        // Fresh instance → empty memory cache → must read from disk.
        let reader = FileStorage()
        #expect(try reader.fetch(identifier: identifier) == data)
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

    @Test("delete does not affect other stored files")
    func deleteDoesNotAffectOtherFiles() throws {
        let data1 = Data("keep".utf8)
        let id1 = try storage.store(data1)
        let id2 = try storage.store(Data("remove".utf8))
        try storage.delete(identifier: id2)
        #expect(try storage.fetch(identifier: id1) == data1)
    }

    @Test("delete is idempotent for unknown identifier")
    func deleteUnknownIdentifierDoesNotThrow() throws {
        try storage.delete(identifier: "unknown")
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

    @Test("clean allows subsequent stores and fetches")
    func cleanThenStore() throws {
        try storage.store(Data("pre".utf8))
        try storage.clean()

        let data = Data("post".utf8)
        let identifier = try storage.store(data)
        #expect(try storage.fetch(identifier: identifier) == data)
    }
}
