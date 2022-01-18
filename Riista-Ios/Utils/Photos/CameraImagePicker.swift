import Foundation

class CameraImagePicker: RiistaUIImagePicker {

    init(localImageManager: LocalImageManager, delegate: RiistaImagePickerDelegate?) {
        super.init(localImageManager: localImageManager, sourceType: .camera, delegate: delegate)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = getImage(info: info) {
            saveImageToPhotoLibrary(image)
        } else {
            self.dismissWithFailure(reason: .unspecified)
        }
    }

    func getImage(info: [UIImagePickerController.InfoKey: Any]) -> UIImage? {
        return info[.originalImage] as? UIImage
    }

    func saveImageToPhotoLibrary(_ image: UIImage) {
        if let imageManager = localImageManager {
            imageManager.saveImageToPhotoLibrary(image) { [weak self] result in
                guard let self = self else { return }

                // dismiss completion is guaranteed to be called from main thread
                // -> no need to pass work to main thread here
                switch result {
                case .success(let identifiableImage):
                    self.dismissWithSuccess(image: identifiableImage)
                    break
                case .failure(let reason):
                    self.dismissWithFailure(reason: reason)
                    break
                }
            }
        } else {
            print("Failed to save the image to photo library. No manager")
            self.dismissWithFailure(reason: .unspecified)
        }
    }
}
