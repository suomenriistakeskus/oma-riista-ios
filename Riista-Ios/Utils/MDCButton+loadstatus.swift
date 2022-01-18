import Foundation
import MaterialComponents.MaterialButtons

extension MDCButton: PropertyStoring {
    typealias T = ImageLoadStatus

    private struct PropertyKeys {
        static var imageLoadStatus = "ImageLoadStatus"
    }
    struct ImageLoadStatus {
        // use an enum instead of Bool? since we're probably accessing this from
        // objective-c land. Bool? is not available there.
        var loadStatus: LoadStatus
        var imageLoadFailureReason: PhotoAccessFailureReason?

        init() {
            self.init(loadStatus: .unknown, failureReason: nil)
        }

        private init(loadStatus: LoadStatus, failureReason: PhotoAccessFailureReason?) {
            self.loadStatus = loadStatus
            self.imageLoadFailureReason = failureReason
        }

        static func succeeded() -> ImageLoadStatus {
            return ImageLoadStatus(loadStatus: .success, failureReason: nil)
        }

        static func failed(reason: PhotoAccessFailureReason) -> ImageLoadStatus {
            return ImageLoadStatus(loadStatus: .failure, failureReason: reason)
        }
    }

    private var _imageLoadStatus: ImageLoadStatus {
        get {
            getAssociatedObject(&PropertyKeys.imageLoadStatus, defaultValue: ImageLoadStatus())
        }
        set {
            setAssociatedObject(&PropertyKeys.imageLoadStatus, value: newValue)
        }
    }

    @objc var imageLoadStatus: LoadStatus {
        get {
            _imageLoadStatus.loadStatus
        }
    }

    // Optional enums are not available in objective-c. Defaults to .unspecified
    // which is most likely incorrect value if imageLoadStatus == .success
    @objc var imageLoadFailureReason: PhotoAccessFailureReason {
        get {
            _imageLoadStatus.imageLoadFailureReason ?? .unspecified
        }
    }

    @objc func setImageLoadedSuccessfully() {
        withAssociatedObject(&PropertyKeys.imageLoadStatus, defaultValue: ImageLoadStatus()) { imageLoadStatus in
            imageLoadStatus.loadStatus = .success
            imageLoadStatus.imageLoadFailureReason = nil
        }
    }

    @objc func setImageLoadFailed(reason: PhotoAccessFailureReason) {
        withAssociatedObject(&PropertyKeys.imageLoadStatus, defaultValue: ImageLoadStatus()) { imageLoadStatus in
            imageLoadStatus.loadStatus = .failure
            imageLoadStatus.imageLoadFailureReason = reason
        }
    }
}
