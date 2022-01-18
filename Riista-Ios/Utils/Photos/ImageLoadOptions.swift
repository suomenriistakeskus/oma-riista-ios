import Foundation
import Photos

@objc public class ImageLoadOptions: NSObject {
    public enum Size {
        case custom(size: CGSize)
        case screen // default
        case original
    }

    /**
     * Replicated PHImageContentMode with the exception that default does not mean either .aspectFit nor .aspectFill
     */
    @objc
    public enum ContentMode: Int {
        // only allowed value if size is original. Default value.
        case `default`

        // allowed for .custom and .screen sizes.
        case aspectFill

        // allowed for .custom and .screen sizes
        case aspectFit
    }

    var size: Size = .screen

    var contentMode: ContentMode = .default
    var validContentMode: ContentMode {
        get {
            switch size {
            case .original:
                return .default
            case .screen, .custom(_):
                return contentMode
            }
        }
    }

    var deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic

    var fixRotation: Bool = false


    @objc class func `default`() -> ImageLoadOptions {
        return ImageLoadOptions()
    }
    @objc class func `default`(size: CGSize) -> ImageLoadOptions {
        return ImageLoadOptions()
            .withCustomSize(size)
    }
    @objc class func aspectFilled(size: CGSize) -> ImageLoadOptions {
        return ImageLoadOptions()
            .withCustomSize(size)
            .withContentMode(.aspectFill)
    }
    @objc class func aspectFitted(size: CGSize) -> ImageLoadOptions {
        return ImageLoadOptions()
            .withCustomSize(size)
            .withContentMode(.aspectFit)
    }
    @objc class func originalSized() -> ImageLoadOptions {
        return ImageLoadOptions()
            .withOriginalSize()
    }

    // transformations

    @objc func applyTransformations(for image: UIImage) -> UIImage {
        var resultImage: UIImage = image

        if (self.fixRotation) {
            resultImage = RiistaUtils.fixImageOrientation(resultImage, limitMaxSize: true)
        }

        if (self.validContentMode == .aspectFill) {
            if let aspectFilled = resultImage.aspectFill(toSize: self.size.getSizeInPoints()) {
                resultImage = aspectFilled
            }
        }
        if (self.validContentMode == .aspectFit) {
            if let aspectFitted = resultImage.aspectFit(toSize: self.size.getSizeInPoints()) {
                resultImage = aspectFitted
            }
        }

        return resultImage
    }

    // builder methods

    // helpers for obj-c as Size enum is not available there
    @objc @discardableResult func withCustomSize(_ size: CGSize) -> ImageLoadOptions {
        self.size = .custom(size: size)
        return self
    }
    @objc @discardableResult func withOriginalSize() -> ImageLoadOptions {
        self.size = .original
        return self
    }
    @objc @discardableResult func withScreenSize() -> ImageLoadOptions {
        self.size = .screen
        return self
    }

    @objc @discardableResult func withContentMode(_ contentMode: ContentMode) -> ImageLoadOptions {
        self.contentMode = contentMode
        return self
    }

    @objc @discardableResult func withDeliveryMode(_ deliveryMode: PHImageRequestOptionsDeliveryMode) -> ImageLoadOptions {
        self.deliveryMode = deliveryMode
        return self
    }

    @objc @discardableResult func withFixRotation(_ fixRotation: Bool) -> ImageLoadOptions {
        self.fixRotation = fixRotation
        return self
    }
}


extension ImageLoadOptions.Size {
    func getSizeInPoints() -> CGSize {
        switch self {
        case .original:
            return PHImageManagerMaximumSize
        case .screen:
            return UIScreen.main.bounds.size
        case .custom(let size):
            return size
        }
    }
}
