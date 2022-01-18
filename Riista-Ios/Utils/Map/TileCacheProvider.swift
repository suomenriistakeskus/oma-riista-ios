import Foundation
import Kingfisher

@objc class TileCacheProvider: NSObject {
    @objc static let shared = TileCacheProvider()

    @objc enum CacheType: Int {
        case mmlTiles
        case vectorTiles
    }

    private var caches: [CacheType : TileCache] = [:]

    @objc func getCache(type: CacheType) -> TileCache {
        if let cache = caches[type] {
            return cache
        } else {
            let cache = createCache(type: type)
            caches[type] = cache
            return cache
        }
    }

    func getMaxDiskCacheSizeInBytes(type: CacheType) -> UInt {
        switch type {
        case .mmlTiles:     return MemUtils.megaBytesToBytes(megaBytes: 128)
        case .vectorTiles:  return MemUtils.megaBytesToBytes(megaBytes: 128)
        }
    }

    func getDiskCacheUsage(type: CacheType, completion: @escaping (_ bytes: UInt?) -> Void) {
        let cache = getCache(type: type)
        cache.imageCache.calculateDiskStorageSize { cacheResult in
            switch cacheResult {
            case .success(let bytes):
                completion(bytes)
                break
            case .failure(_):
                completion(nil)
                break
            }
        }
    }

    func clearDiskCache(type: CacheType, completion: @escaping () -> Void) {
        let cache = getCache(type: type)
        cache.clear(completion: completion)
    }

    private func createCache(type: CacheType) -> TileCache {
        switch type {
        case .mmlTiles:
            let cache = TileCache(name: "MMLTiles")
            cache.imageCache.diskStorage.config.sizeLimit = getMaxDiskCacheSizeInBytes(type: type)
            cache.imageCache.diskStorage.config.expiration = .days(31)
            return cache
        case .vectorTiles:
            let cache = TileCache(name: "VectorTiles")
            cache.imageCache.diskStorage.config.sizeLimit = getMaxDiskCacheSizeInBytes(type: type)
            cache.imageCache.diskStorage.config.expiration = .days(14)
            return cache
        }
    }
}
