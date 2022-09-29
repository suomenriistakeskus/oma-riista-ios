import Foundation
import PhotosUI

/**
 * A gallery image picker for iOS14. Wraps PHPickerViewController and its delegate.
 */
@available(iOS 14, *)
class GalleryImagePickeriOS14: RiistaImagePicker, PHPickerViewControllerDelegate {
    override var imagePickerViewController: UIViewController {
        get {
            return imagePicker
        }
    }

    let imagePicker: PHPickerViewController

    init(localImageManager: LocalImageManager, delegate: RiistaImagePickerDelegate) {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.selectionLimit = 1
        configuration.filter = PHPickerFilter.images

        self.imagePicker = PHPickerViewController(configuration: configuration)

        super.init(localImageManager: localImageManager, delegate: delegate)

        self.imagePicker.delegate = self
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            print("iOS14 gallery picker: no results, interpreting as cancel")
            dismissWithCancel()
            return
        }

        guard let localIdentifier = result.assetIdentifier else {
            dismissWithFailure(reason: .unspecified)
            return
        }

        let imageIdentifier = ImageIdentifier.create(validLocalIdentifier: localIdentifier, imageUrl: nil)
        let loadRequest = ImageLoadRequest(imageIdentifier: imageIdentifier)
        loadRequest.options.deliveryMode = .highQualityFormat

        if let imageManager = self.localImageManager {
            imageManager.loadImage(loadRequest) { result in
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
            dismissWithFailure(reason: .unspecified)
        }
    }
}
