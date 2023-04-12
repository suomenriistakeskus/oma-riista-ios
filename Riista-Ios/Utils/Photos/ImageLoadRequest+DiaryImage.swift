import Foundation
import RiistaCommon

extension ImageLoadRequest {
    @objc class func from(diaryImage: DiaryImage?) -> ImageLoadRequest? {
        guard let imageIdentifier = ImageIdentifier.from(diaryImage: diaryImage) else { return nil }
        return ImageLoadRequest(imageIdentifier: imageIdentifier)
    }

    @objc class func from(diaryImage: DiaryImage?, options: ImageLoadOptions) -> ImageLoadRequest? {
        guard let imageIdentifier = ImageIdentifier.from(diaryImage: diaryImage) else { return nil }
        return ImageLoadRequest(imageIdentifier: imageIdentifier, options: options)
    }

    class func from(entityImage: EntityImage?) -> ImageLoadRequest? {
        from(entityImage: entityImage, options: ImageLoadOptions.default())
    }

    class func from(entityImage: EntityImage?, options: ImageLoadOptions) -> ImageLoadRequest? {
        guard let imageIdentifier = ImageIdentifier.from(entityImage: entityImage) else { return nil }
        return ImageLoadRequest(imageIdentifier: imageIdentifier, options: options)
    }
}
