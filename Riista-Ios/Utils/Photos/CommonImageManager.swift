import Foundation
import RiistaCommon

class CommonImageManager {
    private lazy var logger: AppLogger = AppLogger(for: self, printTimeStamps: false)

    private let maxSavedImageSize: CGSize

    convenience init() {
        self.init(maxSavedImageSize: CGSize(width: AppConstants.MaxImageSizeDimen, height: AppConstants.MaxImageSizeDimen))
    }

    init(maxSavedImageSize: CGSize) {
        self.maxSavedImageSize = maxSavedImageSize
    }


    // MARK: Accessing images

    /**
     * Loads the image specified by `imageFileUuid`
     */
    func loadImage(imageFileUuid: String, _ onImageLoaded: (UIImage?) -> Void) {
        // probably .localImages would be enough but let's search also from .temporaryFiles
        // as that's the place where image is first expected to be saved
        let searchDirectories: [CommonFileProviderDirectory] = [.localImages, .temporaryFiles]
        logger.v { "Looking for entity image \(imageFileUuid) from \(searchDirectories)" }

        for searchDirectory in searchDirectories {
            guard let file = CommonFileStorage.shared.getFile(directory: searchDirectory, fileUuid: imageFileUuid) else {
                logger.v { "Couldn't find file from \(searchDirectory). Checking next one.." }
                continue
            }

            if (!file.exists()) {
                logger.v { "File didn't exist in \(searchDirectory). Checking next one.." }
                continue
            }

            logger.v { "File exists in \(searchDirectory).." }

            let fileUrl = URL(fileURLWithPath: file.path)
            if let fileData = try? Data(contentsOf: fileUrl), let image = UIImage(data: fileData) {
                logger.v { "Image read from file" }
                onImageLoaded(image)
                return
            } else {
                logger.v { "Failed to read image data from path" }
            }
        }

        logger.v { "Couldn't find file from listed search directories, reporting failure" }
        onImageLoaded(nil)
    }


    // MARK: Saving images

    func saveImageToTemporaryImages(identifiableImage: IdentifiableImage) -> EntityImage? {
        let fileServerUuid = UUID().uuidString // generate one

        guard let targetFilePath = CommonFileStorage.shared.getPathFor(directory: .temporaryFiles, fileUuid: fileServerUuid) else {
            logger.v { "Could not obtain target file path for the image" }
            return nil
        }
        guard let imageData = getResizedJpegImageData(originalImage: identifiableImage.image) else {
            logger.v { "Could not obtain target image data, cannot write to file" }
            return nil
        }

        let targetFileUrl = URL(fileURLWithPath: targetFilePath)

        do {
            try imageData.write(to: targetFileUrl, options: [.atomic])
        } catch {
            logger.v { "Failed to save file" }
            return nil
        }

        return EntityImage(
            serverId: fileServerUuid,
            localIdentifier: identifiableImage.imageIdentifier.localIdentifier,
            localUrl: identifiableImage.imageIdentifier.imageUrl?.absoluteString,
            status: .local
        )
    }

    func moveTemporaryImagesToLocalImages(images: [EntityImage], onCompleted: @escaping OnCompleted) {
        if (images.isEmpty) {
            logger.v { "No images to be moved." }
            onCompleted()
            return
        }

        images.foreachAsync(
            onAllCompleted: handleOnMainThread(onCompleted)
        ) { image, onImageMoved in
            moveTemporaryImageToLocalImages(image: image, onImageMoved)
        }
    }

    func moveTemporaryImageToLocalImages(image: EntityImage, _ onCompleted: @escaping OnCompleted) {
        guard let imageFileUuid = image.serverId else {
            logger.w { "Cannot move image to .localImages. No file uuid." }
            onCompleted()
            return
        }

        logger.v { "Attempting to move image \(imageFileUuid) to .localImages.." }

        CommonFileStorage.shared.moveTemporaryFileTo(
            targetDirectory: .localImages,
            fileUuid: imageFileUuid
        ) { fileSaveResult in
            if (fileSaveResult is FileSaveResult.Saved) {
                self.logger.v { "Moved image \(imageFileUuid) to .localImages." }
            } else {
                // quite possible outcome if image was not modified (i.e. it was already in local images).
                // -> create a log entry but otherwise there's not much else to do..
                self.logger.d { "Failed to move image \(imageFileUuid) to .localImages. Was it in .temporaryFiles?" }
            }

            Thread.onMainThread(onCompleted)
        }
    }

    private func getResizedJpegImageData(originalImage: UIImage) -> Data? {
        // file sizes based on quick tests
        //  - compressionQuality: 1.0 -> 800kB
        //  - compressionQuality: 0.9 -> 250kB
        //
        // No noticeable difference in image quality
        originalImage
            .resizedImageToFit(in: maxSavedImageSize, scaleIfSmaller: false)
            .jpegData(compressionQuality: 0.9)
    }
}
