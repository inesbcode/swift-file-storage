import Foundation

extension NSCache where KeyType == NSString, ObjectType == NSData {

    /// Up to 50 files, max 25 MB in memory.
    public nonisolated static var small: NSCache<NSString, NSData> {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 50
        cache.totalCostLimit = 25 * 1024 * 1024
        return cache
    }

    /// Up to 100 files, max 50 MB in memory.
    ///
    /// This is the default configuration.
    public nonisolated static var medium: NSCache<NSString, NSData> {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }

    /// Up to 200 files, max 100 MB in memory.
    public nonisolated static var large: NSCache<NSString, NSData> {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024
        return cache
    }
}
