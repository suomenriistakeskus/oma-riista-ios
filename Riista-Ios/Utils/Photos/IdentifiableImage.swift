import Foundation

/**
 * Wraps the image (UIImage) and required identifier
 */
@objc public class IdentifiableImage: NSObject {
    @objc let imageIdentifier: ImageIdentifier
    @objc let image: UIImage

    init(_ image: UIImage, imageIdentifier: ImageIdentifier) {
        self.imageIdentifier = imageIdentifier
        self.image = image
    }
}
