import Foundation


@objc public class ImageLoadRequest: NSObject {
    @objc let imageIdentifier: ImageIdentifier
    @objc var options: ImageLoadOptions

    convenience init(imageIdentifier: ImageIdentifier) {
        self.init(imageIdentifier: imageIdentifier, options: ImageLoadOptions.default())
    }

    init(imageIdentifier: ImageIdentifier, options: ImageLoadOptions) {
        self.imageIdentifier = imageIdentifier
        self.options = options

        super.init()
    }
}


extension ImageLoadRequest {
    public override var debugDescription: String {
        return "ImageLoadRequest(\(String(reflecting: imageIdentifier)))"
    }
}
