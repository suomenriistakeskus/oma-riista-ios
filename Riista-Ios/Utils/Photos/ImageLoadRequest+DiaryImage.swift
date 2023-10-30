import Foundation
import RiistaCommon

extension ImageLoadRequest {
    class func from(entityImage: EntityImage?) -> ImageLoadRequest? {
        from(entityImage: entityImage, options: ImageLoadOptions.default())
    }

    class func from(entityImage: EntityImage?, options: ImageLoadOptions) -> ImageLoadRequest? {
        guard let imageIdentifier = ImageIdentifier.from(entityImage: entityImage) else { return nil }
        return ImageLoadRequest(imageIdentifier: imageIdentifier, options: options)
    }
}
