import Foundation

extension ImageLoadRequest {
    @objc class func from(diaryImage: DiaryImage?) -> ImageLoadRequest? {
        guard let imageIdentifier = ImageIdentifier.from(diaryImage: diaryImage) else { return nil }
        return ImageLoadRequest(imageIdentifier: imageIdentifier)
    }

    @objc class func from(diaryImage: DiaryImage?, options: ImageLoadOptions) -> ImageLoadRequest? {
        guard let imageIdentifier = ImageIdentifier.from(diaryImage: diaryImage) else { return nil }
        return ImageLoadRequest(imageIdentifier: imageIdentifier, options: options)
    }
}
