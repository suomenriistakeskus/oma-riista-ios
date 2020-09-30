import Foundation
import Photos
import MaterialComponents

@objc protocol ImageEditUtilDelegate {
    func didFinishPickingImage(info: [UIImagePickerController.InfoKey : Any])

    func didSaveImage(assetUrlStr: String)
}

@objcMembers
class ImageEditUtil: NSObject, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    var parentController: UIViewController?

    var dialogTransitionController: MDCDialogTransitionController?

    weak var pickerDelegate: ImageEditUtilDelegate?

    convenience init(parentController: UIViewController) {
        self.init()

        self.parentController = parentController
    }

    func hasImages(entry: DiaryEntryBase) -> Bool {
        if let harvest = entry as? DiaryEntry {
            return harvest.diaryImages.count > 0
        }
        else if let observation = entry as? ObservationEntry {
            return observation.diaryImages?.count ?? 0 > 0
        }
        else if let srva = entry as? SrvaEntry {
            return srva.diaryImages?.count ?? 0 > 0
        }

        return false
    }

    func editImage(pickerDelegate: ImageEditUtilDelegate) {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if (authStatus == .notDetermined) {
            PHPhotoLibrary.requestAuthorization { (status) in
                if (status == .authorized) {
                    DispatchQueue.main.async {
                        self.displayImageSourceDialog(pickerDelegate: pickerDelegate)
                    }
                }
            }
        }
        else if (authStatus == .authorized) {
            displayImageSourceDialog(pickerDelegate: pickerDelegate)
        }
        else {
            requestImagePermissionFromSettings()
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

    func displayImageSourceDialog(pickerDelegate: ImageEditUtilDelegate) {
        self.pickerDelegate = pickerDelegate

        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {

            let transitionController = MDCDialogTransitionController()
            self.dialogTransitionController = transitionController

            let dialogController = ImageSourceSelectionDialogController()
            dialogController.modalPresentationStyle = UIModalPresentationStyle.custom
            dialogController.transitioningDelegate = self.dialogTransitionController
            dialogController.completionHandler = { (imageSource:ImageSourceSelectionDialogController.ImageSource) -> () in
                switch imageSource {
                case .camera:
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.sourceType = UIImagePickerController.SourceType.camera

                    self.parentController?.present(picker, animated: true, completion: nil)
                    break
                case .gallery:
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.sourceType = UIImagePickerController.SourceType.photoLibrary

                    self.parentController?.present(picker, animated: true, completion: nil)
                default:
                    break
                }
            }

            self.parentController?.present(dialogController, animated: true, completion:nil)
        }
        else {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary

            self.parentController?.present(picker, animated: true, completion: nil)
        }
    }

    func saveImageToPhotoLibrary(info: NSDictionary, delegate: ImageEditUtilDelegate) {

        guard let originalImage = info.value(forKey: UIImagePickerController.InfoKey.originalImage.rawValue) as? UIImage else {
            NSLog("Failed to get original image from picker result")
            return
        }

        var placeHolderAsset: PHObjectPlaceholder?

        // Save full size image to photol library. Image is downscaled before sending to backend.
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: originalImage)
            placeHolderAsset = request.placeholderForCreatedAsset;
        }) { (success, error) in
            if (success) {
                NSLog("Saved image to photo library")

                let localID = placeHolderAsset?.localIdentifier
                let assetID = localID?.replacingOccurrences(of: "/.*",
                                                            with: "",
                                                            options: NSString.CompareOptions.regularExpression,
                                                            range: nil)
                let ext = "jpeg"
                let assetURLStr = "assets-library://asset/asset.\(ext)?id=\(assetID ?? "")&ext=\(ext)"

                delegate.didSaveImage(assetUrlStr: assetURLStr)
            }
            else {
                NSLog("Error saving photo: %@", error?.localizedDescription ?? "");
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.parentController?.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.pickerDelegate?.didFinishPickingImage(info: info)

        self.parentController?.dismiss(animated: true, completion: nil)
    }
}
