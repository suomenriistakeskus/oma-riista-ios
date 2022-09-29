import Foundation
import Kingfisher


@objc class TileCache: NSObject {

    /**
     * The actual cache. Customize the cache after TileCache has been created
     */
    private(set) var imageCache: ImageCache

    /**
     * How many times this cache has been cleared.
     */
    private(set) var cacheClearCount: Int = 0

    init(name: String) {
        imageCache = ImageCache(name: name)
    }

    @objc func storeTile(tileUrl: String, tile: UIImage, tileData: Data, keyDiscriminator: String? = nil) {
        let key = getCacheKey(tileUrl: tileUrl, keyDiscriminator: keyDiscriminator)
        imageCache.store(tile, original: tileData, forKey: key)
    }

    @objc func retrieveTile(tileUrl: String, keyDiscriminator: String? = nil, completion: @escaping (UIImage?) -> Void) {
        let key = getCacheKey(tileUrl: tileUrl, keyDiscriminator: keyDiscriminator)
        if (!imageCache.isCached(forKey: key)) {
            completion(nil)
            return
        }

        imageCache.retrieveImage(
            forKey: key,
            // keep original expiration date. This ensures that tiles are
            // eventually reloaded from the network.
            options: [.diskCacheAccessExtendingExpiration(.none)]
        ) { retrieveResult in
            switch retrieveResult {
            case .success(let cacheResult):
                completion(cacheResult.image)
                break
            case .failure(_):
                completion(nil)
                break
            }
        }
    }

    /**
     * Clears the cache.
     *
     * Will increase the cache clear count.
     */
    func clear(completion: @escaping () -> Void) {
        imageCache.clearCache {
            // use strong self intentionally
            self.imageCache.cleanExpiredCache {
                self.cacheClearCount += 1
                completion()
            }
        }
    }

    private func getCacheKey(tileUrl: String, keyDiscriminator: String?) -> String {
        tileUrl + (keyDiscriminator ?? "")
    }
}
