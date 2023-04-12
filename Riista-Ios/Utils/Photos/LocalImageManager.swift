import Foundation
import Async
import Photos


@objc public enum PhotoAccessFailureReason: Int {
    // user has not given access to photo library
    case notAuthorized

    // access to the photo library has not yet been determined
    case notDetermined

    // could not load photo: photo may have been removed or user has limited the access to the photo
    case accessLimitedOrLoadFailed

    // could not load photo: photo has most likely been removed. App has an access to the photo.
    case loadFailed

    // could not save photo
    case saveFailed

    // e.g. if the required data such as photo url is invalid.
    case unspecified
}



public enum LoadPhotoResult {
    case success(_ identifiableImage: IdentifiableImage)
    case failure(_ reason: PhotoAccessFailureReason, loadRequest: ImageLoadRequest)
}
typealias LoadPhotoCompletion = (LoadPhotoResult) -> Void


public enum SavePhotoResult {
    case success(_ identifiableImage: IdentifiableImage)
    case failure(_ reason: PhotoAccessFailureReason)
}
typealias SavePhotoCompletion = (SavePhotoResult) -> Void


/**
 * A manager for images with main responsibilities:
 * - pick image from gallery
 * - load image from gallery
 * - save image to gallery
 *
 * It is not this manager's responsibility to load/save images from/to directories managed by RiistaCommon. See `CommonImageManager`
 * for that purpose.
 */
class LocalImageManager: NSObject {
    @objc static let instance = LocalImageManager()

    let debugPrint = false

    func pickImageFromGallery(presentingViewController: UIViewController, delegate: RiistaImagePickerDelegate) {
        let picker: RiistaImagePicker
        if #available(iOS 14, *) {
            picker = GalleryImagePickeriOS14(localImageManager: self, delegate: delegate)
        } else {
            picker = GalleryImagePicker(localImageManager: self, delegate: delegate)
        }

