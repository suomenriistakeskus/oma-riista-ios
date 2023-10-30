import Foundation
import RiistaCommon

extension ImageIdentifier {
    class func from(entityImage: EntityImage?) -> ImageIdentifier? {
        guard let entityImage = entityImage else { return nil }

        // currently ImageIdentifier is supported for local images only
        if (entityImage.status == .uploaded) {
            return nil
        }

        return ImageIdentifier.create(
            localIdentifier: entityImage.localIdentifier,
            imageUrl: entityImage.localUrl
        )
    }
}
