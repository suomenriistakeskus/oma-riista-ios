import Foundation
import RiistaCommon

extension ImageIdentifier {
    @objc class func from(diaryImage: DiaryImage?) -> ImageIdentifier? {
        guard let diaryImage = diaryImage else { return nil }
        guard let diaryImageType = diaryImage.type else { return nil }

        // currently ImageIdentifier is supported for local images only
        if (diaryImageType.intValue == DiaryImageTypeRemote) {
            return nil
        }

        return ImageIdentifier.create(localIdentifier: diaryImage.localIdentifier,
                                      imageUrl: diaryImage.uri)
    }

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

    @objc func saveIdentifier(to diaryImage: DiaryImage?) {
        guard let diaryImage = diaryImage else {
            // nothing to do
            print("Cannot update <nil> DiaryImage with ImageIdentifier information")
            return
        }

        diaryImage.uri = self.imageUrl?.absoluteString
        diaryImage.localIdentifier = self.localIdentifier
    }
}