        picker.present(presentingViewController: presentingViewController)
    }

    func pickImageFromCamera(presentingViewController: UIViewController, delegate: RiistaImagePickerDelegate) {
        let picker = CameraImagePicker(localImageManager: self, delegate: delegate)
        picker.present(presentingViewController: presentingViewController)
    }

    /**
     * A convenience function for objective-c land. Unwraps the completion enum contents into
     * separate success and error callbacks.
     *
     * The callbacks (onSuccess or onError) are called from main thread.
     */
    @objc func loadImage(_ loadRequest: ImageLoadRequest,
                         onSuccess: @escaping (_ image: IdentifiableImage) -> Void,
                         onError: ((PhotoAccessFailureReason, ImageLoadRequest?) -> Void)?) {
        loadImage(loadRequest) { result in
            switch result {
            case .success(let identifiableImage):
                onSuccess(identifiableImage)
                break
            case .failure(let reason, let loadRequest):
                onError?(reason, loadRequest)
                break;
            }
        }
    }

    /**
     * Tries to load the specified image.
     *
     * The result (image or an error) is notified by calling the completion from main thread.
     */
    func loadImage(_ loadRequest: ImageLoadRequest, completion: @escaping LoadPhotoCompletion) {
        debugPrint("Loading image \(String(reflecting: loadRequest))")

        let authorizationStatus = PhotoPermissions.authorizationStatus()
        switch authorizationStatus {
        case .authorized, .limited:
            // break i.e. don't return
            break
        case .notAuthorized:
            debugPrint("failure: notAuthorized")
            self.completeImageLoading(completion, result: .failure(.notAuthorized, loadRequest: loadRequest))
            return
        case .notDetermined:
            debugPrint("failure: notDetermined")
            // we don't want to automatically request photo authorization here since we don't know where
            // image loading originated from. Instead photo library authorization request should be made
            // when it is appropriate from the UI/UX point of view.
            self.completeImageLoading(completion, result: .failure(.notDetermined, loadRequest: loadRequest))
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1

        let targetSize = getSizeInPixels(size: loadRequest.options.size)
        let contentMode = getContentMode(contentMode: loadRequest.options.validContentMode)


        DispatchQueue.global(qos: .default).async { [self] in
            let fetchResult = fetchPHAsset(imageIdentifier: loadRequest.imageIdentifier, fetchOptions: fetchOptions)
            let asset = fetchResult.firstObject
            if (fetchResult.count == 0 || asset == nil) {
                print("Could not find/access a photo asset for given url")
                if (authorizationStatus == .limited) {
                    debugPrint("failure: accessLimitedOrFailed (\(String(reflecting: loadRequest)))")
                    self.completeImageLoading(completion, result: .failure(.accessLimitedOrLoadFailed, loadRequest: loadRequest))
                } else {
                    debugPrint("failure: loadFailed (\(String(reflecting: loadRequest)))")
                    self.completeImageLoading(completion, result: .failure(.loadFailed, loadRequest: loadRequest))
                }
                return
            }

            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = loadRequest.options.deliveryMode
            requestOptions.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(for: asset!,
                                                  targetSize: targetSize,
                                                  contentMode: contentMode,
                                                  options: requestOptions) { [self] image, info in
                if let image = image {
                    let resultImage = loadRequest.options.applyTransformations(for: image)
                    debugPrint("succeeded (\(String(reflecting: loadRequest)))")
                    self.completeImageLoading(completion, result: .success(IdentifiableImage(resultImage, imageIdentifier: loadRequest.imageIdentifier)))
                } else {
                    print("Failed to load an image from photo asset")

                    // when testing on device and app has limited access to photo library, the
                    // load fails already when fetching the asset. On Simulator, however, we
                    // do get the asset but the actual image loading fails
                    if (authorizationStatus == .limited) {
                        debugPrint("failure: accessLimitedOrFailed (\(String(reflecting: loadRequest)))")
                        self.completeImageLoading(completion, result: .failure(.accessLimitedOrLoadFailed, loadRequest: loadRequest))
                    } else {
                        debugPrint("failure: loadFailed (\(String(reflecting: loadRequest)))")
                        self.completeImageLoading(completion, result: .failure(.loadFailed, loadRequest: loadRequest))
                    }
                }
            }
        }
    }

    private func fetchPHAsset(imageIdentifier: ImageIdentifier, fetchOptions: PHFetchOptions) -> PHFetchResult<PHAsset> {
        switch imageIdentifier.identifyingData {
        case .localIdentifier(let localIdentifier):
            return fetchPHAsset(localIdentifier: localIdentifier, fetchOptions: fetchOptions)
        case .imageUrl(let url):
            return fetchPHAsset(localImageUrl: url, fetchOptions: fetchOptions)
        case .localIdentifierAndUrl(let localIdentifier, _):
            return fetchPHAsset(localIdentifier: localIdentifier, fetchOptions: fetchOptions)
        }
    }

    private func fetchPHAsset(localIdentifier: String, fetchOptions: PHFetchOptions) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
    }

    private func fetchPHAsset(localImageUrl: URL, fetchOptions: PHFetchOptions) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(withALAssetURLs: [localImageUrl], options: fetchOptions)
    }

    private func getSizeInPixels(size: ImageLoadOptions.Size) -> CGSize {
        let sizeInPoints = size.getSizeInPoints()
        if (sizeInPoints == PHImageManagerMaximumSize) {
            // PHImageManagerMaximumSize needs to be identifiable
            return sizeInPoints
        }

        return sizeInPoints.toPixels()
    }

    private func getContentMode(contentMode: ImageLoadOptions.ContentMode) -> PHImageContentMode {
        switch contentMode {
        case .default:      return .default
        case .aspectFit:    return .aspectFit
        case .aspectFill:   return .aspectFill
        }
    }

    private func completeImageLoading(_ completion: @escaping LoadPhotoCompletion, result: LoadPhotoResult) {
        Async.main {
            completion(result)
        }
    }

    private func getURL(uriAsString: String?) -> URL? {
        if let uriAsString = uriAsString {
            if (uriAsString.isEmpty) {
                return nil
            }

            return URL(string: uriAsString)
        }
        return nil
    }

    /**
     * Save the given image to the photo library.
     *
     * The completion callback will be called from main thread.
     */
    func saveImageToPhotoLibrary(_ image: UIImage, completion: @escaping SavePhotoCompletion) {
        var placeHolderAsset: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeHolderAsset = request.placeholderForCreatedAsset;
        }) { (success, error) in
            if (success) {
                print("Saved image to photo library")
                let localID: String = placeHolderAsset!.localIdentifier
                let assetID = localID.replacingOccurrences(of: "/.*",
                                                           with: "",
                                                           options: NSString.CompareOptions.regularExpression,
                                                           range: nil)
                let ext = "jpeg"
                let assetURLStr = "assets-library://asset/asset.\(ext)?id=\(assetID)&ext=\(ext)"

                let imageIdentifier = ImageIdentifier.create(validLocalIdentifier: localID, imageUrl: assetURLStr)

                Async.main {
                    completion(.success(IdentifiableImage(image, imageIdentifier: imageIdentifier)))
                }

            }
            else {
                Async.main {
                    print("Failed to save image to photo library.")
                    completion(.failure(.saveFailed))
                }
            }
        }
    }

    private func debugPrint(_ msg: String) {
        if (debugPrint) {
            print(msg)
        }
    }
}

