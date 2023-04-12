import Foundation
import Async
import Photos
import MaterialComponents

@objcMembers
class ImageEditUtil: NSObject, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var parentController: UIViewController?

    var dialogTransitionController: MDCDialogTransitionController?

    weak var pickerDelegate: RiistaImagePickerDelegate?

    convenience init(parentController: UIViewController) {
        self.init()

        self.parentController = parentController
    }

    func checkPhotoPermissions(_ actionIfAuthorized: @escaping () -> Void) {
        requestPhotoAuthorizationStatusIfNotDetermined { [weak self] authorizationStatus in
            guard let self = self else { return }

            switch authorizationStatus {
            case .authorized, .limited:
                actionIfAuthorized()
                break
            case .notAuthorized:
                self.requestImagePermissionFromSettings()
                break
            case .notDetermined:
                // this should actually never happen since we have already requested
                // permission. There's probably nothing sensible thing to do so
                // lets just bail out
                print("Photo authorization status == .notDetermined even though we just asked permission?")
                break
            }
        }
    }

    func editImage(pickerDelegate: RiistaImagePickerDelegate) {
        requestPhotoAuthorizationStatusIfNotDetermined { [weak self] authorizationStatus in
            guard let self = self else { return }

            switch authorizationStatus {
            case .authorized, .limited:
                self.displayImageSourceDialog(pickerDelegate: pickerDelegate)
                break
            case .notAuthorized:
                self.requestImagePermissionFromSettings()
                break
            case .notDetermined:
                // this should actually never happen since we have already requested
                // permission. There's probably nothing sensible thing to do so
                // lets just bail out
                print("Photo authorization status == .notDetermined even though we just asked permission?")
                break
            }
        }
    }

    func displayImageLoadFailedDialog(_ pickerDelegate: RiistaImagePickerDelegate,
                                      reason: PhotoAccessFailureReason,
                                      imageLoadRequest: ImageLoadRequest?,
                                      allowAnotherPhotoSelection: Bool) {
        if (reason == .accessLimitedOrLoadFailed) {
            displayLimitedAccessOrImageLoadFailedDialog(pickerDelegate, imageLoadRequest: imageLoadRequest, allowAnotherPhotoSelection: allowAnotherPhotoSelection)
        } else if (reason == .loadFailed) {
            displayImageLoadFailedDialog(pickerDelegate, allowAnotherPhotoSelection: allowAnotherPhotoSelection)
        } else {
            // no dialog to be shown in other cases
            // - user cannot do anything to recover
        }
    }

    private func displayImageLoadFailedDialog(_ pickerDelegate: RiistaImagePickerDelegate, allowAnotherPhotoSelection: Bool) {
        self.pickerDelegate = pickerDelegate

        let dialogController = MDCAlertController(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageLoadFailedDialogTitle"),
                                                  message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageLoadFailedDialogMessage"))

        let selectPhotoAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageLoadFailedSelectAnotherPhotoAction")) { (MDCAlertAction) in
            self.displayImageSourceDialog(pickerDelegate: pickerDelegate)
        }
        let cancelAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageDialogButtonCancel"),
                                          emphasis: .medium) { (MDCAlertAction) in
            // Do nothing
        }

        dialogController.addAction(cancelAction)
        if (allowAnotherPhotoSelection) {
            dialogController.addAction(selectPhotoAction)
        }

        self.parentController?.present(dialogController, animated: true, completion: nil)
    }

    private func displayLimitedAccessOrImageLoadFailedDialog(_ pickerDelegate: RiistaImagePickerDelegate,
                                                             imageLoadRequest: ImageLoadRequest?,
                                                             allowAnotherPhotoSelection: Bool) {
        self.pickerDelegate = pickerDelegate

        let dialogController = MDCAlertController(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageLoadFailedDialogTitle"),
                                                  message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageLoadFailedOrLimitedAccessDialogMessage"))

        let selectPhotoAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageLoadFailedSelectAnotherPhotoAction")) { (MDCAlertAction) in
            self.displayImageSourceDialog(pickerDelegate: pickerDelegate)
        }
        let changePhotoAccessAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageLoadFailedSelectAccessiblePhotosAction")) { [weak self] (MDCAlertAction) in
            guard let parentController = self?.parentController else { return }

            PhotoPermissions.updateLimitedPhotosSelection(from: parentController) { [weak self] in
                self?.attemptImageReload(imageLoadRequest)
            }
        }
        let cancelAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageDialogButtonCancel"),
                                          emphasis: .medium) { (MDCAlertAction) in
            // Do nothing
        }

        dialogController.addAction(cancelAction)
        dialogController.addAction(changePhotoAccessAction)
        if (allowAnotherPhotoSelection) {
            dialogController.addAction(selectPhotoAction)
        }

        self.parentController?.present(dialogController, animated: true, completion: nil)
    }

    /**
     * Checks the current photo library authorization status and requests access if not yet determined. The completion handler
     * is guaranteed to be called from main thread.
     */
    private func requestPhotoAuthorizationStatusIfNotDetermined(_ completion: @escaping (PhotoAuthorizationStatus) -> Void) {
        let authStatus = PhotoPermissions.authorizationStatus()
        if (authStatus == .notDetermined) {
            PhotoPermissions.requestAuthorization(completion)
        } else {
            if (Thread.isMainThread) {
                completion(authStatus)
            } else {
                Async.main {
                    completion(authStatus)
                }
            }
        }
    }

    func requestImagePermissionFromSettings() {
        let dialogController = MDCAlertController(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImagePermissionRequiredTitle"),
                                                  message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImagePermissionRequiredMessage"))

        let settingsAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageDialogButtonSettings")) { (MDCAlertAction) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
        let cancelAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ImageDialogButtonCancel"),
                                          emphasis: .medium) { (MDCAlertAction) in
            // Do nothing
        }

        dialogController.addAction(settingsAction)
        dialogController.addAction(cancelAction)

        self.parentController?.present(dialogController, animated: true, completion: nil)
    }

    func displayImageSourceDialog(pickerDelegate: RiistaImagePickerDelegate) {
        if (canTakePhoto()) {
            let transitionController = MDCDialogTransitionController()
            self.dialogTransitionController = transitionController

            let dialogController = ImageSourceSelectionDialogController()
            dialogController.modalPresentationStyle = UIModalPresentationStyle.custom
            dialogController.transitioningDelegate = self.dialogTransitionController
            dialogController.completionHandler = { (imageSource:ImageSourceSelectionDialogController.ImageSource) -> () in
                switch imageSource {
                case .camera:
                    self.takePhoto(pickerDelegate: pickerDelegate)
                    break
                case .gallery:
                    self.pickImageFromGallery(pickerDelegate: pickerDelegate)
                    break
                default:
                    break
                }
            }

            self.parentController?.present(dialogController, animated: true, completion:nil)
        }
        else {
            self.pickImageFromGallery(pickerDelegate: pickerDelegate)
        }
    }

    func pickImageFromGallery(pickerDelegate: RiistaImagePickerDelegate) {
        self.pickerDelegate = pickerDelegate
        if let parentController = self.parentController {
            LocalImageManager.instance.pickImageFromGallery(
                presentingViewController: parentController,
                delegate: pickerDelegate)
        }
    }

    func canTakePhoto() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
    }

    func takePhoto(pickerDelegate: RiistaImagePickerDelegate) {
        self.pickerDelegate = pickerDelegate
        if let parentController = self.parentController {
            LocalImageManager.instance.pickImageFromCamera(
                presentingViewController: parentController,
                delegate: pickerDelegate)
        }
    }

    private func attemptImageReload(_ imageLoadRequest: ImageLoadRequest?) {
        guard let imageLoadRequest = imageLoadRequest else {
            // nothing we can really do without a valid image identifier
            return
        }

        LocalImageManager.instance.loadImage(imageLoadRequest) { [weak self] result in
            guard let pickerDelegate = self?.pickerDelegate else { return }

            switch result {
            case .success(let identifiableImage):
                pickerDelegate.imagePicked(image: identifiableImage)
                break
            case .failure(let reason, let loadRequest):
                pickerDelegate.imagePickFailed(reason, loadRequest: loadRequest)
                break
            }
        }
    }
}
