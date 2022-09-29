import Foundation
import Kingfisher
import RiistaCommon



class PointOfInterestMarkerImageCache {

    static public let shared: PointOfInterestMarkerImageCache = {
        return PointOfInterestMarkerImageCache()
    }()

    /**
     * The marker view that will be rendered to an image.
     */
    private lazy var markerView: PointOfInterestMarkerView = PointOfInterestMarkerView()

    private lazy var markerImageCache: ImageCache = ImageCache(name: "point-of-interest-markers")

    func getOrRenderMarkerIcon(for pointOfInterest: PoiLocationViewModel, completion: @escaping (UIImage?) -> Void) {
        getOrRenderMarkerIcon(for: pointOfInterest.toMarkerData(), completion: completion)
    }

    func getOrRenderMarkerIcon(for pointOfInterest: PointOfInterest, completion: @escaping (UIImage?) -> Void) {
        getOrRenderMarkerIcon(for: pointOfInterest.toMarkerData(), completion: completion)
    }

    func getOrRenderMarkerIcon(for markerData: PointOfInterestMarkerView.MarkerData,
                               completion: @escaping (UIImage?) -> Void) {
        let retrieveOptions: KingfisherOptionsInfo = [
            // disk is probably not used but let's load synchronously if it is
            .loadDiskFileSynchronously
        ]

        markerImageCache.retrieveImage(
            forKey: markerData.identifier,
            options: retrieveOptions
        ) { [weak self] retrieveResult in
            let markerIcon: UIImage?

            switch retrieveResult {
            case .success(let cacheResult):
                markerIcon = cacheResult.image
            case .failure(_):
                markerIcon = nil
            }

            if let markerIcon = markerIcon {
                //print("PointOfInterestMarkerImageCache: retrieved the icon for marker \(markerData.identifier)")
                completion(markerIcon)
            } else if let self = self {
                self.createAndCacheMarkerIcon(for: markerData, completion: completion)
            } else {
                completion(nil)
            }
        }
    }

    private func createAndCacheMarkerIcon(for markerData: PointOfInterestMarkerView.MarkerData,
                                          completion: @escaping (UIImage?) -> Void) {
        if let icon = renderMarker(for: markerData) {
            //print("PointOfInterestMarkerImageCache: rendered icon for marker \(markerData.identifier)")

            // don't store to disk in order to allow changing colors etc in the future
            markerImageCache.store(icon, forKey: markerData.identifier, toDisk: false)
            completion(icon)
        } else {
            print("Failed to render Point-of-Interest into marker image.")
            completion(nil)
        }
    }

    private func renderMarker(for markerData: PointOfInterestMarkerView.MarkerData) -> UIImage? {
        markerView.configureValues(markerData: markerData)

        markerView.setNeedsLayout()
        markerView.layoutIfNeeded()

        return markerView.asImage()
    }
}


fileprivate extension UIView {
    // adjusted from PixelTest library:
    // https://github.com/KaneCheshire/PixelTest
    func asImage() -> UIImage? {
        let size = bounds.size
        if (size.width < 1 || size.height < 1) {
            print("Cannot render view as image (invalid size)")
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        context.saveGState()
        layer.render(in: context)
        context.restoreGState()

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        UIGraphicsEndImageContext()
        return image
    }
}
