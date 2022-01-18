import Foundation
import Async
import Photos
import PhotosUI

/**
 * An enum providing OS version independent status information
 */
@objc enum PhotoAuthorizationStatus: Int {
    case authorized
    case limited        // Can only be seen on > iOS 14 devices.
    case notAuthorized
    case notDetermined
}

/**
 * An OS version independent wrapper for PHPhotoLibrary authorization functionality.
 *
 * App can have a limited access to PHPhotoLibrary starting from iOS 14. Provides a way for other code
 * to check and request authorization status without needing to check OS version manually.
 */
class PhotoPermissions {

    /**
     * Gets the current photo authorization status.
     */
    class func authorizationStatus() -> PhotoAuthorizationStatus {
        return PhotoPermissions.instance.authorizationStatus()
    }

    /**
     * Requests authorization to photos. The handler is guaranteed to be called from main thread.
     */
    class func requestAuthorization(_ handler: @escaping (PhotoAuthorizationStatus) -> Void) {
        return PhotoPermissions.instance.requestAuthorization(handler)
    }

    /**
     * Launches the UI for selecting the photos the app has access to. Does nothing if current authorizationStatus
     * is not .limited.
     *
     * The completion will only be called if user confirms the updated selection (changes are not necessarily made though)
     */
    class func updateLimitedPhotosSelection(from controller: UIViewController, completion: (() -> Void)? = nil) {
        if #available(iOS 14, *) {
            LimitedPhotoLibraryAccessUpdater().present(from: controller, completion: completion)
        } else {
            print("OS version does not support changing limited photos")
        }
    }


    // Internal implementation

    // singleton, only one instance allowed
    private static let instance = PhotoPermissions()
    private init() {}


    private func authorizationStatus() -> PhotoAuthorizationStatus {
        var authorizationStatus: PHAuthorizationStatus
        if #available(iOS 14, *) {
            // - photos need to be read later (offline usage) -> read
            // - taken photos are written to photo library -> write
            authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            authorizationStatus = PHPhotoLibrary.authorizationStatus()
        }

        return mapFromPhotoLibraryAuthorizationStatus(authorizationStatus)
    }

    /**
     * Requests authorization to photos. The handler is guaranteed to be called from main thread.
     */
    private func requestAuthorization(_ handler: @escaping (PhotoAuthorizationStatus) -> Void) {
        let internalHandler: (PHAuthorizationStatus) -> Void = { [self] authorizationStatus in
            let permissionStatus = self.mapFromPhotoLibraryAuthorizationStatus(authorizationStatus)

            if (Thread.isMainThread) {
                handler(permissionStatus)
            } else {
                Async.main {
                    handler(permissionStatus)
                }
            }
        }

        if #available(iOS 14, *) {
            // - photos need to be read later (offline usage) -> read
            // - taken photos are written to photo library -> write
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: internalHandler)
        } else {
            PHPhotoLibrary.requestAuthorization(internalHandler)
        }
    }

    private func mapFromPhotoLibraryAuthorizationStatus(_ authorizationStatus: PHAuthorizationStatus) -> PhotoAuthorizationStatus {
        // use non-exhaustive switch here in order to prevent warnings from handling .limited in default block
        // make sure to add missing entries manually
        switch authorizationStatus {
        case .notDetermined:    return .notDetermined
        case .restricted:       return .notAuthorized
        case .denied:           return .notAuthorized
        case .authorized:       return .authorized
        default:
            if #available(iOS 14, *) {
                if (authorizationStatus == .limited) {
                    return .limited
                }
            }
            fatalError("Unknown photo library authorization status \(authorizationStatus.rawValue)")
        }
    }
}
