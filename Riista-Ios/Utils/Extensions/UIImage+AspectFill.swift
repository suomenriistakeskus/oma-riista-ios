extension UIImage {
    @objc func aspectFill(toSize newSize: CGSize) -> UIImage? {
        let aspectRatio = size.aspectRatio()
        let targetAspectRatio = newSize.aspectRatio()

        let drawSize: CGSize;

        if (targetAspectRatio > aspectRatio) {
            // target is to make the image wider -> increase width, possibly crop height
            drawSize = CGSize(width: newSize.width, height: newSize.width / aspectRatio)
        } else {
            // target is to make the image taller -> increase height, possibly crop width
            drawSize = CGSize(width: newSize.height * aspectRatio, height: newSize.height)
        }

        let newImage: UIImage?
        let clipRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral

        // perform center cropping by drawing the image outside of clip rect
        let drawRect = CGRect(x: (drawSize.width >= newSize.width) ? (newSize.width - drawSize.width) / 2 : 0,
                              y: (drawSize.height >= newSize.height) ? (newSize.height - drawSize.height) / 2 : 0,
                              width: drawSize.width,
                              height: drawSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.interpolationQuality = .high
        context.clip(to: clipRect)
        draw(in: drawRect)
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
