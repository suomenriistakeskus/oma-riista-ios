import Foundation
import Photos

class GalleryImagePicker: RiistaUIImagePicker {

    init(localImageManager: LocalImageManager, delegate: RiistaImagePickerDelegate?) {
        super.init(localImageManager: localImageManager, sourceType: .photoLibrary, delegate: delegate)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // The .referenceUrl points to the image in ALAssetLibrary framework. Don't mix this with .imageUrl
        // as the latter points to the file on the disk (and we cannot load images based on that information)
        let imageUrl: URL? = info[.referenceURL] as? URL
        let localIdentifier: String?
        if #available(iOS 11, *) {
            localIdentifier = (info[.phAsset] as? PHAsset)?.localIdentifier
        } else {
            localIdentifier = nil
        }

        guard let imageIdentifier = ImageIdentifier.create(localIdentifier: localIdentifier,
                                                           imageUrl: imageUrl?.absoluteString) else {
            self.dismissWithFailure(reason: .loadFailed)
            return
        }

        let loadRequest = ImageLoadRequest(imageIdentifier: imageIdentifier)
        loadRequest.options.deliveryMode = .highQualityFormat

        if let imageManager = self.localImageManager {
            imageManager.loadImage(loadRequest) { [weak self] result in
                guard let self = self else { return }

                // dismiss completion is guaranteed to be called from main thread
                // -> no need to pass work to main thread here
                switch result {
                case .success(let identifiableImage):
                    self.dismissWithSuccess(image: identifiableImage)
                    break
                case .failure(let reason, let loadRequest):
                    self.dismissWithFailure(reason: reason, loadRequest: loadRequest)
                    break
                }
            }
        } else {
            self.dismissWithFailure(reason: .unspecified)
        }
    }
}
