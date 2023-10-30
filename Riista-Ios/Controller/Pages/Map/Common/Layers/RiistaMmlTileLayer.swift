import Foundation
import GoogleMaps
import RiistaCommon

fileprivate let RefererKey = "Referer"
fileprivate let RefererValue = "https://oma.riista.fi"
fileprivate let MmlTopographicTileUrlFormat = "http://kartta.riista.fi/tms/1.0.0/maasto_mobile/EPSG_3857/%u/%u/%u.png"
fileprivate let MmlAerialTileUrlFormat = "http://kartta.riista.fi/tms/1.0.0/orto_mobile/EPSG_3857/%u/%u/%u.png"
fileprivate let MmlBackgroundTileUrlFormat = "http://kartta.riista.fi/tms/1.0.0/tausta_mobile/EPSG_3857/%u/%u/%u.png"

fileprivate let tileHeight = 256
fileprivate let tileWidth = 256


@objc class RiistaMmlTileLayer: GMSTileLayer {
    @objc var urlFormat: String

    /**
     * A custom cache providing also disk cache. Allows displaying previously fetched tiles also when network
     * connection is not available.
     */
    let customCache: TileCache

    /**
     * Keep track of cache clear counts as that allows clearing GMSTileLayer caches after customCache is cleared.
     */
    private var cacheClearCount: Int

    override init() {
        urlFormat = MmlTopographicTileUrlFormat
        customCache = TileCacheProvider.shared.getCache(type: .mmlTiles)
        cacheClearCount = customCache.cacheClearCount

        super.init()

        setupTileSize()
    }

    @objc func setMapType(_ type: RiistaMapType) {
        let oldFormat = urlFormat

        if (type == MmlAerialMapType) {
            urlFormat = MmlAerialTileUrlFormat
        } else if (type == MmlBackgroundMapType) {
            urlFormat = MmlBackgroundTileUrlFormat
        } else {
            urlFormat = MmlTopographicTileUrlFormat
        }

        clearTileCacheIfNeeded(oldUrlFormat: oldFormat)
    }

    private func clearTileCacheIfNeeded(oldUrlFormat: String) {
        // is same tile layer being used for displaying tiles of other format?
        let formatChanged = oldUrlFormat != urlFormat
        let customCacheCleared = cacheClearCount != customCache.cacheClearCount

        if (formatChanged || customCacheCleared) {
            // we don't have to clear customCache since urlString is used as a key and
            // it is different based on urlFormat
            clearTileCache()
            cacheClearCount = customCache.cacheClearCount
        }
    }

    private func setupTileSize() {
        // see RiitaVectorTileLayer.swift for same implementation. Keep these in sync!

        let screenScale = Int(UIScreen.main.scale)

        // the default tileSize available on the server is 256x256. There's no point in rendering
        // in smaller size. Also prevent rendering tiles as too large as this would cause tiles to blur
        //
        // this setting can be used as "map zoom" i.e. to help make texts more readable.
        // - we could e.g. add a setting to UI ('easy to read map on/off') and we could add e.g. 128
        //   to the extraZoom based on that value

        // not really zoom but helps keeping current tile zoom level bit further when zooming in.
        // This prevents displaying next zoom levels before their texts become readable
        let extraZoom = 128
        let tileHeight = min(max(128 * screenScale, 256) + extraZoom, 512)
        self.tileSize = tileHeight
    }

    @objc func getTileUrlString(x: UInt, y: UInt, zoom: UInt) -> String {
        return String(format: urlFormat, zoom, x, tmsConvert(y: y, zoom: zoom))
    }

    private func tmsConvert(y: UInt, zoom: UInt) -> Int {
        return Int((1 << zoom)) - Int(y) - 1
    }

    override func requestTileFor(x: UInt, y: UInt, zoom: UInt, receiver: GMSTileReceiver) {
        let urlString = getTileUrlString(x: x, y: y, zoom: zoom)

        customCache.retrieveTile(tileUrl: urlString) { [weak self] image in
            guard let self = self else {
                // tile layer probably discarded and no longer used
                // -> don't notify receiver in order to not mess anything (user may have e.g. switched
                //    to another tile layer and we don't want to display these tiles any more)
                return
            }

            if let image = image {
                receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: image)
            } else {
                self.fetchTileFromNetwork(x: x, y: y, zoom: zoom, urlString: urlString, receiver: receiver)
            }
        }
    }

    private func fetchTileFromNetwork(x: UInt, y: UInt, zoom: UInt, urlString: String, receiver: GMSTileReceiver) {
        let url = URL(string: urlString)!

        // store urlFormat before fetching. This way we can detect whether it was changed
        // while we were fetching tiles and prevent passing tiles with wrong format to receiver
        let urlFormatBeforeFetch = self.urlFormat

        // we have a local disk and memory caches for tiles and thus network cache
        // should only be used if there is no newer tile
        var request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)
        request.addValue(RefererValue, forHTTPHeaderField: RefererKey)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                // tile layer probably discarded and no longer used
                // -> don't notify receiver in order to not mess anything (user may have e.g. switched
                //    to another tile layer and we don't want to display these tiles any more)
                return
            }

            if let data = data, let image = UIImage(data: data) {
                // it is safe to store the image to cache even though url format may have changed
                // - this way we can use the tile later if urlFormat is set back to original value
                self.customCache.storeTile(tileUrl: urlString, tile: image, tileData: data)

                if (self.urlFormat == urlFormatBeforeFetch) {
                    receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: image)
                } else {
                    // url format was changed while fetching
                    // -> don't use this tile and instead launch the fetch process from the beginning
                    self.requestTileFor(x: x, y: y, zoom: zoom, receiver: receiver)
                }
            } else {
                // try again later
                receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: nil)
            }
        }.resume()
    }
}
