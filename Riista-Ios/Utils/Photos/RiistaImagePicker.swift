import Foundation
import Async

@objc protocol RiistaImagePickerDelegate {
    /**
     * Image has been successfully picked.
     *
     * This callback is always called from main thread.
     */
    func imagePicked(image: IdentifiableImage)

    /**
     * Image pick has been cancelled.
     *
     * This callback may be called from background thread.
     */
    func imagePickCancelled()

    /**
     * Image pick failed.
     *
     * This callback is always called from main thread.
     */
    func imagePickFailed(_ reason: PhotoAccessFailureReason, loadRequest: ImageLoadRequest?)
}

protocol ImagePickerProvider: AnyObject {
    var imagePickerViewController: UIViewController { get }
}

/**
 * Encapsulates the image picker and it's delegate. Subclasses need to decide the actual image picker (UIImagePickerController vs PHPickerViewController) and
 * implement required functions + provide a delegate.
 *
 * Subclasses are required to override ImagePickerProvider functionality.
 */
class RiistaImagePicker: NSObject, ImagePickerProvider {
    // keep strong references to pickers that are currently active (i.e. presenting imagePicker)
    static private var activePickers = Synchronized<Set<RiistaImagePicker>>(
        label: "RiistaImagePicker.activePickers",
        initialValue: Set<RiistaImagePicker>()
    )

    var imagePickerViewController: UIViewController {
        get {
            fatalError("Subclasses are required to override ImagePickerProvider functionality")
        }
    }

    weak var localImageManager: LocalImageManager?
    weak var delegate: RiistaImagePickerDelegate?

    init(localImageManager: LocalImageManager, delegate: RiistaImagePickerDelegate?) {
        self.localImageManager = localImageManager
        self.delegate = delegate

        super.init()
    }

    func present(presentingViewController: UIViewController) {
        presentingViewController.present(imagePickerViewController, animated: true, completion: nil)
        keepAlive(self)
    }

    func dismissWithSuccess(image: IdentifiableImage) {
        dismiss() { [self] in
            self.delegate?.imagePicked(image: image)
        }
    }

    func dismissWithFailure(reason: PhotoAccessFailureReason, loadRequest: ImageLoadRequest? = nil) {
        dismiss() { [self] in
            self.delegate?.imagePickFailed(reason, loadRequest: loadRequest)
        }
    }

    func dismissWithCancel() {
        dismiss() { [self] in
            self.delegate?.imagePickCancelled()
        }
    }

    /**
     * Dismisses the picker. Does not call any delegate functions.
     *
     * The completion will be called from main thread.
     */
    func dismiss(_ completion: (() -> Void)? = nil) {
        let dismissHandler: () -> Void = { [self] in
            // dismiss completion _should_ happen in main thread
            self.imagePickerViewController.dismiss(animated: true, completion: completion)
            self.allowRelease(self)
        }

        Thread.onMainThread {
            dismissHandler()
        }
    }

    func keepAlive(_ picker: RiistaImagePicker) {
        RiistaImagePicker.activePickers.apply { pickers in
            pickers.insert(self)
        }
    }

    func allowRelease(_ picker: RiistaImagePicker) {
        RiistaImagePicker.activePickers.apply { pickers in
            pickers.remove(self)
        }
    }
}
