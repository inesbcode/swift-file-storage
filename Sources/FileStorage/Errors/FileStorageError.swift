import Foundation

/// Errors thrown by `FileStorage` operations.
public enum FileStorageError: Error, Sendable {
    /// No file was found on disk for the given identifier.
    case fileNotFound(String)
    /// Writing data to disk failed. Contains the underlying error message.
    case storeFailure(String)
    /// Reading data from disk failed. Contains the underlying error message.
    case fetchFailure(String)
    /// Removing a file from disk failed. Contains the underlying error message.
    case deleteFailure(String)
    /// Clearing the storage directory failed. Contains the underlying error message.
    case cleanFailure(String)
}

extension FileStorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let id):
            return "No file found for identifier '\(id)'."
        case .storeFailure(let message):
            return "Store failed: \(message)"
        case .fetchFailure(let message):
            return "Fetch failed: \(message)"
        case .deleteFailure(let message):
            return "Delete failed: \(message)"
        case .cleanFailure(let message):
            return "Clean failed: \(message)"
        }
    }
}
