import Foundation
import Async

/**
 * Wraps the UIImagePickerController and it's delegate. Subclasses need to implement UIImagePickerControllerDelegate functions.
 */
class RiistaUIImagePicker: RiistaImagePicker, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    override var imagePickerViewController: UIViewController {
        get {
            return imagePicker
        }
    }

    // the actual image picker presented to the user
    private let imagePicker: UIImagePickerController

    init(localImageManager: LocalImageManager,
         sourceType: UIImagePickerController.SourceType,
         delegate: RiistaImagePickerDelegate?) {
        self.imagePicker = UIImagePickerController()

        super.init(localImageManager: localImageManager, delegate: delegate)

        self.imagePicker.delegate = self
        self.imagePicker.sourceType = sourceType
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismissWithCancel()
    }
}
